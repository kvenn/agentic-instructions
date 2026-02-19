set dotenv-load := true

default:
    @just --list

# Copy template files into the current directory.
bootstrap profile="general":
    ./ai-bootstrap {{profile}}

# Preview copy operations without writing files.
bootstrap-dry-run profile="general":
    ./ai-bootstrap {{profile}} --dry-run

# Overwrite files in the target directory when they already exist.
bootstrap-force profile="general":
    ./ai-bootstrap {{profile}} --force

# Symlink ai-bootstrap into ~/.local/bin so it can be called from anywhere.
install-bootstrap:
    mkdir -p "$HOME/.local/bin"
    ln -sf "{{justfile_directory()}}/ai-bootstrap" "$HOME/.local/bin/ai-bootstrap"
    @echo "Installed ai-bootstrap to $HOME/.local/bin/ai-bootstrap"
    @echo "Ensure $HOME/.local/bin is in PATH."
