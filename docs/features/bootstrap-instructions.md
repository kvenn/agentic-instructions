# Bootstrap Instructions Script

## Goal

Provide a single command (`ai-bootstrap`) that can be run from any project directory to apply this repository's instruction templates into that project.

## Profiles

- `general` (always included): Core cross-project instruction files.
- Additional profiles are auto-discovered from:
  - `.roo/rules/<profile>.md` files (except `general.md` and `AA-CRITICAL-INSTRUCTION.md`)
  - `docs_<profile>/` folders
- Multiple profiles can be stacked in one call, for example `ai-bootstrap flutter node`.

## Behavior

- Safe by default: existing files are skipped.
- Symlink mode is the default (`ln -s`).
- `--no-symlink` / `--no-sim-link`: copy files and directories instead of symlinking.
- `--force`: overwrite existing target files.
- `--dry-run`: preview what would be applied.
- `--list-profiles`: print discovered profile names and exit.
- `--source <path>`: read templates from a different instructions repo path.

## Files

- `ai-bootstrap`: Main executable script that resolves template source path, discovers profiles, and applies symlink/copy operations.
- `justfile`: Task shortcuts for bootstrap, dry-run, force, copy mode, profile listing, and local install into `~/.local/bin`.

## Integration Notes

- The script is designed to be symlinked into a PATH directory (for example `~/.local/bin/ai-bootstrap`) while still reading templates from this repository.
- Adding a new `.roo/rules/<profile>.md` file or `docs_<profile>/` folder immediately makes that profile available to `ai-bootstrap`.
