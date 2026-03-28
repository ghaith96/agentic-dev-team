#!/usr/bin/env zsh
# install-cursor.sh — Install agentic-dev-team configs into Cursor IDE
#
# This script installs agents, skills, commands, hooks, and knowledge files
# into Cursor's configuration directories.
#
# Usage:
#   ./install-cursor.sh                    # Interactive mode
#   ./install-cursor.sh --user             # Install to user-level (~/.cursor/)
#   ./install-cursor.sh --project          # Install to project-level (.cursor/)
#   ./install-cursor.sh --target <path>    # Install to specific project path
#   ./install-cursor.sh --symlink          # Use symlinks instead of copies
#   ./install-cursor.sh --dry-run          # Show what would be done
#   ./install-cursor.sh --uninstall        # Remove installed files
#
# Examples:
#   ./install-cursor.sh --user --symlink   # Symlink to user config
#   ./install-cursor.sh --project          # Copy to current project
#   ./install-cursor.sh --target ../other-project --symlink  # Install to another project

set -euo pipefail

# --- Configuration ---
# Get script directory and name (zsh syntax)
SCRIPT_DIR="${0:A:h}"
SCRIPT_NAME="${0:t}"
CURSOR_USER_DIR="${HOME}/.cursor"
CURSOR_PROJECT_DIR=".cursor"

# Directories to install
INSTALL_DIRS=(agents skills commands hooks knowledge prompts templates)

# Files to install
INSTALL_FILES=(CLAUDE.md AGENTS.md review-config.json)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Default options ---
INSTALL_SCOPE=""  # "user", "project", or "target"
TARGET_PATH=""    # Custom target path (used with --target)
USE_SYMLINK=false
DRY_RUN=false
UNINSTALL=false
FORCE=false

# --- Helper functions ---
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC}   $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Install agentic-dev-team configs into Cursor IDE.

Options:
  --user           Install to user-level config (~/.cursor/)
  --project        Install to project-level config (.cursor/)
  --target <path>  Install to a specific project path (<path>/.cursor/)
  --symlink        Use symlinks instead of copying files
  --copy           Use copies instead of symlinks (default)
  --dry-run        Show what would be done without making changes
  --uninstall      Remove previously installed files
  --force          Overwrite existing files without prompting
  -h, --help       Show this help message

Examples:
  $SCRIPT_NAME --user --symlink              # Symlink configs to ~/.cursor/
  $SCRIPT_NAME --project                     # Copy configs to .cursor/
  $SCRIPT_NAME --target ../linksink --symlink  # Install to another project
  $SCRIPT_NAME --uninstall --user            # Remove user-level installation

EOF
  exit 0
}

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case $1 in
    --user)
      INSTALL_SCOPE="user"
      shift
      ;;
    --project)
      INSTALL_SCOPE="project"
      shift
      ;;
    --target)
      INSTALL_SCOPE="target"
      if [[ -z "${2:-}" ]]; then
        log_error "--target requires a path argument"
        exit 1
      fi
      TARGET_PATH="$2"
      shift 2
      ;;
    --symlink)
      USE_SYMLINK=true
      shift
      ;;
    --copy)
      USE_SYMLINK=false
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --uninstall)
      UNINSTALL=true
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      log_error "Unknown option: $1"
      usage
      ;;
  esac
done

# --- Interactive mode if scope not specified ---
if [[ -z "$INSTALL_SCOPE" ]]; then
  # Check if we have a terminal for interactive input
  if [[ ! -t 0 ]]; then
    log_error "No install scope specified and stdin is not a terminal."
    echo ""
    echo "Usage: $SCRIPT_NAME --user|--project [--symlink] [--force]"
    echo ""
    echo "Examples:"
    echo "  $SCRIPT_NAME --user --symlink    # Symlink to ~/.cursor/"
    echo "  $SCRIPT_NAME --project           # Copy to .cursor/"
    echo ""
    exit 1
  fi

  echo ""
  echo "Agentic Dev Team — Cursor Installation"
  echo "======================================="
  echo ""
  echo "Where would you like to install?"
  echo ""
  echo "  1) User-level (~/.cursor/)"
  echo "     - Available in all projects"
  echo "     - Persists across project changes"
  echo ""
  echo "  2) Project-level (.cursor/)"
  echo "     - Only available in this project"
  echo "     - Can be version-controlled"
  echo ""
  printf "Select [1/2]: "
  read -r choice || { log_error "Failed to read input"; exit 1; }
  case $choice in
    1) INSTALL_SCOPE="user" ;;
    2) INSTALL_SCOPE="project" ;;
    *)
      log_error "Invalid choice. Exiting."
      exit 1
      ;;
  esac

  echo ""
  echo "How should files be installed?"
  echo ""
  echo "  1) Copy files"
  echo "     - Independent copies"
  echo "     - Won't update when source changes"
  echo ""
  echo "  2) Symlink files"
  echo "     - Links to source"
  echo "     - Auto-updates when source changes"
  echo ""
  printf "Select [1/2]: "
  read -r link_choice || { log_error "Failed to read input"; exit 1; }
  case $link_choice in
    1) USE_SYMLINK=false ;;
    2) USE_SYMLINK=true ;;
    *)
      log_error "Invalid choice. Exiting."
      exit 1
      ;;
  esac
  echo ""
fi

# --- Set target directory based on scope ---
if [[ "$INSTALL_SCOPE" == "user" ]]; then
  TARGET_DIR="$CURSOR_USER_DIR"
elif [[ "$INSTALL_SCOPE" == "target" ]]; then
  # Resolve to absolute path and append .cursor
  if [[ ! -d "$TARGET_PATH" ]]; then
    log_error "Target directory does not exist: $TARGET_PATH"
    exit 1
  fi
  TARGET_DIR="${TARGET_PATH:A}/.cursor"
else
  TARGET_DIR="$CURSOR_PROJECT_DIR"
fi

# --- Verify source directory ---
if [[ ! -d "$SCRIPT_DIR/agents" ]]; then
  log_error "Source directory not found. Run this script from the agentic-dev-team repository."
  exit 1
fi

# --- Uninstall mode ---
uninstall() {
  log_info "Uninstalling from $TARGET_DIR..."
  
  local removed=0
  
  for dir in "${INSTALL_DIRS[@]}"; do
    local target="$TARGET_DIR/$dir"
    if [[ -L "$target" ]]; then
      if $DRY_RUN; then
        log_info "[DRY-RUN] Would remove symlink: $target"
      else
        rm -f "$target"
        log_success "Removed symlink: $target"
      fi
      removed=$((removed + 1))
    elif [[ -d "$target" ]]; then
      # Check if it contains our marker file
      if [[ -f "$target/.agentic-dev-team" ]]; then
        if $DRY_RUN; then
          log_info "[DRY-RUN] Would remove directory: $target"
        else
          rm -rf "$target"
          log_success "Removed directory: $target"
        fi
        removed=$((removed + 1))
      else
        log_warn "Skipping $target (not installed by this script)"
      fi
    fi
  done
  
  for file in "${INSTALL_FILES[@]}"; do
    local target="$TARGET_DIR/$file"
    if [[ -L "$target" ]] || [[ -f "$target" ]]; then
      if $DRY_RUN; then
        log_info "[DRY-RUN] Would remove: $target"
      else
        rm -f "$target"
        log_success "Removed: $target"
      fi
      removed=$((removed + 1))
    fi
  done
  
  if [[ $removed -eq 0 ]]; then
    log_info "Nothing to uninstall."
  else
    log_success "Uninstalled $removed items."
  fi
}

if $UNINSTALL; then
  uninstall
  exit 0
fi

# --- Create target directory ---
if $DRY_RUN; then
  log_info "[DRY-RUN] Would create: $TARGET_DIR"
else
  mkdir -p "$TARGET_DIR"
fi

# --- Install function ---
install_item() {
  local src="$1"
  local dest="$2"
  local name="$3"
  
  if [[ ! -e "$src" ]]; then
    log_warn "Source not found: $src"
    return
  fi
  
  # Check if destination exists
  if [[ -e "$dest" ]] || [[ -L "$dest" ]]; then
    if $FORCE; then
      if $DRY_RUN; then
        log_info "[DRY-RUN] Would remove existing: $dest"
      else
        rm -rf "$dest"
      fi
    else
      if [[ -L "$dest" ]]; then
        local existing_target
        existing_target=$(readlink "$dest")
        if [[ "$existing_target" == "$src" ]]; then
          log_info "Already linked: $name"
          return
        fi
      fi
      log_warn "Exists: $dest (use --force to overwrite)"
      return
    fi
  fi
  
  if $USE_SYMLINK; then
    if $DRY_RUN; then
      log_info "[DRY-RUN] Would symlink: $dest -> $src"
    else
      ln -s "$src" "$dest"
      log_success "Linked: $name"
    fi
  else
    if $DRY_RUN; then
      log_info "[DRY-RUN] Would copy: $src -> $dest"
    else
      if [[ -d "$src" ]]; then
        cp -rf "$src" "$dest"
        # Add marker file for uninstall
        touch "$dest/.agentic-dev-team"
      else
        cp -f "$src" "$dest"
      fi
      log_success "Copied: $name"
    fi
  fi
}

# --- Main installation ---
echo ""
log_info "Installing to: $TARGET_DIR"
log_info "Method: $(if $USE_SYMLINK; then echo 'symlink'; else echo 'copy'; fi)"
echo ""

# Install directories
for dir in "${INSTALL_DIRS[@]}"; do
  src="$SCRIPT_DIR/$dir"
  dest="$TARGET_DIR/$dir"
  install_item "$src" "$dest" "$dir/"
done

# Install files
for file in "${INSTALL_FILES[@]}"; do
  src="$SCRIPT_DIR/$file"
  dest="$TARGET_DIR/$file"
  install_item "$src" "$dest" "$file"
done

# --- Install hooks configuration ---
install_hooks_config() {
  local hooks_json="$TARGET_DIR/hooks.json"
  
  if [[ -f "$hooks_json" ]] && ! $FORCE; then
    log_warn "hooks.json exists (use --force to overwrite)"
    return
  fi
  
  # Determine hooks path prefix based on install scope
  # User-level (~/.cursor/): use "./hooks/" since scripts run from ~/.cursor/
  # Project-level (.cursor/): use ".cursor/hooks/" since scripts run from project root
  local hooks_prefix
  if [[ "$INSTALL_SCOPE" == "user" ]]; then
    hooks_prefix="./hooks"
  else
    hooks_prefix=".cursor/hooks"
  fi
  
  # Generate Cursor-compatible hooks.json
  # Cursor format: https://cursor.com/docs/hooks
  local hooks_content
  hooks_content=$(cat <<HOOKS_EOF
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "command": "$hooks_prefix/pre-tool-guard.sh",
        "matcher": "Write|Edit"
      },
      {
        "command": "$hooks_prefix/destructive-guard.sh",
        "matcher": "Shell"
      }
    ],
    "postToolUse": [
      {
        "command": "$hooks_prefix/js-fp-review.sh",
        "matcher": "Write|Edit|StrReplace"
      },
      {
        "command": "$hooks_prefix/token-efficiency-review.sh",
        "matcher": "Write|Edit|StrReplace"
      },
      {
        "command": "$hooks_prefix/tdd-guard.sh",
        "matcher": "Write|Edit|StrReplace"
      }
    ],
    "afterFileEdit": [
      {
        "command": "$hooks_prefix/eval-compliance-check.sh"
      }
    ],
    "beforeReadFile": [
      {
        "command": "$hooks_prefix/version-check.sh"
      }
    ]
  }
}
HOOKS_EOF
)

  if $DRY_RUN; then
    log_info "[DRY-RUN] Would create: hooks.json (Cursor-compatible format)"
  else
    echo "$hooks_content" > "$hooks_json"
    log_success "Created: hooks.json (Cursor-compatible format)"
  fi
}

# Only install hooks config if we have hooks directory
if [[ -d "$SCRIPT_DIR/hooks" ]]; then
  install_hooks_config
fi

# --- Post-installation summary ---
echo ""
echo "========================================="
if $DRY_RUN; then
  log_info "Dry run complete. No changes made."
else
  log_success "Installation complete!"
fi
echo ""

if ! $DRY_RUN; then
  echo "Installed to: $TARGET_DIR"
  echo ""
  echo "Contents:"
  if $USE_SYMLINK; then
    ls -la "$TARGET_DIR" 2>/dev/null | head -20 || true
  else
    ls -1 "$TARGET_DIR" 2>/dev/null || true
  fi
  echo ""
  
  if [[ "$INSTALL_SCOPE" == "project" ]] || [[ "$INSTALL_SCOPE" == "target" ]]; then
    echo "Next steps:"
    echo "  1. Add .cursor/ to .gitignore (if not tracking configs)"
    echo "  2. Or commit .cursor/ to share configs with team"
  else
    echo "User-level configs installed."
    echo "These will be available in all Cursor projects."
  fi
fi

echo ""
if [[ "$INSTALL_SCOPE" == "target" ]]; then
  echo "To uninstall: $SCRIPT_NAME --uninstall --target \"$TARGET_PATH\""
else
  echo "To uninstall: $SCRIPT_NAME --uninstall --$INSTALL_SCOPE"
fi
echo ""
