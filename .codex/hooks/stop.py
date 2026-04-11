#!/usr/bin/env python3
from __future__ import annotations

import codex_hook_adapter as adapter


def main() -> None:
    adapter.load_payload()
    adapter.emit_json(
        {
            "systemMessage": (
                "[planning-with-files] Before stopping, if you used planning files in this task, "
                "update progress.md and task_plan.md to reflect the latest state."
            )
        }
    )


if __name__ == "__main__":
    raise SystemExit(adapter.main_guard(main))
