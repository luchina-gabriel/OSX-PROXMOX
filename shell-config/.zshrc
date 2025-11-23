# ORION Infrastructure - Zsh Configuration
# Optimized for infrastructure development with Oh My Zsh + Antigen

# ============================================================================
# Oh My Zsh Base Configuration
# ============================================================================

# Path to your Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="agnoster"  # Better theme for infrastructure work

# Update behavior
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 7

# Completion waiting dots
COMPLETION_WAITING_DOTS="true"

# Command execution timestamp
HIST_STAMPS="yyyy-mm-dd"

# Plugins from Oh My Zsh
plugins=(
  git
  docker
  terraform
  ansible
  kubectl
  helm
  sudo
  command-not-found
  history
  z
  colored-man-pages
  extract
  web-search
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ============================================================================
# Antigen Configuration (zsh-users plugins)
# ============================================================================

# Load Antigen
source ~/antigen.zsh

# Load oh-my-zsh library
antigen use oh-my-zsh

# zsh-users plugins (https://github.com/orgs/zsh-users/repositories)
antigen bundle zsh-users/zsh-syntax-highlighting       # Fish-like syntax highlighting
antigen bundle zsh-users/zsh-autosuggestions           # Fish-like autosuggestions
antigen bundle zsh-users/zsh-completions               # Additional completions
antigen bundle zsh-users/zsh-history-substring-search  # Better history search

# Apply Antigen configuration
antigen apply

# ============================================================================
# zsh-users Plugin Configuration
# ============================================================================

# zsh-autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6c757d"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# zsh-syntax-highlighting
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=yellow,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=blue,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=magenta'
ZSH_HIGHLIGHT_STYLES[error]='fg=red,bold'

# zsh-history-substring-search (bind keys)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down

# ============================================================================
# Environment Variables for ORION
# ============================================================================

# ORION project root
export ORION_ROOT="/home/user/luci-macOSX-PROXMOX"

# Terraform
export TF_LOG="INFO"
export TF_LOG_PATH="/tmp/terraform.log"

# Ansible
export ANSIBLE_STDOUT_CALLBACK="yaml"
export ANSIBLE_FORCE_COLOR=true

# Kubernetes
export KUBECONFIG="$HOME/.kube/config"

# ============================================================================
# Aliases for ORION Infrastructure
# ============================================================================

# Navigation
alias orion='cd $ORION_ROOT'
alias tf='cd $ORION_ROOT/terraform'
alias ans='cd $ORION_ROOT/ansible'
alias k8s='cd $ORION_ROOT/kubernetes'

# Terraform shortcuts
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfo='terraform output'
alias tfs='terraform show'

# Ansible shortcuts
alias ap='ansible-playbook'
alias ai='ansible-inventory'
alias ag='ansible-galaxy'

# Kubectl shortcuts
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ke='kubectl exec -it'

# Docker shortcuts
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dim='docker images'

# Make shortcuts
alias m='make'
alias mh='make help'
alias mdeploy='make deploy-full'
alias mverify='make verify'

# Git shortcuts (enhanced)
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

# System shortcuts
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ============================================================================
# Functions for ORION Infrastructure
# ============================================================================

# Quick deploy function
deploy() {
  echo "🚀 Deploying ORION infrastructure..."
  cd $ORION_ROOT
  make deploy-full
}

# Quick status check
orion-status() {
  echo "📊 ORION Infrastructure Status"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  cd $ORION_ROOT
  echo "\n📁 Git Status:"
  git status --short
  echo "\n🏗️  Terraform Status:"
  cd terraform && terraform show -json 2>/dev/null | jq -r '.values.root_module.resources[] | select(.type == "proxmox_vm_qemu") | "\(.values.name) (VM \(.values.vmid))"' || echo "No Terraform state"
  echo "\n☸️  Kubernetes Status (if running):"
  kubectl get nodes 2>/dev/null || echo "K8s cluster not accessible"
}

# SSH to VMs
ssh-router() {
  ssh root@192.168.100.1
}

ssh-coordinator() {
  ssh root@192.168.100.30
}

ssh-netbox() {
  ssh root@192.168.100.50
}

ssh-k8s-master() {
  ssh root@192.168.100.60
}

# Proxmox helper
proxmox-vms() {
  echo "📦 Proxmox VMs:"
  qm list 2>/dev/null || echo "Not connected to Proxmox host"
}

# LXC helper
proxmox-lxc() {
  echo "📦 Proxmox LXC Containers:"
  pct list 2>/dev/null || echo "Not connected to Proxmox host"
}

# ============================================================================
# User Configuration
# ============================================================================

# Preferred editor
export EDITOR='nano'
export VISUAL='nano'

# Language environment
export LANG=en_US.UTF-8

# Compilation flags
export ARCHFLAGS="-arch x86_64"

# History settings
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt SHARE_HISTORY

# ============================================================================
# Welcome Message
# ============================================================================

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║          🚀 ORION Infrastructure Development Shell            ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "📘 Main docs: ARCHITECTURE.md"
echo "🔧 Deploy: make deploy-full  or  deploy"
echo "📊 Status: orion-status"
echo "💡 Quick nav: orion, tf, ans, k8s"
echo "⚡ Shortcuts: m (make), k (kubectl), tf* (terraform)"
echo ""
