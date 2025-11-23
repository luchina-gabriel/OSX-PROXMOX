# ORION VM Configurations

This directory contains NixOS configuration files for ORION virtual machines.

## Directory Structure

```
vm-configs/
├── router-vm/
│   └── configuration.nix    # NixOS + VyOS router configuration
└── ai-agent-vm/
    ├── configuration.nix    # AI agent system configuration
    └── autonomous_agent.py  # AI monitoring agent
```

## VM Overview

### Router VM (VM 200)

**Purpose**: High-performance network router with BGP, firewall, DHCP, and DNS

**Services**:
- BIRD2 BGP (AS 394955)
- VyOS routing
- Unbound DNS (DNS over TLS)
- Kea DHCP
- nftables firewall
- Prometheus node exporter

**Network Interfaces**:
- eth0: WAN (DHCP from Telus)
- eth1: LAN (192.168.100.1/24)
- eth2: Guest (192.168.200.1/24)
- eth3: Management (192.168.1.1/24)

**Configuration**: `router-vm/configuration.nix`

### AI Agent VM (VM 300)

**Purpose**: Autonomous network monitoring and management

**Services**:
- Autonomous monitoring agent (Python)
- Prometheus server (port 9090)
- Grafana dashboards (port 3000)
- Alert manager
- Prometheus node exporter

**Network**:
- eth0: LAN (192.168.100.20/24)

**Configuration**: `ai-agent-vm/configuration.nix`

## Installation

### 1. Install NixOS Base System

Boot VM from NixOS ISO and partition disks:

```bash
# Partition disk
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 512MiB 100%

# Format
mkfs.fat -F 32 -n boot /dev/sda1
mkfs.ext4 -L nixos /dev/sda2

# Mount
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Generate hardware config
nixos-generate-config --root /mnt
```

### 2. Copy Configuration

For **Router VM**:
```bash
# Copy configuration from this repository
scp vm-configs/router-vm/configuration.nix nixos@VM_IP:/tmp/
ssh nixos@VM_IP "sudo cp /tmp/configuration.nix /mnt/etc/nixos/"
```

For **AI Agent VM**:
```bash
# Copy both configuration and agent script
scp vm-configs/ai-agent-vm/configuration.nix nixos@VM_IP:/tmp/
scp vm-configs/ai-agent-vm/autonomous_agent.py nixos@VM_IP:/tmp/
ssh nixos@VM_IP "sudo cp /tmp/configuration.nix /mnt/etc/nixos/"
```

### 3. Install NixOS

```bash
# Run installation
nixos-install

# Set root password when prompted

# Reboot
reboot
```

### 4. Post-Installation

After first boot:

```bash
# SSH into the VM
ssh admin@<VM_IP>

# Update system (if needed)
sudo nixos-rebuild switch

# Check services
systemctl status bird2         # Router VM only
systemctl status orion-agent   # AI Agent VM only
systemctl status prometheus    # AI Agent VM only
systemctl status grafana       # AI Agent VM only
```

## Configuration Management

### Updating Configurations

Configurations are declarative - edit the `.nix` files and rebuild:

```bash
# Edit configuration
vim /etc/nixos/configuration.nix

# Test configuration (don't activate)
sudo nixos-rebuild test

# Apply configuration
sudo nixos-rebuild switch

# Rollback if needed
sudo nixos-rebuild --rollback
```

### Version Control

Keep configurations in Git:

```bash
# After making changes
cd /path/to/luci-macOSX-PROXMOX
git add vm-configs/
git commit -m "Update VM configurations"
git push
```

## Customization

### Router VM

**Add BGP peer**:
Edit `router-vm/configuration.nix`:
```nix
protocol bgp new_peer {
  local as 394955;
  neighbor <IP> as <ASN>;

  ipv4 {
    import all;
    export where source = RTS_STATIC;
  };
}
```

**Add firewall rule**:
```nix
# In nftables.ruleset
iif eth1 tcp dport <PORT> accept
```

**Change network ranges**:
```nix
networking.interfaces.eth1.ipv4.addresses = [{
  address = "192.168.X.1";
  prefixLength = 24;
}];
```

### AI Agent VM

**Adjust monitoring interval**:
Edit `ai-agent-vm/autonomous_agent.py`:
```python
self.check_interval = 60  # seconds
```

**Add monitoring targets**:
Edit `ai-agent-vm/configuration.nix`:
```nix
services.prometheus.scrapeConfigs = [
  {
    job_name = "new-target";
    static_configs = [{
      targets = [ "IP:PORT" ];
    }];
  }
];
```

**Change Grafana password**:
```nix
services.grafana.settings.security.admin_password = "NEW_PASSWORD";
```

## Troubleshooting

### Router VM

**BGP not working**:
```bash
# Check BIRD status
birdc show protocols

# Check BIRD logs
journalctl -u bird2 -f

# Reload BIRD config
birdc configure
```

**Firewall blocking traffic**:
```bash
# View rules
nft list ruleset

# Check counters
nft list ruleset -a

# Temporarily disable (for testing only!)
systemctl stop nftables
```

### AI Agent VM

**Agent not collecting metrics**:
```bash
# Check agent logs
journalctl -u orion-agent -f

# Check if Prometheus is scraping
curl http://localhost:9090/api/v1/targets

# Manually test router connectivity
curl http://192.168.100.1:9100/metrics
```

**Grafana not accessible**:
```bash
# Check Grafana status
systemctl status grafana

# Check firewall
nft list ruleset | grep 3000

# View Grafana logs
journalctl -u grafana -f
```

## Network Diagram

```
Internet (Telus)
      │
      │ WAN (eth0) - DHCP
      │
┌─────▼─────────────────────┐
│   Router VM (200)         │
│  192.168.100.1            │
│                           │
│  • BGP (AS 394955)        │
│  • Firewall (nftables)    │
│  • DHCP Server            │
│  • DNS (Unbound)          │
└─────┬─────────────────────┘
      │ LAN (eth1)
      │ 192.168.100.0/24
      │
      ├──────────────┬─────────────┬──────────────┐
      │              │             │              │
┌─────▼─────┐  ┌────▼─────┐ ┌────▼─────┐  ┌────▼─────┐
│ AI Agent  │  │  macOS   │ │ Proxmox  │  │  Clients │
│   (300)   │  │  (100)   │ │   Host   │  │   DHCP   │
│  .100.20  │  │  .100.X  │ │ .100.10  │  │ .100.100+│
└───────────┘  └──────────┘ └──────────┘  └──────────┘
```

## Security Notes

1. **SSH Keys**: Add your public keys to configuration:
   ```nix
   users.users.admin.openssh.authorizedKeys.keys = [
     "ssh-rsa AAAAB3... your-key-here"
   ];
   ```

2. **Firewall**: Default deny policy - only explicitly allowed traffic passes

3. **Updates**: Automatic weekly updates enabled:
   ```nix
   system.autoUpgrade.enable = true;
   ```

4. **Change Default Passwords**:
   - Grafana: admin / orion2025 → Change immediately!
   - SSH: Disable password auth, use keys only

## Support

For issues or questions:
1. Check the main documentation: `../ORION_HYBRID_ARCHITECTURE.md`
2. Review NixOS manual: https://nixos.org/manual/nixos/stable/
3. Check service logs: `journalctl -u <service> -f`

---

**Last Updated**: 2025-01-20
