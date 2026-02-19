# Agentic Instructions

Reusable instruction templates and architecture references for bootstrapping new projects.

## High-Level Flow

- This repo is the template source of truth.
- Install `ai-bootstrap` once, then run it from inside any target project.
- `general` gives you the cross-project baseline instructions.
- Stack profiles (for example `flutter`) layer additional rules and references on top.
- Copied files become local project files that you can tune per repo after bootstrapping.

Why this structure:

- `AGENTS.md` and `.gemini/styleguide.md` are entry points for different agents.
- `.roo/rules/` holds the actual instruction system.
- `docs_flutter/example-files/` provides architecture examples for stronger first-pass generation.

## Bootstrap Command

Use `ai-bootstrap` from inside a target project directory.

- `ai-bootstrap`: copy the general instruction set
- `ai-bootstrap flutter`: copy general + flutter instruction set
- `ai-bootstrap --dry-run`: preview changes
- `ai-bootstrap --force`: overwrite existing files

`just install-bootstrap` creates a symlink at `~/.local/bin/ai-bootstrap` so the command is callable from anywhere.

## What Gets Copied

General profile:

- `AGENTS.md`
- `.gemini/styleguide.md`
- `.roo/rules/AA-CRITICAL-INSTRUCTION.md`
- `.roo/rules/general.md`

Flutter profile adds:

- `.roo/rules/flutter.md`
- `docs_flutter/`

## Repository Structure

- `ai-bootstrap`: main executable script for profile-based copying
- `justfile`: convenience commands for running/installing the script
- `.roo/rules/`: base and stack-specific instruction rules
- `.gemini/styleguide.md`: Gemini entry instructions
- `docs_flutter/example-files/`: flutter architecture reference files
- `docs/features/bootstrap-instructions.md`: feature notes for bootstrap behavior
