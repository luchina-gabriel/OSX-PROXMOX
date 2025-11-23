#!/bin/bash
# ORION Infrastructure - Zsh Setup Script
# Installs Oh My Zsh + Antigen + zsh-users plugins

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║         🚀 ORION Infrastructure - Zsh Setup                   ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  SUDO="sudo"
else
  SUDO=""
fi

# 1. Install Zsh
echo "📦 Installing Zsh..."
if ! command -v zsh &> /dev/null; then
  if command -v apt-get &> /dev/null; then
    $SUDO apt-get update && $SUDO apt-get install -y zsh git curl wget jq
  elif command -v yum &> /dev/null; then
    $SUDO yum install -y zsh git curl wget jq
  elif command -v dnf &> /dev/null; then
    $SUDO dnf install -y zsh git curl wget jq
  else
    echo "❌ Unsupported package manager. Please install zsh manually."
    exit 1
  fi
else
  echo "✅ Zsh already installed: $(zsh --version)"
fi

# 2. Install Oh My Zsh
echo ""
echo "📦 Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  echo "✅ Oh My Zsh installed"
else
  echo "✅ Oh My Zsh already installed"
fi

# 3. Install Antigen
echo ""
echo "📦 Installing Antigen..."
if [ ! -f "$HOME/antigen.zsh" ]; then
  curl -L git.io/antigen > "$HOME/antigen.zsh"
  echo "✅ Antigen installed"
else
  echo "✅ Antigen already installed"
fi

# 4. Backup existing .zshrc
if [ -f "$HOME/.zshrc" ]; then
  echo ""
  echo "📝 Backing up existing .zshrc to .zshrc.backup.$(date +%Y%m%d_%H%M%S)"
  cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
fi

# 5. Install ORION .zshrc
echo ""
echo "📝 Installing ORION .zshrc configuration..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
cp "$SCRIPT_DIR/antigen.zsh" "$HOME/antigen.zsh"
echo "✅ Configuration installed"

# 6. Change default shell to zsh (optional)
echo ""
read -p "⚠️  Change default shell to zsh? (requires logout to take effect) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  if command -v chsh &> /dev/null; then
    $SUDO chsh -s $(which zsh) $USER
    echo "✅ Default shell changed to zsh (restart your session)"
  else
    echo "⚠️  chsh command not found. Add 'exec zsh' to your .bashrc to auto-switch"
  fi
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                  ✅ Installation Complete!                    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "🎯 Next steps:"
echo "   1. Start zsh: zsh"
echo "   2. Or logout and login again if you changed default shell"
echo "   3. Plugins will auto-install on first run"
echo ""
echo "📚 Included features:"
echo "   ✅ Oh My Zsh with 14+ plugins"
echo "   ✅ Antigen plugin manager"
echo "   ✅ zsh-users/zsh-syntax-highlighting"
echo "   ✅ zsh-users/zsh-autosuggestions"
echo "   ✅ zsh-users/zsh-completions"
echo "   ✅ zsh-users/zsh-history-substring-search"
echo "   ✅ Custom ORION aliases and functions"
echo ""
echo "💡 Try these commands:"
echo "   orion-status    # Check ORION infrastructure status"
echo "   deploy          # Quick deploy"
echo "   orion           # cd to ORION root"
echo "   tf, ans, k8s    # Navigate to directories"
echo ""
