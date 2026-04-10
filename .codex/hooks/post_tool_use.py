#!/usr/bin/env python3
from __future__ import annotations

import codex_hook_adapter as adapter


def main() -> None:
    payload = adapter.load_payload()
    cwd = adapter.cwd_from_payload(payload)
    files = adapter.planning_files(cwd)
    if files is None:
        return
    message = (
        "[planning-with-files] Update progress.md with what you just did. "
        "If a phase is now complete, update task_plan.md status."
    )
    adapter.emit_json({"systemMessage": message})


if __name__ == "__main__":
    raise SystemExit(adapter.main_guard(main))
