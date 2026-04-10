#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any


HOOK_DIR = Path(__file__).resolve().parent
PLANNING_FILES = ("task_plan.md", "progress.md", "findings.md")
PLANNING_DIR_NAMES = ("plans", "plan", "planning")
SKIP_DIR_NAMES = {
    ".git",
    ".hg",
    ".svn",
    ".codex",
    ".claude",
    ".cursor",
    "node_modules",
    "dist",
    "build",
    "target",
    ".next",
}


def load_payload() -> dict[str, Any]:
    raw = sys.stdin.read().strip()
    if not raw:
        return {}
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError:
        return {}
    return payload if isinstance(payload, dict) else {}


def cwd_from_payload(payload: dict[str, Any]) -> Path:
    cwd = payload.get("cwd")
    if isinstance(cwd, str) and cwd:
        return Path(cwd)
    return Path.cwd()


def git_root(cwd: Path) -> Path:
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        cwd=str(cwd),
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode == 0:
        root = result.stdout.strip()
        if root:
            return Path(root)
    return cwd


def emit_json(payload: dict[str, Any]) -> None:
    if not payload:
        return
    json.dump(payload, sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")


def resolve_skill_dir() -> Path | None:
    candidates = [
        HOOK_DIR.parent / "skills" / "planning-with-files",
        Path.home() / ".codex" / "skills" / "planning-with-files",
        Path.home() / ".agents" / "skills" / "planning-with-files" / "skills" / "planning-with-files",
        Path.home() / ".claude" / "plugins" / "planning-with-files",
        Path.home() / ".claude" / "skills" / "planning-with-files",
    ]
    for candidate in candidates:
        if (candidate / "scripts" / "session-catchup.py").is_file():
            return candidate
    return None


def _is_under(child: Path, parent: Path) -> bool:
    try:
        child.relative_to(parent)
        return True
    except ValueError:
        return False


def _iter_docs_task_plans(repo_root: Path) -> list[Path]:
    docs_dir = repo_root / "docs"
    if not docs_dir.is_dir():
        return []
    matches: list[Path] = []
    for path in docs_dir.rglob("task_plan.md"):
        if any(part in SKIP_DIR_NAMES or part.startswith(".") for part in path.parts):
            continue
        matches.append(path.parent)
    return matches


def _candidate_directories(cwd: Path) -> list[Path]:
    repo_root = git_root(cwd)
    candidates: list[Path] = []
    seen: set[Path] = set()

    def add(path: Path) -> None:
        if path in seen:
            return
        seen.add(path)
        candidates.append(path)

    env_dir = os.environ.get("PLANNING_WITH_FILES_DIR")
    if env_dir:
        add(Path(env_dir).expanduser())

    current = cwd
    while True:
        add(current)
        if current == repo_root or current.parent == current:
            break
        current = current.parent

    add(repo_root)
    docs_dir = repo_root / "docs"
    for name in PLANNING_DIR_NAMES:
        add(docs_dir / name)
    for candidate in _iter_docs_task_plans(repo_root):
        add(candidate)
    return candidates


def resolve_planning_dir(cwd: Path) -> Path | None:
    repo_root = git_root(cwd)
    best: tuple[int, int, int, float, Path] | None = None
    for directory in _candidate_directories(cwd):
        task_plan = directory / "task_plan.md"
        if not task_plan.is_file():
            continue
        trio_count = sum((directory / name).is_file() for name in PLANNING_FILES)
        latest_mtime = max((directory / name).stat().st_mtime for name in PLANNING_FILES if (directory / name).exists())
        cwd_bonus = 1 if _is_under(cwd, directory) else 0
        root_penalty = 0 if directory != repo_root else -1
        score = (trio_count, cwd_bonus, root_penalty, latest_mtime)
        if best is None or score > best[:4]:
            best = (*score, directory)
    return None if best is None else best[4]


def planning_files(cwd: Path) -> dict[str, Path] | None:
    directory = resolve_planning_dir(cwd)
    if directory is None:
        return None
    return {name[:-3]: directory / name for name in PLANNING_FILES}


def _read_head(path: Path, limit: int) -> str:
    if not path.is_file():
        return ""
    with path.open("r", encoding="utf-8", errors="replace") as handle:
        return "".join(handle.readline() for _ in range(limit)).rstrip()


def _read_tail(path: Path, limit: int) -> str:
    if not path.is_file():
        return ""
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    return "\n".join(lines[-limit:]).rstrip()


def render_active_plan_context(cwd: Path) -> str:
    files = planning_files(cwd)
    if files is None or not files["task_plan"].is_file():
        return ""

    directory = files["task_plan"].parent
    plan_head = _read_head(files["task_plan"], 50)
    progress_tail = _read_tail(files["progress"], 20)
    findings_hint = files["findings"].name

    parts = [
        f"[planning-with-files] ACTIVE PLAN — {directory}:",
        plan_head,
    ]
    if progress_tail:
        parts.extend(["", "=== recent progress ===", progress_tail])
    parts.extend(
        [
            "",
            f"[planning-with-files] Read {findings_hint} for research context. Continue from the current phase.",
        ]
    )
    return "\n".join(part for part in parts if part is not None).strip()


def render_plan_header(cwd: Path, lines: int = 30) -> str:
    files = planning_files(cwd)
    if files is None:
        return ""
    return _read_head(files["task_plan"], lines)


def run_session_catchup(cwd: Path) -> str:
    skill_dir = resolve_skill_dir()
    if skill_dir is None:
        return ""
    script = skill_dir / "scripts" / "session-catchup.py"
    python_bin = shutil_which_python()
    if python_bin is None or not script.is_file():
        return ""
    result = subprocess.run(
        [python_bin, str(script), str(cwd)],
        cwd=str(cwd),
        text=True,
        capture_output=True,
        check=False,
    )
    return (result.stdout or "").strip()


def shutil_which_python() -> str | None:
    for name in ("python3", "python"):
        result = subprocess.run(
            ["sh", "-lc", f"command -v {name}"],
            text=True,
            capture_output=True,
            check=False,
        )
        path = result.stdout.strip()
        if path:
            return path
    return None


def stop_message(cwd: Path) -> str:
    files = planning_files(cwd)
    if files is None:
        return ""
    skill_dir = resolve_skill_dir()
    if skill_dir is None:
        return ""
    script = skill_dir / "scripts" / "check-complete.sh"
    if not script.is_file():
        return ""
    result = subprocess.run(
        ["sh", str(script), str(files["task_plan"])],
        cwd=str(cwd),
        text=True,
        capture_output=True,
        check=False,
    )
    return (result.stdout or result.stderr).strip()


def main_guard(func) -> int:
    try:
        func()
    except Exception as exc:  # pragma: no cover
        print(f"[planning-with-files hook] {exc}", file=sys.stderr)
        return 0
    return 0
