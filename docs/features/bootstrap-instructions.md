# Bootstrap Instructions Script

## Goal

Provide a single command (`ai-bootstrap`) that can be run from any project directory to copy this repository's instruction templates into that project.

## Profiles

- `general` (default): Copies core cross-project instruction files.
- `flutter`: Copies everything in `general` plus flutter-specific templates.

## Behavior

- Safe by default: existing files are skipped.
- `--force`: overwrite existing target files.
- `--dry-run`: preview what would be copied.
- `--source <path>`: read templates from a different instructions repo path.

## Files

- `ai-bootstrap`: Main executable script that resolves its own template source path and applies profile manifests.
- `justfile`: Task shortcuts for normal bootstrap usage, dry-run, force mode, and local install into `~/.local/bin`.

## Integration Notes

- The script is designed to be symlinked into a PATH directory (for example `~/.local/bin/ai-bootstrap`) while still reading templates from this repository.
- Profile manifests are defined in the script so new stacks can be added as new profile arrays.
