#!/usr/bin/env python3
from __future__ import annotations

import codex_hook_adapter as adapter


def main() -> None:
    payload = adapter.load_payload()
    cwd = adapter.cwd_from_payload(payload)
    parts = [adapter.run_session_catchup(cwd), adapter.render_active_plan_context(cwd)]
    text = "\n\n".join(part for part in parts if part)
    if text:
        adapter.emit_additional_context("SessionStart", text)


if __name__ == "__main__":
    raise SystemExit(adapter.main_guard(main))
