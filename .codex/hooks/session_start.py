#!/usr/bin/env python3
from __future__ import annotations

import codex_hook_adapter as adapter


def main() -> None:
    adapter.load_payload()
    adapter.emit_additional_context(
        "SessionStart",
        (
            "[planning-with-files] If this task is complex, first check whether the repo already has planning files "
            "(for example docs/plans, docs/plan, docs/planning, or an existing task_plan.md). "
            "If a plan exists, read task_plan.md, progress.md, and findings.md before continuing. "
            "If not, create planning files only when the task actually needs persistent tracking."
        ),
    )


if __name__ == "__main__":
    raise SystemExit(adapter.main_guard(main))
