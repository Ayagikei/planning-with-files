#!/usr/bin/env python3
from __future__ import annotations

import codex_hook_adapter as adapter


def main() -> None:
    payload = adapter.load_payload()
    cwd = adapter.cwd_from_payload(payload)
    header = adapter.render_plan_header(cwd, lines=30)
    if header:
        adapter.emit_json({"systemMessage": header})


if __name__ == "__main__":
    raise SystemExit(adapter.main_guard(main))
