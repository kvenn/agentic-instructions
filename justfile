set dotenv-load := true

default:
    @just --list

# Bootstrap templates into the current directory.
# Params: *args = zero or more profile names and/or ai-bootstrap options.
bootstrap *args:
    ./ai-bootstrap {{args}}

# Preview bootstrap operations without writing files.
# Params: *args = zero or more profile names and/or ai-bootstrap options.
bootstrap-dry-run *args:
    ./ai-bootstrap --dry-run {{args}}

# Overwrite existing target paths when they already exist.
# Params: *args = zero or more profile names and/or ai-bootstrap options.
bootstrap-force *args:
    ./ai-bootstrap --force {{args}}

# Copy files instead of symlinking (symlink mode is the default).
# Params: *args = zero or more profile names and/or ai-bootstrap options.
bootstrap-copy *args:
    ./ai-bootstrap --no-symlink {{args}}

# Print discovered profile names based on .roo/rules and docs_<profile> folders.
bootstrap-list-profiles:
    ./ai-bootstrap --list-profiles

# Symlink ai-bootstrap into ~/.local/bin so it can be called from anywhere.
install-bootstrap:
    mkdir -p "$HOME/.local/bin"
    ln -sf "{{justfile_directory()}}/ai-bootstrap" "$HOME/.local/bin/ai-bootstrap"
    @echo "Installed ai-bootstrap to $HOME/.local/bin/ai-bootstrap"
    @echo "Ensure $HOME/.local/bin is in PATH."
