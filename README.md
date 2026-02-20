# Agentic Instructions

Reusable instruction templates and architecture references for bootstrapping new projects.

## High-Level Flow

- This repo is the template source of truth.
- Install `ai-bootstrap` once, then run it from inside any target project.
- `general` gives you the cross-project baseline instructions.
- Stack profiles (for example `flutter` or `node`) layer additional rules and references on top.
- Paths are symlinked by default so template updates stay connected; use `--no-symlink` to copy instead.

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

## Profile Discovery

Profiles are discovered automatically from the template source:

- Any `.roo/rules/<profile>.md` file (excluding `general.md` and `AA-CRITICAL-INSTRUCTION.md`)
- Any `docs_<profile>/` directory

This means adding new framework files/folders to those locations immediately creates a new usable profile.

## What Gets Applied

Base files always applied:

- `AGENTS.md`
- `.gemini/styleguide.md`
- `.roo/rules/AA-CRITICAL-INSTRUCTION.md`
- `.roo/rules/general.md`

Each selected profile adds, when present:

- `.roo/rules/<profile>.md`
- `docs_<profile>/`

## Repository Structure

- `ai-bootstrap`: main executable script for dynamic profile discovery, stacking, and symlink/copy apply modes
- `justfile`: convenience commands for running/installing the script
- `.roo/rules/`: base and stack-specific instruction rules
- `.gemini/styleguide.md`: Gemini entry instructions
- `docs_flutter/example-files/`: flutter architecture reference files
- `docs/features/bootstrap-instructions.md`: feature notes for bootstrap behavior
