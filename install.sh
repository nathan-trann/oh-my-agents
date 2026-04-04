#!/usr/bin/env bash
set -euo pipefail

# Oh My Agents — Installer
# Copies the correct prompt files into your project for the agentic tools you use.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-.}"

# Resolve to absolute path
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

# Colors (skip if not a terminal)
if [ -t 1 ]; then
  BOLD='\033[1m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  CYAN='\033[0;36m'
  RED='\033[0;31m'
  RESET='\033[0m'
else
  BOLD='' GREEN='' YELLOW='' CYAN='' RED='' RESET=''
fi

info()  { echo -e "${CYAN}▸${RESET} $1"; }
ok()    { echo -e "${GREEN}✓${RESET} $1"; }
warn()  { echo -e "${YELLOW}⚠${RESET} $1"; }
err()   { echo -e "${RED}✗${RESET} $1"; }

echo -e "${BOLD}Oh My Agents — Installer${RESET}"
echo "Target project: $TARGET_DIR"
echo ""

# --------------------------------------------------------------------------
# Detect which agentic tools the project uses (or ask)
# --------------------------------------------------------------------------

detected=()

if [ -d "$TARGET_DIR/.claude" ]; then
  detected+=("claude")
fi

if [ -d "$TARGET_DIR/.github" ]; then
  detected+=("copilot")
fi

# Gemini: check for existing GEMINI.md or .gemini/ directory
if [ -f "$TARGET_DIR/GEMINI.md" ] || [ -d "$TARGET_DIR/.gemini" ]; then
  detected+=("gemini")
fi

if [ ${#detected[@]} -gt 0 ]; then
  info "Detected agentic tools: ${detected[*]}"
  echo ""
  echo "Install for these tools? Or choose manually?"
  echo "  [d] Use detected: ${detected[*]}"
  echo "  [m] Choose manually"
  echo "  [a] All tools (Claude Code + Copilot + Gemini)"
  echo ""
  read -r -p "Choice [d/m/a]: " choice
  choice="${choice:-d}"
else
  info "No agentic tool directories detected."
  echo ""
  echo "Which tools do you want to install for?"
  echo "  [m] Choose manually"
  echo "  [a] All tools (Claude Code + Copilot + Gemini)"
  echo ""
  read -r -p "Choice [m/a]: " choice
  choice="${choice:-m}"
fi

install_claude=false
install_copilot=false
install_gemini=false

case "$choice" in
  d)
    for tool in "${detected[@]}"; do
      case "$tool" in
        claude)  install_claude=true ;;
        copilot) install_copilot=true ;;
        gemini)  install_gemini=true ;;
      esac
    done
    ;;
  a)
    install_claude=true
    install_copilot=true
    install_gemini=true
    ;;
  m|*)
    echo ""
    echo "Select tools to install (y/n for each):"
    read -r -p "  Claude Code?    [y/n]: " yn_claude
    read -r -p "  GitHub Copilot? [y/n]: " yn_copilot
    read -r -p "  Gemini CLI?     [y/n]: " yn_gemini
    [[ "$yn_claude"  =~ ^[yY] ]] && install_claude=true
    [[ "$yn_copilot" =~ ^[yY] ]] && install_copilot=true
    [[ "$yn_gemini"  =~ ^[yY] ]] && install_gemini=true
    ;;
esac

if ! $install_claude && ! $install_copilot && ! $install_gemini; then
  err "No tools selected. Nothing to install."
  exit 1
fi

echo ""

# --------------------------------------------------------------------------
# Copy prompt files
# --------------------------------------------------------------------------

copy_with_backup() {
  local src="$1"
  local dst="$2"

  if [ ! -f "$src" ]; then
    err "Source file not found: $src"
    return 1
  fi

  local dst_dir
  dst_dir="$(dirname "$dst")"
  mkdir -p "$dst_dir"

  if [ -f "$dst" ]; then
    warn "File exists: $dst"
    read -r -p "     Overwrite? [y/n]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then
      info "Skipped: $dst"
      return 0
    fi
  fi

  cp "$src" "$dst"
  ok "Installed: $dst"
}

# --- Claude Code ---
if $install_claude; then
  info "Installing Claude Code command..."
  copy_with_backup \
    "$SCRIPT_DIR/src/claude-code/oh-my-agents.md" \
    "$TARGET_DIR/.claude/commands/oh-my-agents.md"

  # Copy templates and specs that the Claude prompt references
  mkdir -p "$TARGET_DIR/.oh-my-agents/spec"
  mkdir -p "$TARGET_DIR/.oh-my-agents/templates/output"
  mkdir -p "$TARGET_DIR/.oh-my-agents/templates/shared"

  cp "$SCRIPT_DIR/spec/core-workflow.md" "$TARGET_DIR/.oh-my-agents/spec/"
  cp "$SCRIPT_DIR/spec/overrides.md" "$TARGET_DIR/.oh-my-agents/spec/"
  cp "$SCRIPT_DIR/templates/output/"*.md "$TARGET_DIR/.oh-my-agents/templates/output/"
  cp "$SCRIPT_DIR/templates/shared/"*.md "$TARGET_DIR/.oh-my-agents/templates/shared/"
  ok "Copied spec + templates to .oh-my-agents/ (referenced by Claude prompt)"
  echo ""
fi

# --- GitHub Copilot ---
if $install_copilot; then
  info "Installing GitHub Copilot agent..."
  copy_with_backup \
    "$SCRIPT_DIR/src/copilot/oh-my-agents.agent.md" \
    "$TARGET_DIR/.github/agents/oh-my-agents.agent.md"
  echo ""
fi

# --- Gemini CLI ---
if $install_gemini; then
  info "Installing Gemini CLI prompt..."
  copy_with_backup \
    "$SCRIPT_DIR/src/gemini/oh-my-agents.md" \
    "$TARGET_DIR/.gemini/prompts/oh-my-agents.md"
  echo ""
fi

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------

echo -e "${BOLD}Installation complete.${RESET}"
echo ""
echo "Usage:"
if $install_claude; then
  echo "  Claude Code:    /oh-my-agents"
  echo "                  (runs the .claude/commands/oh-my-agents.md command)"
fi
if $install_copilot; then
  echo "  Copilot Agent:  Select @oh-my-agents in Copilot Chat, then type 'go'"
fi
if $install_gemini; then
  echo "  Gemini CLI:     Reference .gemini/prompts/oh-my-agents.md in your session"
fi
echo ""
echo "The tool will ask which config formats to generate, then walk you"
echo "through each part of your codebase interactively."
