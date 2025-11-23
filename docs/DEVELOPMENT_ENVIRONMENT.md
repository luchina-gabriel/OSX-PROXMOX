# ORION Development Environment Setup

**Complete guide for setting up Zsh, Oh My Zsh, Antigen, and Claude Code for ORION infrastructure development**

---

## 🎯 Overview

This guide covers the complete development environment setup for ORION infrastructure, including:

1. **Zsh Shell** - Modern shell with powerful features
2. **Oh My Zsh** - Framework for managing Zsh configuration
3. **Antigen** - Plugin manager for Zsh
4. **zsh-users plugins** - Essential productivity plugins
5. **Claude Code Integration** - AI-assisted development with local server connectivity

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Zsh Installation](#zsh-installation)
3. [Plugin Configuration](#plugin-configuration)
4. [ORION-Specific Features](#orion-specific-features)
5. [Claude Code Local Server Setup](#claude-code-local-server-setup)
6. [SSH Tunneling for Remote Development](#ssh-tunneling-for-remote-development)
7. [Customization](#customization)
8. [Troubleshooting](#troubleshooting)

---

## 🚀 Quick Start

### Automated Installation

```bash
cd /home/user/luci-macOSX-PROXMOX/shell-config
./install-zsh.sh
```

This script will:
- ✅ Install Zsh
- ✅ Install Oh My Zsh
- ✅ Install Antigen
- ✅ Install zsh-users plugins
- ✅ Configure ORION-specific aliases and functions
- ✅ (Optional) Change your default shell to zsh

---

## 🔧 Zsh Installation

### What Gets Installed

#### 1. **Zsh 5.9** - Modern Shell

```bash
# Installed via apt/yum/dnf
zsh --version
# Output: zsh 5.9 (x86_64-ubuntu-linux-gnu)
```

#### 2. **Oh My Zsh** - Framework

**URL**: https://github.com/ohmyzsh/ohmyzsh

**Included Plugins**:
- `git` - Git aliases and functions
- `docker` - Docker completions and aliases
- `terraform` - Terraform completions
- `ansible` - Ansible completions
- `kubectl` - Kubernetes completions
- `helm` - Helm completions
- `sudo` - Double ESC to prepend sudo
- `command-not-found` - Suggests package for missing commands
- `history` - History management
- `z` - Jump to frequently used directories
- `colored-man-pages` - Colored man pages
- `extract` - Extract any archive with `extract <file>`
- `web-search` - Search from terminal (`google query`)

#### 3. **Antigen** - Plugin Manager

**URL**: https://github.com/zsh-users/antigen

**Purpose**: Manages Zsh plugins from GitHub repositories

#### 4. **zsh-users Plugins**

**Repository**: https://github.com/orgs/zsh-users/repositories

**Installed Plugins**:

| Plugin | Purpose | Example |
|--------|---------|---------|
| **zsh-syntax-highlighting** | Fish-like syntax highlighting | Commands turn green when valid |
| **zsh-autosuggestions** | Fish-like autosuggestions | Shows gray suggestions from history |
| **zsh-completions** | Additional completions | More tab-completion options |
| **zsh-history-substring-search** | Better history search | Press ↑ to search history by substring |

---

## 🎨 Plugin Configuration

### zsh-autosuggestions

**Features**:
- Suggests commands from history as you type
- Press `→` (right arrow) to accept suggestion
- Press `Ctrl+F` to accept word-by-word

**Configuration**:
```bash
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6c757d"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
```

### zsh-syntax-highlighting

**Features**:
- Green: Valid command
- Red: Invalid command
- Magenta: Path
- Cyan: Alias

**Color Scheme**:
```bash
ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=yellow,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=blue,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=magenta'
ZSH_HIGHLIGHT_STYLES[error]='fg=red,bold'
```

### zsh-history-substring-search

**Keybindings**:
```bash
↑ / ↓                # Search history by substring
Ctrl+P / Ctrl+N     # Alternative bindings
```

---

## 🚀 ORION-Specific Features

### Environment Variables

```bash
ORION_ROOT="/home/user/luci-macOSX-PROXMOX"
TF_LOG="INFO"
TF_LOG_PATH="/tmp/terraform.log"
ANSIBLE_STDOUT_CALLBACK="yaml"
ANSIBLE_FORCE_COLOR=true
KUBECONFIG="$HOME/.kube/config"
```

### Navigation Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `orion` | `cd $ORION_ROOT` | Jump to ORION root |
| `tf` | `cd $ORION_ROOT/terraform` | Jump to Terraform |
| `ans` | `cd $ORION_ROOT/ansible` | Jump to Ansible |
| `k8s` | `cd $ORION_ROOT/kubernetes` | Jump to Kubernetes |

### Infrastructure Aliases

#### Terraform
```bash
tfi    # terraform init
tfp    # terraform plan
tfa    # terraform apply
tfd    # terraform destroy
tfo    # terraform output
tfs    # terraform show
```

#### Ansible
```bash
ap     # ansible-playbook
ai     # ansible-inventory
ag     # ansible-galaxy
```

#### Kubernetes
```bash
k      # kubectl
kgp    # kubectl get pods
kgs    # kubectl get svc
kgn    # kubectl get nodes
kd     # kubectl describe
kl     # kubectl logs
ke     # kubectl exec -it
```

#### Docker
```bash
d      # docker
dc     # docker-compose
dps    # docker ps
dim    # docker images
```

#### Make
```bash
m        # make
mh       # make help
mdeploy  # make deploy-full
mverify  # make verify
```

### Custom Functions

#### `deploy()`
Quick deployment of entire ORION stack

```bash
deploy
# Output: 🚀 Deploying ORION infrastructure...
# Runs: make deploy-full
```

#### `orion-status()`
Comprehensive status check

```bash
orion-status
# Shows:
# - Git status
# - Terraform VMs
# - Kubernetes nodes
```

#### SSH Functions
```bash
ssh-router        # SSH to VM 200 (Router)
ssh-coordinator   # SSH to VM 300 (AI Coordinator)
ssh-netbox        # SSH to VM 500 (NetBox)
ssh-k8s-master    # SSH to VM 600 (K8s Master)
```

#### Proxmox Functions
```bash
proxmox-vms       # List Proxmox VMs
proxmox-lxc       # List Proxmox LXC containers
```

---

## 🌐 Claude Code Local Server Setup

### Overview

Claude Code can connect to your local ORION infrastructure server for dependency management, allowing you to:
- Run package managers remotely
- Execute infrastructure commands
- Access local services

### Method 1: SSH Tunneling (Recommended)

**Use Case**: Develop locally while executing commands on remote Proxmox host

#### 1. Setup SSH Tunnel

On your **local machine**:

```bash
# SSH to Proxmox host with port forwarding
ssh -L 8006:192.168.1.100:8006 \
    -L 8000:192.168.100.50:8000 \
    -L 6443:192.168.100.60:6443 \
    root@your-proxmox-host.com
```

**Port Mapping**:
- `8006` → Proxmox Web UI
- `8000` → NetBox
- `6443` → Kubernetes API

#### 2. Configure Claude Code

Add to `.claude/settings.local.json`:

```json
{
  "env": {
    "PROXMOX_API_URL": "https://localhost:8006/api2/json",
    "NETBOX_URL": "http://localhost:8000",
    "KUBECONFIG": "/path/to/local/kubeconfig"
  }
}
```

#### 3. Update Terraform Variables

```bash
# terraform/terraform.tfvars
pm_api_url = "https://localhost:8006/api2/json"
```

### Method 2: Direct Remote Execution

**Use Case**: Execute commands directly on Proxmox host

#### 1. Setup SSH Key Authentication

On your **local machine**:

```bash
# Generate SSH key (if not exists)
ssh-keygen -t ed25519 -C "orion-development"

# Copy to Proxmox host
ssh-copy-id root@your-proxmox-host.com
```

#### 2. Configure Claude Code Remote Execution

Add to `.claude/settings.json`:

```json
{
  "hooks": {
    "preBash": {
      "enabled": true,
      "command": "ssh root@proxmox-host.com 'cd /root/orion && {command}'",
      "description": "Execute commands on remote Proxmox host"
    }
  }
}
```

### Method 3: VS Code Remote - SSH

**Use Case**: Full remote development experience

#### 1. Install VS Code Remote - SSH Extension

```bash
code --install-extension ms-vscode-remote.remote-ssh
```

#### 2. Configure SSH Connection

Add to `~/.ssh/config`:

```
Host orion-proxmox
    HostName your-proxmox-host.com
    User root
    ForwardAgent yes
    LocalForward 8006 192.168.1.100:8006
    LocalForward 8000 192.168.100.50:8000
    LocalForward 6443 192.168.100.60:6443
```

#### 3. Connect to Remote Host

```bash
# In VS Code:
# 1. Cmd/Ctrl + Shift + P
# 2. "Remote-SSH: Connect to Host"
# 3. Select "orion-proxmox"
```

---

## 🔌 SSH Tunneling for Remote Development

### Persistent SSH Tunnel with autossh

#### Install autossh

```bash
# Ubuntu/Debian
sudo apt-get install autossh

# macOS
brew install autossh
```

#### Create Persistent Tunnel

```bash
autossh -M 0 -f -N \
  -L 8006:192.168.1.100:8006 \
  -L 8000:192.168.100.50:8000 \
  -L 6443:192.168.100.60:6443 \
  -o "ServerAliveInterval 30" \
  -o "ServerAliveCountMax 3" \
  root@your-proxmox-host.com
```

#### Systemd Service (Linux)

Create `/etc/systemd/system/orion-tunnel.service`:

```ini
[Unit]
Description=ORION SSH Tunnel
After=network.target

[Service]
Type=simple
User=youruser
ExecStart=/usr/bin/autossh -M 0 -N \
  -L 8006:192.168.1.100:8006 \
  -L 8000:192.168.100.50:8000 \
  -L 6443:192.168.100.60:6443 \
  -o "ServerAliveInterval 30" \
  -o "ServerAliveCountMax 3" \
  root@your-proxmox-host.com
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl enable orion-tunnel
sudo systemctl start orion-tunnel
sudo systemctl status orion-tunnel
```

---

## 🎨 Customization

### Personal Overrides

Create `.claude/settings.local.json` for personal preferences:

```json
{
  "model": "opus",
  "statusLine": "🏗️ {user}@ORION | {model}",

  "env": {
    "MY_PROXMOX_HOST": "192.168.1.100",
    "MY_CUSTOM_VAR": "value"
  },

  "permissions": {
    "defaultMode": "allow"
  }
}
```

### Custom Zsh Aliases

Add to `~/.zshrc` (at the end):

```bash
# Your custom aliases
alias myalias='your-command'

# Your custom functions
my-function() {
  echo "My custom function"
}
```

Or create `~/.zshrc.local` and source it:

```bash
# Add to ~/.zshrc
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
```

---

## 🔧 Troubleshooting

### Issue: Plugins not loading

**Symptom**: zsh-autosuggestions or syntax-highlighting not working

**Solution**:

```bash
# Reinstall Antigen plugins
rm -rf ~/.antigen
zsh  # Restart zsh - plugins will reinstall
```

### Issue: Slow shell startup

**Symptom**: Zsh takes several seconds to start

**Solution**:

```bash
# Disable unnecessary plugins in ~/.zshrc
# Comment out plugins you don't need
plugins=(
  git
  # docker  # Disabled for faster startup
  terraform
  # ...
)
```

### Issue: SSH tunnel disconnects

**Symptom**: Local services become unreachable

**Solution**:

```bash
# Check tunnel status
ps aux | grep ssh

# Restart autossh service
sudo systemctl restart orion-tunnel

# Or manually reconnect
ssh -L 8006:192.168.1.100:8006 root@proxmox-host.com
```

### Issue: Claude Code can't connect to local server

**Symptom**: Connection refused errors

**Solution**:

1. **Verify tunnel is active**:
   ```bash
   curl -k https://localhost:8006/api2/json/version
   ```

2. **Check firewall**:
   ```bash
   # Allow local binding
   ufw allow from 127.0.0.1
   ```

3. **Verify settings**:
   ```bash
   cat .claude/settings.local.json
   ```

---

## 📚 Additional Resources

### Documentation

- **[ARCHITECTURE.md](../ARCHITECTURE.md)** - Main infrastructure documentation
- **[CLAUDE_CODE_INTEGRATION.md](CLAUDE_CODE_INTEGRATION.md)** - Claude Code configuration
- **[Makefile](../Makefile)** - Deployment commands

### External Resources

- **[Oh My Zsh](https://ohmyz.sh/)** - Framework homepage
- **[Antigen](https://github.com/zsh-users/antigen)** - Plugin manager
- **[zsh-users](https://github.com/orgs/zsh-users/repositories)** - Plugin repositories
- **[Claude Code Docs](https://code.claude.com/docs/)** - Official documentation

---

## 🎯 Quick Reference

### Zsh Shortcuts

```bash
Ctrl+A       # Move to beginning of line
Ctrl+E       # Move to end of line
Ctrl+U       # Delete from cursor to beginning
Ctrl+K       # Delete from cursor to end
Ctrl+R       # Reverse search history
Ctrl+L       # Clear screen
Alt+.        # Insert last argument
```

### ORION Quick Commands

```bash
orion-status     # Full status check
deploy           # Deploy everything
orion            # cd to ORION root
m help           # Show make targets
k get pods       # List K8s pods
tfp              # Terraform plan
```

---

**Last Updated**: 2025-11-22
**Status**: Active
**Maintained By**: ORION Infrastructure Team
