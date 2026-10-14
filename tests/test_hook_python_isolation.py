"""Regression: isolate Python fallbacks in inject-plan.sh and resolve-plan-dir.sh.

Upstream ec2ec0a (python -I) stops hook interpreters from importing a project
module that happens to share a stdlib name. This fork's -c snippets only
import os and sys, both of which CPython has already loaded before -c runs,
so a cwd secrets.py, hashlib.py, or ctypes.py is not reached today. The
fallback still executes site startup: a PYTHONPATH sitecustomize.py runs with
the hook's privileges on every non-isolated `python -c`.

-I ignores PYTHON* environment variables, excludes the script/current directory
and user site-packages from sys.path, and keeps the system site module enabled.
It is available since Python 3.4; Python 3.11 names the safe-path behavior -P.
These tests force the canonicalization fallback, and the resolver's mtime
fallback, because realpath/readlink/stat/date never spawn Python on the happy
path.

Windows and other runtimes:
- The fallback is forced with POSIX stub scripts. Git Bash can run them when
  they are on PATH ahead of the real tools; a host without a working sh skips.
- PowerShell twins are not part of this backport.
- Planted cwd modules must stay inert; system-wide site customizations remain
  enabled and are outside this project's isolation boundary.
"""

from __future__ import annotations

import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
INJECT_SH = REPO_ROOT / "scripts" / "inject-plan.sh"
RESOLVE_SH = REPO_ROOT / "scripts" / "resolve-plan-dir.sh"
CODEX_HOOK = REPO_ROOT / ".codex" / "hooks" / "user-prompt-submit.sh"

# git ls-files names, relative to the repo root. The Codex hook file is a shim
# with no interpreter of its own and must stay in the scanned set.
REQUIRED_COPIES = (
    "scripts/inject-plan.sh",
    "scripts/resolve-plan-dir.sh",
    "skills/planning-with-files/scripts/inject-plan.sh",
    "skills/planning-with-files/scripts/resolve-plan-dir.sh",
    ".agents/skills/planning-with-files/scripts/inject-plan.sh",
    ".agents/skills/planning-with-files/scripts/resolve-plan-dir.sh",
    ".pi/skills/planning-with-files/scripts/inject-plan.sh",
    ".pi/skills/planning-with-files/scripts/resolve-plan-dir.sh",
    ".codex/skills/planning-with-files/scripts/inject-plan.sh",
    ".codex/skills/planning-with-files/scripts/resolve-plan-dir.sh",
    ".codex/hooks/resolve-plan-dir.sh",
    ".continue/skills/planning-with-files/scripts/inject-plan.sh",
    ".continue/skills/planning-with-files/scripts/resolve-plan-dir.sh",
    ".gemini/skills/planning-with-files/scripts/inject-plan.sh",
    ".gemini/skills/planning-with-files/scripts/resolve-plan-dir.sh",
)

# Upstream named these because its heredocs import them. This fork's snippets
# do not, but a cwd copy must still not run.
CWD_THREAT_MODULES = ("secrets", "hashlib", "ctypes")

# python3 -c / python -c, optional -I (or other short flags), and the upstream
# `"$PWF_PYTHON" -I - ... <<'PY'` heredoc form.
_LAUNCH = re.compile(
    r"""(?x)
    (?:
        (?<![A-Za-z0-9_])python3?(?![A-Za-z0-9_])
        |
        "\$(?:\{)?[A-Za-z_][A-Za-z0-9_]*(?:\})?"
    )
    \s+
    (?P<flags>(?:-[A-Za-z0-9]+\s+)*)
    (?P<mode>-c\b|-\s|<<)
    """
)


def tracked_script_family() -> list[str]:
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=str(REPO_ROOT),
        check=True,
        capture_output=True,
    )
    names = result.stdout.decode("utf-8").split("\0")
    return sorted(
        name
        for name in names
        if name.endswith("/inject-plan.sh")
        or name.endswith("/resolve-plan-dir.sh")
        or name.endswith("inject-plan.sh")
        or name.endswith("resolve-plan-dir.sh")
    )


def python_launches(path: Path) -> list[tuple[int, str, str]]:
    """Return (lineno, flag-string, line) for each -c or heredoc launch."""
    found: list[tuple[int, str, str]] = []
    text = path.read_text(encoding="utf-8")
    for lineno, line in enumerate(text.splitlines(), 1):
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        match = _LAUNCH.search(line)
        if match is None:
            continue
        found.append((lineno, match.group("flags"), line.strip()))
    return found


def shell_and_env() -> tuple[str, dict[str, str]]:
    env = os.environ.copy()
    for key in (
        "PLAN_ID",
        "PLANNING_DISABLED",
        "PYTHONPATH",
        "PYTHONHOME",
        "PYTHONSTARTUP",
        "PYTHONSAFEPATH",
        "PYTHONINSPECT",
    ):
        env.pop(key, None)
    if os.name != "nt":
        shell = shutil.which("sh")
        if shell is None:
            raise unittest.SkipTest("POSIX sh is unavailable")
        return shell, env

    hooks = REPO_ROOT / ".codex" / "hooks"
    sys.path.insert(0, str(hooks))
    try:
        import codex_hook_adapter as adapter

        shell, extra_path_dirs = adapter._windows_git_bash()
    finally:
        sys.path.pop(0)
    if shell is None:
        raise unittest.SkipTest("Git for Windows sh.exe is unavailable")
    if extra_path_dirs:
        env["PATH"] = os.pathsep.join([*extra_path_dirs, env.get("PATH", "")])
    return shell, env


def require_python3(env: dict[str, str]) -> None:
    if shutil.which("python3", path=env.get("PATH")) is None:
        raise unittest.SkipTest("python3 is unavailable to the hook shell")


def write_plan(directory: Path, goal: str) -> None:
    directory.mkdir(parents=True, exist_ok=True)
    (directory / "task_plan.md").write_text(
        f"# Task Plan\n\n## Goal\n{goal}\n\n### Phase 1: Work\n- **Status:** in_progress\n",
        encoding="utf-8",
    )
    (directory / "progress.md").write_text("# Progress\n\nstarted\n", encoding="utf-8")


def plant_marker_module(directory: Path, module_name: str, marker: Path) -> None:
    directory.mkdir(parents=True, exist_ok=True)
    target = json.dumps(str(marker))
    (directory / f"{module_name}.py").write_text(
        f"open({target}, 'w', encoding='utf-8').write('executed\\n')\n",
        encoding="utf-8",
    )


def install_failing_stubs(bin_dir: Path, names: tuple[str, ...], log: Path) -> None:
    """Tools that must fail so the shell falls through to python3 -c."""
    bin_dir.mkdir(parents=True, exist_ok=True)
    quoted_log = shlex.quote(str(log))
    for name in names:
        script = bin_dir / name
        script.write_text(
            "#!/bin/sh\n"
            f"printf '%s\\n' {shlex.quote(name)} >> {quoted_log}\n"
            "exit 1\n",
            encoding="utf-8",
        )
        script.chmod(0o755)


def run_script(
    shell: str,
    script: Path,
    cwd: Path,
    env: dict[str, str],
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [shell, str(script)],
        cwd=str(cwd),
        env=env,
        text=True,
        encoding="utf-8",
        errors="replace",
        capture_output=True,
        check=False,
        timeout=30,
    )


class HookPythonIsolationContractTests(unittest.TestCase):
    def test_tracked_script_family_includes_every_ide_mirror(self) -> None:
        tracked = set(tracked_script_family())
        missing = [name for name in REQUIRED_COPIES if name not in tracked]
        self.assertEqual([], missing, f"git ls-files missed hook scripts: {missing}")

    def test_canonical_fallbacks_are_the_python_launches(self) -> None:
        inject = python_launches(INJECT_SH)
        resolve = python_launches(RESOLVE_SH)
        shim = python_launches(REPO_ROOT / ".codex" / "hooks" / "resolve-plan-dir.sh")
        self.assertEqual(2, len(inject), inject)
        self.assertEqual(4, len(resolve), resolve)
        self.assertEqual([], shim)
        # Resolver owns both realpath and mtime fallbacks; inject only realpath.
        resolve_text = "\n".join(line for _lineno, _flags, line in resolve)
        self.assertIn("os.path.realpath", resolve_text)
        self.assertIn("os.stat", resolve_text)
        inject_text = "\n".join(line for _lineno, _flags, line in inject)
        self.assertIn("os.path.realpath", inject_text)
        self.assertNotIn("os.stat", inject_text)

    def test_every_python_c_or_heredoc_launch_uses_isolated_mode(self) -> None:
        offenders: list[str] = []
        for name in tracked_script_family():
            for lineno, flags, line in python_launches(REPO_ROOT / name):
                if "-I" not in flags.split():
                    offenders.append(f"{name}:{lineno}: {line}")
        self.assertEqual([], offenders)


class HookPythonFallbackBehaviorTests(unittest.TestCase):
    def setUp(self) -> None:
        self.shell, self.base_env = shell_and_env()
        require_python3(self.base_env)

    def assert_planted_modules_did_not_run(self, markers: list[Path]) -> None:
        present = [str(path) for path in markers if path.exists()]
        self.assertEqual(
            [],
            present,
            "hook Python executed a planted module during fallback: " + ", ".join(present),
        )

    def prepare_project(self, root: Path) -> tuple[Path, list[Path], dict[str, str]]:
        project = root / "project"
        project.mkdir()
        pythonpath = root / "pythonpath"
        markers = [project / "PLANTED_SITE"]
        plant_marker_module(pythonpath, "sitecustomize", markers[0])
        for module in CWD_THREAT_MODULES:
            marker = project / f"PLANTED_{module}"
            plant_marker_module(project, module, marker)
            markers.append(marker)
        env = self.base_env.copy()
        env["PYTHONPATH"] = str(pythonpath)
        return project, markers, env

    def force_fallback(
        self,
        root: Path,
        env: dict[str, str],
        tools: tuple[str, ...],
    ) -> Path:
        log = root / "stub-calls.log"
        install_failing_stubs(root / "stubs", tools, log)
        env["PATH"] = str(root / "stubs") + os.pathsep + env.get("PATH", "")
        return log

    def assert_stubs_ran(self, log: Path, tools: tuple[str, ...]) -> None:
        text = log.read_text(encoding="utf-8") if log.exists() else ""
        missing = [name for name in tools if name not in text.split()]
        self.assertEqual(
            [],
            missing,
            f"fallback was not forced; missing stub calls {missing} in {text!r}",
        )

    def test_inject_legacy_and_docs_fallback_ignores_planted_modules(self) -> None:
        cases = (
            ("legacy", "Legacy goal text", None),
            ("docs", "Docs goal text", "docs"),
        )
        for label, goal, layout in cases:
            with self.subTest(layout=label):
                with tempfile.TemporaryDirectory() as tmp:
                    root = Path(tmp)
                    project, markers, env = self.prepare_project(root)
                    if layout == "docs":
                        write_plan(project / "docs" / "plans" / "feature", goal)
                    else:
                        write_plan(project, goal)
                    log = self.force_fallback(root, env, ("realpath", "readlink"))
                    result = run_script(self.shell, INJECT_SH, project, env)
                    self.assertEqual(0, result.returncode, result.stderr)
                    self.assert_stubs_ran(log, ("realpath", "readlink"))
                    self.assertIn(goal, result.stdout, result.stdout)
                    self.assertIn("ACTIVE PLAN", result.stdout)
                    self.assert_planted_modules_did_not_run(markers)

    def test_resolver_docs_and_slug_fallback_ignores_planted_modules(self) -> None:
        cases = (
            ("docs", lambda project: write_plan(project / "docs" / "plans" / "feature", "Docs goal text"), "docs/plans/feature"),
            ("slug", lambda project: write_plan(project / ".planning" / "feature-slug", "Slug goal text"), ".planning/feature-slug"),
        )
        # perl is stubbed so a broken python cannot succeed via the next
        # fallback, but a working python returns before perl is reached.
        tools = ("realpath", "readlink", "stat", "date", "perl")
        observed = ("realpath", "readlink", "stat", "date")
        for label, plant, expected in cases:
            with self.subTest(layout=label):
                with tempfile.TemporaryDirectory() as tmp:
                    root = Path(tmp)
                    project, markers, env = self.prepare_project(root)
                    plant(project)
                    log = self.force_fallback(root, env, tools)
                    result = run_script(self.shell, RESOLVE_SH, project, env)
                    self.assertEqual(0, result.returncode, result.stderr)
                    self.assert_stubs_ran(log, observed)
                    normalized = result.stdout.replace("\\", "/")
                    self.assertIn(expected, normalized, result.stdout)
                    self.assert_planted_modules_did_not_run(markers)

    def test_codex_hook_docs_injection_fallback_ignores_planted_modules(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            project, markers, env = self.prepare_project(root)
            write_plan(project / "docs" / "plans" / "feature", "Hook docs goal")
            log = self.force_fallback(root, env, ("realpath", "readlink"))
            result = run_script(self.shell, CODEX_HOOK, project, env)
            self.assertEqual(0, result.returncode, result.stderr)
            self.assert_stubs_ran(log, ("realpath", "readlink"))
            self.assertIn("ACTIVE PLAN", result.stdout, result.stdout)
            self.assertIn("Hook docs goal", result.stdout)
            self.assert_planted_modules_did_not_run(markers)

    def test_normal_legacy_and_docs_injection_unchanged(self) -> None:
        """Happy path: realpath is left intact, so Python must not be required."""
        cases = (
            ("legacy", "Legacy goal text", None, ""),
            ("docs", "Docs goal text", "docs/plans/feature", "docs/plans/feature"),
        )
        for label, goal, layout, resolved in cases:
            with self.subTest(layout=label):
                with tempfile.TemporaryDirectory() as tmp:
                    project = Path(tmp)
                    if layout is None:
                        write_plan(project, goal)
                    else:
                        write_plan(project / layout, goal)
                    env = self.base_env.copy()
                    injected = run_script(self.shell, INJECT_SH, project, env)
                    self.assertEqual(0, injected.returncode, injected.stderr)
                    self.assertIn("ACTIVE PLAN", injected.stdout, injected.stdout)
                    self.assertIn(goal, injected.stdout)
                    resolved_out = run_script(self.shell, RESOLVE_SH, project, env)
                    self.assertEqual(0, resolved_out.returncode, resolved_out.stderr)
                    if resolved:
                        self.assertIn(resolved, resolved_out.stdout.replace("\\", "/"))
                    else:
                        self.assertEqual("", resolved_out.stdout.strip())


if __name__ == "__main__":
    unittest.main()
