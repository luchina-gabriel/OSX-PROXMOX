# ORION Quick Start Guide

## Dell R730 CQ5QBM2 - Proxmox with macOS and Routing

This guide provides a quick start for deploying the ORION platform on Dell PowerEdge R730.

---

## What is ORION?

**ORION** is a unified platform that combines:

1. **High-Performance Router** - pfSense with BGP, replacing ISP modem
2. **macOS Virtualization** - Run macOS Sequoia and other versions
3. **Development Platform** - Host Linux/Windows VMs and containers

All running on **Proxmox VE** hypervisor on Dell PowerEdge R730 hardware.

---

## Hardware Requirements

- **Server:** Dell PowerEdge R730 (Service Tag: CQ5QBM2)
- **CPU:** 2x Intel Xeon E5-2690 v4 (56 threads total)
- **RAM:** 384GB DDR4-2400
- **NICs:** 8x Network Interfaces (4x10GbE + 2x1GbE + 2x10GbE)
- **Storage:** PERC H730 RAID Controller

---

## Quick Installation (5 Steps)

### Step 1: Install Proxmox VE

1. Download Proxmox VE ISO from https://www.proxmox.com/en/downloads
2. Create bootable USB drive
3. Boot Dell R730 from USB (via iDRAC Virtual Media)
4. Install Proxmox VE with default settings
5. Configure management IP: 192.168.100.10/24

**Time:** ~15 minutes

### Step 2: Run Automated Deployment

```bash
# SSH to Proxmox server
ssh root@192.168.100.10

# Download deployment script
git clone https://github.com/luci-digital/luci-macOSX-PROXMOX.git /root/orion-deploy
cd /root/orion-deploy

# Run full deployment
./deploy-orion.sh --full-deploy
```

**Time:** ~30-60 minutes (downloads ISOs, creates VMs)

### Step 3: Configure Router VM (pfSense)

1. Access Proxmox Web UI: https://192.168.100.10:8006
2. Start VM 200 (ORION-Router)
3. Open Console and install pfSense
4. Configure WAN interface (Telus connection)
5. Configure BGP peering (FRR package)

**Time:** ~20 minutes

### Step 4: Install macOS

1. Start VM 100 (HACK-Sequoia-01)
2. Open VNC Console
3. Boot from "macOS Installer"
4. Format disk with Disk Utility (APFS)
5. Install macOS Sequoia
6. Complete setup wizard

**Time:** ~45-60 minutes

### Step 5: Install Monitoring Services

```bash
# On Proxmox host
cd /root/orion-deploy/scripts
./install-orion-services.sh

# Start monitoring
systemctl start orion-gateway-monitor
systemctl start orion-bgp-monitor
systemctl start orion-vm-watchdog
```

**Time:** ~5 minutes

---

## Architecture Overview

```
Proxmox VE (Hypervisor)
├── VM 200: ORION-Router (pfSense)
│   ├── WAN: vmbr0 (eno3) → Telus Fiber
│   ├── LAN: vmbr1 (eno4) → Internal Network
│   └── BGP: AS 394955 → Telus AS 6939
│
├── VM 100: HACK-Sequoia-01 (macOS)
│   ├── CPU: 12 cores
│   ├── RAM: 64GB
│   └── Network: vmbr2 (dedicated 10GbE)
│
└── Monitoring Services
    ├── Gateway Monitor (ping Telus gateways)
    ├── BGP Monitor (check BGP sessions)
    └── VM Watchdog (auto-restart critical VMs)
```

---

## Network Configuration

| Bridge | Interface | Purpose | IP Address |
|--------|-----------|---------|------------|
| vmbr0 | eno3 | WAN (Router VM) | - |
| vmbr1 | eno4 | LAN (Internal) | 192.168.100.1/24 |
| vmbr2 | eno5 | macOS VMs | - |
| vmbr3 | eno6 | Storage | - |

---

## Resource Allocation

| Component | CPU Cores | RAM | Purpose |
|-----------|-----------|-----|---------|
| Proxmox Host | 4 | 16GB | Hypervisor |
| Router VM | 8 | 32GB | Routing, BGP |
| macOS VM | 12 | 64GB | Development |
| Available | 32 | 272GB | Other VMs |

---

## Access Points

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| Proxmox Web UI | https://192.168.100.10:8006 | root / (set during install) |
| pfSense Web UI | https://192.168.100.1 | admin / pfsense |
| iDRAC | https://192.168.1.2 | (Dell default) |
| Grafana | http://192.168.100.10:3000 | admin / admin |

---

## Common Tasks

### Start/Stop VMs

```bash
# Start router
qm start 200

# Stop router
qm stop 200

# Check status
qm status 200
```

### View Monitoring Logs

```bash
# Gateway monitor
journalctl -u orion-gateway-monitor -f

# BGP monitor
journalctl -u orion-bgp-monitor -f

# VM watchdog
journalctl -u orion-vm-watchdog -f

# All ORION logs
tail -f /var/log/orion/*.log
```

### Backup VMs

```bash
# Backup router VM
vzdump 200 --mode snapshot --compress zstd --storage local

# Backup macOS VM
vzdump 100 --mode snapshot --compress zstd --storage local
```

### Update Proxmox

```bash
apt-get update
apt-get dist-upgrade
pveam update
```

---

## Troubleshooting

### macOS Won't Boot

**Problem:** Stuck at Apple logo or blank screen

**Solution:**

```bash
# Check TSC (should show "tsc")
cat /sys/devices/system/clocksource/clocksource0/current_clocksource

# Force TSC if needed
nano /etc/default/grub
# Add: clocksource=tsc tsc=reliable
update-grub
reboot
```

### BGP Sessions Not Establishing

**Problem:** pfSense shows BGP neighbors in "Active" state

**Solution:**

1. Verify WAN interface has correct IP
2. Check routing to BGP peers: `ping -S 206.75.1.126 206.75.1.127`
3. Verify FRR is running: `Status > Services`
4. Check FRR logs: `/var/log/frr/frr.log`

### Poor Network Performance

**Problem:** Low throughput or high latency

**Solution:**

```bash
# Enable virtio offloading
qm set 100 --net0 virtio,bridge=vmbr2,firewall=0

# Tune NIC ring buffers
ethtool -G eno5 rx 4096 tx 4096

# Enable performance tuning service
systemctl restart orion-performance-tuning
```

---

## Documentation

- **Complete Guide:** [DELL_R730_ORION_PROXMOX_INTEGRATION.md](DELL_R730_ORION_PROXMOX_INTEGRATION.md)
- **Proxmox Docs:** https://pve.proxmox.com/pve-docs/
- **OSX-PROXMOX:** https://github.com/luchina-gabriel/OSX-PROXMOX
- **pfSense Docs:** https://docs.netgate.com/pfsense/

---

## Support

- **Issues:** https://github.com/luci-digital/Dell_R730_CQ5QBM2_ORION/issues
- **Proxmox Forum:** https://forum.proxmox.com/
- **Universo Hackintosh:** https://discord.universohackintosh.com.br

---

## Success Checklist

- [ ] Proxmox VE installed and accessible
- [ ] Network bridges configured (vmbr0-vmbr3)
- [ ] Router VM created and pfSense installed
- [ ] BGP sessions established with Telus gateways
- [ ] macOS VM created and Sequoia installed
- [ ] Monitoring services running
- [ ] Internet connectivity verified from LAN
- [ ] Backup strategy configured

---

**Version:** 1.0.0
**Last Updated:** 2025-01-19
**Deployment Time:** ~2-3 hours (full setup)

Happy virtualizing! 🚀
