#!/usr/bin/env python3
from __future__ import annotations

import codex_hook_adapter as adapter


def main() -> None:
    payload = adapter.load_payload()
    cwd = adapter.cwd_from_payload(payload)
    text = adapter.render_active_plan_context(cwd)
    if text:
        print(text)


if __name__ == "__main__":
    raise SystemExit(adapter.main_guard(main))
