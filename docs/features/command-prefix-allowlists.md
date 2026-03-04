# Command Prefix Allowlists

## Goal

Maintain one source of truth for command-prefix approvals, then generate per-agent config files so the same allowlist policy can be shared across projects.

## Core API

- Core input file: `config/command-prefixes/core.json`
- Generator: `scripts/generate-command-prefixes.py`
- Just commands:
  - `just allowlist-generate`: regenerate all agent files from the core config.
  - `just allowlist-check`: fail if generated files drift from the core config.

## Generated Files

- `.codex/rules/default.rules`
  - Codex `prefix_rule(...)` entries.
- `.gemini/policies/command-prefixes.toml`
  - Gemini CLI policy-engine rules for `run_shell_command`.
- `.claude/settings.json`
  - Claude Code permissions with `Bash(...)` allow entries.
- `.vscode/settings.json`
  - Roo Code workspace settings (`roo-cline.allowedCommands` and `roo-cline.deniedCommands`).

## Bootstrap Integration

- `ai-bootstrap` runs allowlist preparation automatically before applying templates.
  - Normal mode runs generator write mode.
  - `--dry-run` runs generator check mode (`--check`) and does not write files.
- `ai-bootstrap` applies these generated files as base templates.
- In default symlink mode, changes to generated files in this repo automatically propagate to bootstrapped projects that are symlinked.
- In copy mode, projects keep a snapshot and need re-bootstrap or manual sync.
