# ORION Hybrid Deployment - Quick Start Guide

Get your Dell R730 ORION system up and running in minutes with full automation!

## What You'll Get

✅ Proxmox VE hypervisor with web management
✅ High-performance NixOS + VyOS router with BGP
✅ AI-powered autonomous network monitoring
✅ macOS Sequoia development environment
✅ Full remote management via iDRAC
✅ Prometheus + Grafana monitoring dashboards

## Prerequisites

Before starting, ensure you have:

- [x] Dell R730 powered on and network-accessible
- [x] iDRAC configured at 192.168.1.2
- [x] Management network (192.168.1.0/24) connected
- [x] Internet connection available
- [x] Python 3.x installed on your workstation

## 5-Minute Quick Start

### Step 1: Clone Repository

```bash
git clone https://github.com/luci-digital/luci-macOSX-PROXMOX.git
cd luci-macOSX-PROXMOX
```

### Step 2: Install Dependencies

```bash
pip3 install requests
```

### Step 3: Run Automated Deployment

```bash
python3 deploy-orion-hybrid.py
```

The deployment wizard will:
1. ✅ Check prerequisites
2. ✅ Configure iDRAC
3. ✅ Guide you through Proxmox installation
4. ✅ Setup network bridges
5. ✅ Create and configure VMs
6. ✅ Setup monitoring

### Step 4: Install Proxmox (Manual Step)

When prompted by the wizard:

1. Download Proxmox VE ISO: https://www.proxmox.com/en/downloads
2. Open iDRAC web console: https://192.168.1.2
3. Mount ISO via Virtual Media
4. Reboot system and follow installer:
   - Hostname: `orion-pve.local`
   - IP: `192.168.100.10/24`
   - Gateway: `192.168.100.1`
   - DNS: `1.1.1.1`
5. Access Proxmox: https://192.168.100.10:8006

### Step 5: Access Your System

**Proxmox Management**:
- URL: https://192.168.100.10:8006
- Login: root / (password set during install)

**Grafana Dashboards**:
- URL: http://192.168.100.20:3000
- Login: admin / orion2025 (change this!)

**iDRAC Console**:
- URL: https://192.168.1.2
- Login: root / calvin

## Architecture Overview

```
Dell R730 ORION
├─ Proxmox VE (192.168.100.10)
│  ├─ VM 200: Router (NixOS + VyOS)
│  │  └─ 192.168.100.1 (Gateway/DNS/DHCP)
│  ├─ VM 300: AI Agent
│  │  └─ 192.168.100.20 (Monitoring)
│  └─ VM 100: macOS Sequoia
│     └─ 192.168.100.X (Development)
└─ iDRAC (192.168.1.2)
```

## Network Configuration

### WAN (Internet)
- Interface: 10GbE (eno3/vmbr0)
- Provider: Telus Fiber
- IPv4: DHCP
- IPv6: 2602:F674::/48
- BGP AS: 394955

### LAN (Internal)
- Interface: 10GbE (eno4/vmbr1)
- Network: 192.168.100.0/24
- Gateway: 192.168.100.1 (Router VM)
- DHCP: .100 - .200

## Essential Commands

### iDRAC Control

```bash
# Check system status
python3 deploy-orion-hybrid.py status

# Power on
python3 deploy-orion-hybrid.py power-on

# Reboot
python3 deploy-orion-hybrid.py reboot
```

### VM Management (Proxmox)

```bash
# List VMs
qm list

# Start router
qm start 200

# Stop router (graceful)
qm shutdown 200

# Console access
qm console 200
```

### Router Management

```bash
# SSH to router
ssh admin@192.168.100.1

# Check BGP status
birdc show protocols

# Check firewall
nft list ruleset

# View DHCP leases
cat /var/lib/kea/dhcp4.leases
```

### Monitoring

```bash
# Access Grafana
firefox http://192.168.100.20:3000

# Query Prometheus
curl 'http://192.168.100.20:9090/api/v1/query?query=up'

# Check AI agent
ssh admin@192.168.100.20 "systemctl status orion-agent"
```

## VM Creation Guide

### Create Router VM (200)

```bash
# Create VM in Proxmox
qm create 200 \
  --name ORION-Router \
  --cores 8 \
  --memory 32768 \
  --net0 virtio,bridge=vmbr0 \
  --net1 virtio,bridge=vmbr1 \
  --net2 virtio,bridge=vmbr2 \
  --net3 virtio,bridge=vmbr1 \
  --scsi0 local-lvm:50 \
  --boot order=scsi0

# Download NixOS ISO (if not already done)
wget -P /var/lib/vz/template/iso/ \
  https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-x86_64-linux.iso

# Attach ISO
qm set 200 --ide2 local:iso/nixos-minimal-x86_64-linux.iso,media=cdrom

# Start VM
qm start 200

# Open console
qm console 200
```

In NixOS installer:
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

# Generate config
nixos-generate-config --root /mnt

# Download our config (from another machine)
# Upload vm-configs/router-vm/configuration.nix to /mnt/etc/nixos/

# Install
nixos-install

# Reboot
reboot
```

### Create AI Agent VM (300)

```bash
# Create VM
qm create 300 \
  --name ORION-AI-Agent \
  --cores 4 \
  --memory 16384 \
  --net0 virtio,bridge=vmbr1 \
  --scsi0 local-lvm:50 \
  --boot order=scsi0

# Attach NixOS ISO
qm set 300 --ide2 local:iso/nixos-minimal-x86_64-linux.iso,media=cdrom

# Start and install (same process as router)
qm start 300

# Use configuration from: vm-configs/ai-agent-vm/
```

### Create macOS VM (100)

Refer to the existing `deploy-orion.sh` script for detailed macOS VM setup.

## Network Bridge Setup

In Proxmox web UI (System → Network):

**vmbr0** (WAN):
- Bridge ports: eno3
- Comment: WAN - Telus Fiber

**vmbr1** (LAN):
- Bridge ports: eno4
- IPv4: 192.168.100.1/24
- Comment: LAN - Internal Network

**vmbr2** (Guest):
- Bridge ports: eno5
- Comment: Guest Network

**vmbr3** (Storage):
- Bridge ports: eno6
- Comment: Storage Network

Apply configuration and reboot Proxmox if needed.

## Verification Checklist

After deployment, verify everything works:

```bash
# ✓ iDRAC accessible
curl -k https://192.168.1.2

# ✓ Proxmox web UI accessible
curl -k https://192.168.100.10:8006

# ✓ Router responding
ping -c 3 192.168.100.1

# ✓ DNS working
dig @192.168.100.1 google.com

# ✓ BGP sessions up
ssh admin@192.168.100.1 "birdc show protocols" | grep Established

# ✓ AI agent running
ssh admin@192.168.100.20 "systemctl is-active orion-agent"

# ✓ Prometheus collecting metrics
curl http://192.168.100.20:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health == "up")'

# ✓ Grafana accessible
curl http://192.168.100.20:3000/api/health

# ✓ Internet connectivity
ping -c 3 8.8.8.8
```

## Troubleshooting

### Router Not Accessible

```bash
# Check VM is running
qm status 200

# Check console
qm console 200

# Verify network config in Proxmox
cat /etc/network/interfaces
```

### BGP Sessions Down

```bash
# SSH to router
ssh admin@192.168.100.1

# Check BIRD status
birdc show protocols all

# Check WAN interface has IP
ip addr show eth0

# Test connectivity to BGP peers
ping -c 3 206.75.1.127

# Restart BIRD
sudo systemctl restart bird2
```

### No Internet from LAN

```bash
# Check NAT is configured
ssh admin@192.168.100.1 "nft list table ip nat"

# Check routing
ssh admin@192.168.100.1 "ip route show"

# Check DNS
dig @192.168.100.1 google.com

# Test from Proxmox host
ping -c 3 8.8.8.8
```

### Monitoring Not Working

```bash
# Check Prometheus targets
curl http://192.168.100.20:9090/api/v1/targets | jq

# Check if router exporter is running
ssh admin@192.168.100.1 "systemctl status prometheus-node-exporter"

# Check AI agent logs
ssh admin@192.168.100.20 "journalctl -u orion-agent -n 50"

# Restart services
ssh admin@192.168.100.20 "sudo systemctl restart prometheus grafana"
```

## Next Steps

Once your system is running:

1. **Secure Your System**:
   - Change default passwords
   - Configure SSH keys
   - Review firewall rules

2. **Customize Configuration**:
   - Edit `vm-configs/router-vm/configuration.nix` for router changes
   - Edit `vm-configs/ai-agent-vm/configuration.nix` for monitoring changes
   - Rebuild with: `nixos-rebuild switch`

3. **Add More VMs**:
   - Create VMs in Proxmox web UI
   - Attach to vmbr1 for LAN access
   - Configure DHCP or static IPs

4. **Setup Backups**:
   - Configure Proxmox backup schedule
   - Export VM configurations to Git

5. **Explore Monitoring**:
   - Create custom Grafana dashboards
   - Setup alert notifications
   - Configure AI agent behaviors

## Resource Allocation

| Component | Cores | RAM | Purpose |
|-----------|-------|-----|---------|
| Proxmox Host | 4 | 16GB | Hypervisor |
| Router VM | 8 | 32GB | Routing/BGP/Firewall |
| AI Agent VM | 4 | 16GB | Monitoring |
| macOS VM | 12 | 64GB | Development |
| Available | 28 | 256GB | Future VMs/containers |
| **Total** | **56** | **384GB** | |

## Useful Links

- **Proxmox Documentation**: https://pve.proxmox.com/pve-docs/
- **NixOS Manual**: https://nixos.org/manual/nixos/stable/
- **VyOS Documentation**: https://docs.vyos.io/
- **BIRD Routing**: https://bird.network.cz/
- **Prometheus**: https://prometheus.io/docs/
- **Grafana**: https://grafana.com/docs/

## Support

For detailed documentation:
- Full architecture: `ORION_HYBRID_ARCHITECTURE.md`
- VM configurations: `vm-configs/README.md`
- Original Proxmox setup: `DELL_R730_ORION_PROXMOX_INTEGRATION.md`

For issues:
- Check system logs: `journalctl -xe`
- Review VM console output
- Consult troubleshooting sections

---

**Ready to deploy? Run `python3 deploy-orion-hybrid.py` to get started!**

Last Updated: 2025-01-20
