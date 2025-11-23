# ORION Shell Configuration

**Zsh + Oh My Zsh + Antigen + zsh-users plugins for infrastructure development**

---

## 🚀 Quick Start

```bash
# Run the installation script
./install-zsh.sh

# Start zsh
zsh

# Or set as default shell (requires logout)
chsh -s $(which zsh)
```

---

## 📦 What's Included

- **Zsh 5.9** - Modern shell
- **Oh My Zsh** - Framework with 14+ infrastructure plugins
- **Antigen** - Plugin manager
- **zsh-users plugins**:
  - `zsh-syntax-highlighting` - Fish-like syntax highlighting
  - `zsh-autosuggestions` - Fish-like autosuggestions
  - `zsh-completions` - Additional completions
  - `zsh-history-substring-search` - Better history search

---

## 📁 Files

```
shell-config/
├── .zshrc              # Complete Zsh configuration
├── antigen.zsh         # Antigen plugin manager
├── install-zsh.sh      # Automated installation script
└── README.md           # This file
```

---

## 🎯 Features

### Infrastructure Aliases

```bash
# Navigation
orion, tf, ans, k8s

# Terraform
tfi, tfp, tfa, tfd, tfo, tfs

# Kubernetes
k, kgp, kgs, kgn, kd, kl, ke

# Make
m, mh, mdeploy, mverify
```

### Custom Functions

```bash
deploy()              # Quick deploy ORION stack
orion-status()        # Complete infrastructure status
ssh-router()          # SSH to router VM
ssh-coordinator()     # SSH to AI coordinator
ssh-netbox()          # SSH to NetBox
ssh-k8s-master()      # SSH to K8s master
proxmox-vms()         # List Proxmox VMs
proxmox-lxc()         # List LXC containers
```

---

## 📚 Documentation

See **[docs/DEVELOPMENT_ENVIRONMENT.md](../docs/DEVELOPMENT_ENVIRONMENT.md)** for complete documentation including:

- Detailed installation guide
- Plugin configuration
- Claude Code integration
- SSH tunneling for remote development
- Customization options
- Troubleshooting

---

## 🔧 Manual Installation

If you prefer manual installation:

```bash
# 1. Install Zsh
sudo apt-get install zsh git curl wget

# 2. Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 3. Install Antigen
curl -L git.io/antigen > ~/antigen.zsh

# 4. Copy configuration
cp .zshrc ~/.zshrc
cp antigen.zsh ~/antigen.zsh

# 5. Start zsh
zsh
```

---

## 💡 Quick Tips

**Autosuggestions**: Type a few letters, press `→` to accept

**Syntax Highlighting**: Green = valid command, Red = invalid

**History Search**: Press `↑` to search history by substring

**Quick Deploy**: Just type `deploy`

**Status Check**: Type `orion-status` for complete overview

---

**Last Updated**: 2025-11-22
