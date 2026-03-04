# Agentic Instructions

Reusable instruction templates and architecture references for bootstrapping new projects.

## High-Level Flow

- This repo is the template source of truth.
- Install `ai-bootstrap` once, then run it from inside any target project.
- `general` gives you the cross-project baseline instructions.
- Stack profiles (for example `flutter` or `node`) layer additional rules and references on top.
- Paths are symlinked by default so template updates stay connected; use `--no-symlink` to copy instead.
- Command-prefix allowlists are generated from one core config and bootstrapped across agent tools.

Why this structure:

- `AGENTS.md` and `.gemini/styleguide.md` are entry points for different agents.
- `.roo/rules/` holds the actual instruction system.
- `docs_flutter/example-files/` provides architecture examples for stronger first-pass generation.

## Bootstrap Command

Use `ai-bootstrap` from inside a target project directory.

- `ai-bootstrap`: apply the general instruction set
- `ai-bootstrap node`: apply general + node profile
- `ai-bootstrap flutter node`: apply general + both profiles
- `ai-bootstrap --dry-run`: preview changes
- `ai-bootstrap --force`: overwrite existing target paths
- `ai-bootstrap --no-symlink` (or `--no-sim-link`): copy files instead of creating symlinks
- `ai-bootstrap --list-profiles`: print discovered profile names

`just install-bootstrap` creates a symlink at `~/.local/bin/ai-bootstrap` so the command is callable from anywhere.

## Command Prefix Allowlists

- Source of truth: `config/command-prefixes/core.json`
- Generator: `scripts/generate-command-prefixes.py`
- Regenerate: `just allowlist-generate`
- Drift check: `just allowlist-check`
- `ai-bootstrap` automatically prepares generated allowlist files before applying templates.
  - In normal mode, it runs generator write mode.
  - In `--dry-run` mode, it runs generator check mode (`--check`) to avoid writes.

Generated outputs:

- `.codex/rules/default.rules`
- `.gemini/policies/command-prefixes.toml`
- `.claude/settings.json`
- `.vscode/settings.json` (Roo settings keys)

## Profile Discovery

Profiles are discovered automatically from the template source:

- Any `.roo/rules/<profile>.md` file (excluding `general.md` and `AA-CRITICAL-INSTRUCTION.md`)
- Any `docs_<profile>/` directory

This means adding new framework files/folders to those locations immediately creates a new usable profile.

## What Gets Applied

Base files always applied:

- `AGENTS.md`
- `.claude/settings.json`
- `.codex/rules/default.rules`
- `.gemini/styleguide.md`
- `.gemini/policies/command-prefixes.toml`
- `.roo/rules/AA-CRITICAL-INSTRUCTION.md`
- `.roo/rules/general.md`
- `.vscode/settings.json`

Each selected profile adds, when present:

- `.roo/rules/<profile>.md`
- `docs_<profile>/`

## Repository Structure

- `ai-bootstrap`: main executable script for dynamic profile discovery, stacking, and symlink/copy apply modes
- `justfile`: convenience commands for running/installing the script
- `config/command-prefixes/core.json`: source of truth for command-prefix allowlists
- `scripts/generate-command-prefixes.py`: generator for per-agent allowlist files
- `.codex/rules/default.rules`: generated Codex command-prefix rules
- `.gemini/policies/command-prefixes.toml`: generated Gemini CLI policy rules
- `.claude/settings.json`: generated Claude Code command permissions
- `.vscode/settings.json`: generated Roo workspace command permissions
- `.roo/rules/`: base and stack-specific instruction rules
- `.gemini/styleguide.md`: Gemini entry instructions
- `docs_flutter/example-files/`: flutter architecture reference files
- `docs/features/bootstrap-instructions.md`: feature notes for bootstrap behavior
- `docs/features/command-prefix-allowlists.md`: feature notes for cross-agent allowlist generation
