# Codex IDE Support

## Overview

planning-with-files works with Codex as a personal skill in `~/.codex/skills/`.

## Installation

See [.codex/INSTALL.md](../.codex/INSTALL.md) for detailed installation instructions.

### Quick Install

```bash
mkdir -p ~/.codex/skills
cd ~/.codex/skills
git clone https://github.com/OthmanAdi/planning-with-files.git
```

## Usage with Superpowers

If you have [obra/superpowers](https://github.com/obra/superpowers) installed:

```bash
~/.codex/superpowers/.codex/superpowers-codex use-skill planning-with-files
```

## Usage without Superpowers

Add to your `~/.codex/AGENTS.md`:

```markdown
## Planning with Files

<IMPORTANT>
For complex tasks (3+ steps, research, projects):
1. Read skill: `cat ~/.codex/skills/planning-with-files/planning-with-files/SKILL.md`
2. Create task_plan.md, findings.md, progress.md in your project directory
3. Follow 3-file pattern throughout the task
</IMPORTANT>
```

## Codex Notes

- Codex does not require `session-catchup.py` and does not set `CLAUDE_PLUGIN_ROOT`. In Codex, explicitly skip session-catchup and state that it is not needed.

## Verification

```bash
ls -la ~/.codex/skills/planning-with-files/planning-with-files/SKILL.md
```

## Learn More

- [Installation Guide](installation.md)
- [Quick Start](quickstart.md)
- [Workflow Diagram](workflow.md)
