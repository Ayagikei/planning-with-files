# Codex Setup

Using planning-with-files with [OpenAI Codex](https://developers.openai.com/codex/).

## Overview

Codex discovers skills from `.codex/skills/` and hooks from `.codex/hooks.json` or `~/.codex/hooks.json`.

This integration includes both:

- `.codex/skills/planning-with-files/` for the skill itself
- `.codex/hooks.json` plus `.codex/hooks/*.py` for lifecycle automation

The Codex hook layer is adapted for this fork:

- it follows the official `hooks.json` flow from Codex docs
- it auto-detects the active planning directory instead of assuming the repo root
- it still falls back to legacy root-level `task_plan.md` when that is what the project uses

> **Important:** Codex hooks require `codex_hooks = true` in `~/.codex/config.toml`.

---

## Installation

### Method 1: Workspace Installation

Commit `.codex/` to your repository so the team shares the same Codex skill and hook behavior:

```bash
# In your project repository
git clone https://github.com/OthmanAdi/planning-with-files.git /tmp/planning-with-files

# Copy the Codex integration to your repo
cp -r /tmp/planning-with-files/.codex .

# Commit to share with team
git add .codex/
git commit -m "Add planning-with-files skill for Codex"
git push

# Clean up
rm -rf /tmp/planning-with-files
```

### Method 2: Personal Installation

Install just for yourself:

```bash
# Clone the repo
git clone https://github.com/OthmanAdi/planning-with-files.git /tmp/planning-with-files

# Copy the skill
mkdir -p ~/.codex/skills
cp -r /tmp/planning-with-files/.codex/skills/planning-with-files ~/.codex/skills/

# Copy hook helpers
mkdir -p ~/.codex/hooks
cp -r /tmp/planning-with-files/.codex/hooks ~/.codex/

# Copy hooks.json
# If you already have ~/.codex/hooks.json, merge the planning-with-files entries manually
cp /tmp/planning-with-files/.codex/hooks.json ~/.codex/hooks.json

# Clean up
rm -rf /tmp/planning-with-files
```

> **Note:** If you already have a `~/.codex/hooks.json`, do not overwrite it blindly. Merge the planning-with-files hook entries into your existing file.

### Enable Hooks in `config.toml`

Ensure your `~/.codex/config.toml` contains:

```toml
[features]
codex_hooks = true
```

If you already have a `[features]` section, add `codex_hooks = true` under it instead of creating a duplicate section.

### Verification

```bash
codex --version
codex features list | rg '^codex_hooks\\s'
ls -la ~/.codex/skills/planning-with-files/SKILL.md
ls -la ~/.codex/hooks.json
ls -la ~/.codex/hooks
```

If `codex_hooks` does not appear in `codex features list`, upgrade Codex before troubleshooting the skill.

---

## How It Works

### Hooks

Codex reads hooks from:

1. `.codex/hooks.json` in your project root
2. `~/.codex/hooks.json` for your global install

This integration includes two Codex lifecycle hooks:

| Hook | What It Does |
|------|--------------|
| **SessionStart** | Reminds the agent to check for existing planning files or create them only if the task needs persistent tracking |
| **Stop** | Reminds the agent to update `progress.md` and `task_plan.md` before ending if planning was used |

`UserPromptSubmit` is intentionally not enabled in this fork's Codex integration. It fires on every user message and is too noisy for long sessions.
`PreToolUse` is intentionally not enabled in this fork's Codex integration. Re-reading planning context before every Bash command added noise without enough value.
`PostToolUse` is intentionally not enabled in this fork's Codex integration. In current Codex runtimes it only matches `Bash`, so it fires too often to be a useful planning reminder.

### The Three Files

Once activated, the skill creates and maintains:

| File | Purpose | Location |
|------|---------|----------|
| `task_plan.md` | Phases, progress, decisions | Active planning directory |
| `findings.md` | Research, discoveries | Active planning directory |
| `progress.md` | Session log, test results | Active planning directory |

This fork intentionally avoids trying to auto-select an "active plan" in Codex hooks. The SessionStart reminder asks the agent to inspect the repo and make that decision in-context instead.

---

## Team Workflow

### Workspace Installation

With workspace installation (`.codex/` committed to your repo):

- everyone on the team gets the same skill and hooks
- the Codex setup is version controlled with the project
- updates ship through normal git review

### Personal Installation

With personal installation (`~/.codex/`):

- you can use the skill across all projects
- you keep your setup even if you change repositories
- existing global hooks may need manual merging

---

## Troubleshooting

### Hooks Not Running?

1. Check that `codex_hooks = true` is present in `~/.codex/config.toml`
2. Verify `.codex/hooks.json` or `~/.codex/hooks.json` exists
3. Restart Codex after adding or changing hooks
4. Run `codex features list | rg '^codex_hooks\\s'`
5. If you use docs-based planning locations, make sure at least `task_plan.md` exists in the active planning directory

### Already Using Other Global Hooks?

That is fine, but do not overwrite your existing `~/.codex/hooks.json`. Merge the planning-with-files entries instead.

### Seeing Duplicate Hook Messages?

Avoid installing the same planning-with-files hooks in both places at once:

- workspace `.codex/hooks.json`
- global `~/.codex/hooks.json`

If you enable both, Codex may run both sets of hooks and duplicate the reminders.

### Windows Support

OpenAI's current Codex hooks documentation says hooks are disabled on Windows. The skill files can still be installed there, but the hook automation is currently for macOS/Linux Codex environments.

---

## Support

- **GitHub Issues:** https://github.com/OthmanAdi/planning-with-files/issues
- **OpenAI Codex Hooks Docs:** https://developers.openai.com/codex/hooks
- **OpenAI Codex Skills Docs:** https://developers.openai.com/codex/skills
