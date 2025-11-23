# ORION Hybrid Architecture Documentation

**Version**: 2.0.0-hybrid
**Last Updated**: 2025-01-20
**System**: Dell PowerEdge R730 (CQ5QBM2)

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Design](#architecture-design)
3. [Key Features](#key-features)
4. [Hardware Specifications](#hardware-specifications)
5. [Network Architecture](#network-architecture)
6. [Virtual Machines](#virtual-machines)
7. [Deployment Process](#deployment-process)
8. [Monitoring & Management](#monitoring--management)
9. [Troubleshooting](#troubleshooting)

---

## Overview

The ORION Hybrid Architecture combines the best features from multiple deployment strategies to create a robust, flexible, and intelligent network infrastructure:

- **Proxmox VE** as the virtualization foundation (flexibility)
- **NixOS + VyOS Router** for high-performance routing (performance)
- **AI Autonomous Agent** for intelligent monitoring (intelligence)
- **macOS Support** via OSX-PROXMOX (development)
- **iDRAC Automation** for remote management (automation)

### Design Philosophy

**Best of Both Worlds**:
- ✅ Virtualization flexibility from Proxmox
- ✅ Bare-metal routing performance from VyOS
- ✅ Declarative configuration from NixOS
- ✅ AI-powered automation and monitoring
- ✅ macOS development environment
- ✅ Full remote management via iDRAC

---

## Architecture Design

```
┌─────────────────────────────────────────────────────────────────┐
│                    Dell PowerEdge R730 ORION                    │
│                      (CQ5QBM2 - 384GB RAM)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │              iDRAC Enterprise (192.168.1.2)               │ │
│  │          Redfish API - Full Remote Management             │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │            Proxmox VE 8.x Hypervisor Layer                │ │
│  │              Management: 192.168.100.10:8006              │ │
│  └───────────────────────────────────────────────────────────┘ │
│                            │                                    │
│         ┌──────────────────┼──────────────────┐                │
│         │                  │                  │                │
│  ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐          │
│  │   VM 200    │   │   VM 300    │   │   VM 100    │          │
│  │   Router    │   │  AI Agent   │   │    macOS    │          │
│  │             │   │             │   │   Sequoia   │          │
│  │ NixOS+VyOS  │   │   NixOS     │   │             │          │
│  │  8 cores    │   │  4 cores    │   │  12 cores   │          │
│  │   32GB      │   │   16GB      │   │    64GB     │          │
│  │             │   │             │   │             │          │
│  │ Services:   │   │ Services:   │   │ Purpose:    │          │
│  │ • BGP       │   │ • AI Agent  │   │ • Dev Env   │          │
│  │ • Firewall  │   │ • Prometh.  │   │ • Testing   │          │
│  │ • DHCP/DNS  │   │ • Grafana   │   │ • Build     │          │
│  │ • NAT       │   │ • Alerts    │   │             │          │
│  └─────────────┘   └─────────────┘   └─────────────┘          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
         │              │              │
    ┌────▼────┐    ┌───▼───┐     ┌───▼───┐
    │   WAN   │    │  LAN  │     │ Guest │
    │  Telus  │    │ .100  │     │ .200  │
    │ 10GbE   │    │10GbE  │     │ 10GbE │
    └─────────┘    └───────┘     └───────┘
```

---

## Key Features

### 1. **Hybrid Virtualization Model**

- **Proxmox VE 8.x**: Enterprise-grade hypervisor
  - Web-based management UI
  - Live migration support
  - Snapshot and backup capabilities
  - LXC container support

- **NixOS VMs**: Declarative, reproducible configurations
  - Atomic updates and rollbacks
  - Immutable infrastructure
  - Easy version control

### 2. **High-Performance Routing**

- **VyOS Router** (VM 200):
  - Dedicated routing VM with minimal overhead
  - BIRD2 for BGP routing
  - nftables for high-performance firewalling
  - Hardware-accelerated networking (virtio)

### 3. **AI-Powered Monitoring**

- **Autonomous Agent** (VM 300):
  - Real-time network health monitoring
  - Automatic issue detection
  - Self-healing capabilities
  - Predictive analysis

### 4. **macOS Development**

- **macOS Sequoia** (VM 100):
  - Full macOS 15 support via OSX-PROXMOX
  - 12 cores / 64GB RAM
  - Metal GPU acceleration
  - OpenCore bootloader

### 5. **Full Automation**

- **iDRAC Redfish API**:
  - Remote power management
  - Boot configuration
  - Hardware monitoring
  - Virtual media mounting

---

## Hardware Specifications

### Dell PowerEdge R730 (CQ5QBM2)

| Component | Specification |
|-----------|---------------|
| **CPUs** | 2x Intel Xeon E5-2690 v4 (14 cores, 2.6GHz) |
| **Total Cores** | 28 physical / 56 threads |
| **RAM** | 384GB DDR4-2400 (12x 32GB Samsung) |
| **Storage Controller** | PERC H730 Mini (RAID 10) |
| **Network** | 8x NICs (4x 10GbE + 4x 1GbE) |
| **Power** | Dual 750W redundant PSUs |
| **Management** | iDRAC 8 Enterprise |

### Network Interface Mapping

| Interface | MAC | Speed | Purpose |
|-----------|-----|-------|---------|
| eno1 | D0:94:66:24:96:7C | 1GbE | Proxmox Management |
| eno2 | D0:94:66:24:96:7D | 1GbE | Reserved |
| eno3 | D0:94:66:24:96:7E | 10GbE | WAN (Telus Fiber) → vmbr0 |
| eno4 | D0:94:66:24:96:80 | 10GbE | LAN (Internal) → vmbr1 |
| eno5 | - | 10GbE | macOS Network → vmbr2 |
| eno6 | - | 10GbE | Storage Network → vmbr3 |
| enp3s0f0 | - | 10GbE | Available (Slot 3) |
| enp3s0f1 | - | 10GbE | Available (Slot 3) |

---

## Network Architecture

### IP Addressing Scheme

#### WAN (Telus Fiber)
- **Interface**: vmbr0 (eno3)
- **IPv4**: DHCP from Telus
- **IPv6**: 2602:F674::/48 (prefix delegation)
- **BGP AS**: 394955
- **Peers**:
  - 206.75.1.127 (Primary - AS 6939)
  - 206.75.1.47 (Secondary - AS 6939)
  - 206.75.1.48 (Tertiary - AS 6939)

#### LAN (Internal Network)
- **Interface**: vmbr1 (eno4)
- **IPv4**: 192.168.100.0/24
- **Gateway**: 192.168.100.1 (Router VM)
- **DHCP Range**: 192.168.100.100 - 192.168.100.200
- **DNS**: 192.168.100.1 (Unbound)
- **IPv6**: 2602:F674:1000::/64

#### Guest Network
- **Interface**: vmbr2
- **IPv4**: 192.168.200.0/24
- **Gateway**: 192.168.200.1 (Router VM)
- **Isolation**: Restricted to WAN only

#### Management Network
- **IPv4**: 192.168.1.0/24
- **Proxmox**: 192.168.1.10 (eno1)
- **iDRAC**: 192.168.1.2
- **Router**: 192.168.1.1 (eth3)

### Network Bridges (Proxmox)

```
vmbr0: WAN Bridge
  - Physical: eno3 (10GbE)
  - Purpose: Router VM WAN interface
  - VLAN: Aware (for future VLANs)

vmbr1: LAN Bridge
  - Physical: eno4 (10GbE)
  - Purpose: Internal network for VMs
  - IP: 192.168.100.1/24

vmbr2: macOS Bridge
  - Physical: eno5 (10GbE)
  - Purpose: macOS VM network

vmbr3: Storage Bridge
  - Physical: eno6 (10GbE)
  - Purpose: NFS/iSCSI storage network
```

---

## Virtual Machines

### VM 200: ORION-Router

**Operating System**: NixOS 24.11 + VyOS

**Resources**:
- CPUs: 8 cores (host passthrough)
- RAM: 32GB
- Disk: 50GB
- NICs: 4x virtio (WAN, LAN, Guest, Mgmt)

**Services**:
- **BIRD2**: BGP routing (AS 394955)
- **VyOS**: Advanced routing and firewall
- **Unbound**: DNS resolver (192.168.100.1)
- **Kea DHCP**: DHCP server
- **nftables**: High-performance firewall
- **Prometheus Node Exporter**: Metrics

**Network Interfaces**:
- eth0: WAN (vmbr0) - DHCP from Telus
- eth1: LAN (vmbr1) - 192.168.100.1/24
- eth2: Guest (vmbr2) - 192.168.200.1/24
- eth3: Mgmt (vmbr1) - 192.168.1.1/24

**Configuration**: `vm-configs/router-vm/configuration.nix`

**Features**:
- Stateful firewall with nftables
- NAT for LAN and Guest networks
- DHCPv6 prefix delegation
- BGP route announcements
- DNS over TLS forwarding
- Automatic failover between BGP peers

---

### VM 300: ORION-AI-Agent

**Operating System**: NixOS 24.11

**Resources**:
- CPUs: 4 cores (host passthrough)
- RAM: 16GB
- Disk: 50GB
- NICs: 1x virtio (LAN)

**Services**:
- **Autonomous Agent**: Python-based monitoring
- **Prometheus**: Metrics collection (port 9090)
- **Grafana**: Visualization (port 3000)
- **Alert Manager**: Alert routing
- **Node Exporter**: System metrics

**Network**:
- IP: 192.168.100.20/24
- Gateway: 192.168.100.1

**Configuration**: `vm-configs/ai-agent-vm/configuration.nix`

**AI Agent Capabilities**:
- Real-time network monitoring
- BGP session health checks
- Bandwidth analysis
- Anomaly detection
- Automatic remediation:
  - Restart BGP if all sessions down
  - Alert on high CPU/memory
  - Detect routing loops
- Hourly status reports

**Monitoring Targets**:
- Router VM (192.168.100.1:9100)
- AI Agent itself (localhost:9100)
- Proxmox host (192.168.100.10:9100)

**Dashboards**: http://192.168.100.20:3000
- Default credentials: admin / orion2025 (change immediately!)

---

### VM 100: HACK-Sequoia-01

**Operating System**: macOS Sequoia 15

**Resources**:
- CPUs: 12 cores (Haswell-noTSX)
- RAM: 64GB
- Disk: 256GB
- NICs: 1x virtio (macOS network)

**Configuration**: OpenCore 1.0.4
- SMBIOS: iMacPro1,1
- SIP: Enabled
- Secure Boot: Default

**Purpose**: macOS development environment

**Setup**: Refer to existing `deploy-orion.sh` for detailed macOS VM creation

---

## Deployment Process

### Prerequisites

1. **Hardware**:
   - Dell R730 powered on and accessible
   - iDRAC configured (IP: 192.168.1.2)
   - Network cables connected

2. **Software**:
   - Python 3.x with requests library
   - Proxmox VE ISO downloaded
   - NixOS minimal ISO downloaded
   - SSH access configured

3. **Network**:
   - Management network (192.168.1.0/24) configured
   - Internet access for downloads

### Deployment Steps

#### Step 1: Run Automated Deployment

```bash
# Clone repository
git clone <repo-url>
cd luci-macOSX-PROXMOX

# Install Python dependencies
pip3 install requests

# Run hybrid deployment
python3 deploy-orion-hybrid.py
```

The deployment wizard will guide you through:
1. ✅ Prerequisites check
2. ✅ iDRAC configuration
3. ✅ Proxmox installation
4. ✅ Network bridge setup
5. ✅ Router VM creation
6. ✅ macOS VM creation
7. ✅ AI Agent VM creation
8. ✅ Monitoring setup
9. ✅ Verification

#### Step 2: Install Proxmox VE

1. Mount Proxmox ISO via iDRAC virtual media
2. Boot system from CD
3. Follow installer:
   - Hostname: `orion-pve.local`
   - IP: `192.168.100.10/24`
   - Gateway: `192.168.100.1`
   - DNS: `1.1.1.1`
4. Access web UI: https://192.168.100.10:8006

#### Step 3: Configure Network Bridges

In Proxmox web UI:
1. Navigate to: Datacenter → Node → System → Network
2. Create bridges:
   - vmbr0: eno3 (WAN)
   - vmbr1: eno4 (LAN)
   - vmbr2: eno5 (macOS)
   - vmbr3: eno6 (Storage)
3. Apply configuration and reboot

#### Step 4: Create Router VM

```bash
# Create VM
qm create 200 \
  --name ORION-Router \
  --cores 8 \
  --memory 32768 \
  --net0 virtio,bridge=vmbr0 \
  --net1 virtio,bridge=vmbr1 \
  --net2 virtio,bridge=vmbr2 \
  --net3 virtio,bridge=vmbr1 \
  --scsi0 local-lvm:50

# Download NixOS ISO
wget -O /var/lib/vz/template/iso/nixos-minimal.iso \
  https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-x86_64-linux.iso

# Mount ISO and boot
qm set 200 --ide2 local:iso/nixos-minimal.iso,media=cdrom
qm start 200

# Open console and install NixOS
# Copy configuration from: vm-configs/router-vm/configuration.nix
```

#### Step 5: Create AI Agent VM

```bash
# Create VM
qm create 300 \
  --name ORION-AI-Agent \
  --cores 4 \
  --memory 16384 \
  --net0 virtio,bridge=vmbr1 \
  --scsi0 local-lvm:50

# Mount NixOS ISO and install
# Copy configuration from: vm-configs/ai-agent-vm/configuration.nix
```

#### Step 6: Create macOS VM

Refer to `deploy-orion.sh` for detailed macOS VM setup using OSX-PROXMOX.

#### Step 7: Verification

```bash
# Check VM status
qm list

# Test router connectivity
ping -c 3 192.168.100.1

# Test BGP sessions
ssh admin@192.168.100.1 "birdc show protocols"

# Access Grafana
firefox http://192.168.100.20:3000

# Test internet from LAN
ping -c 3 8.8.8.8
```

---

## Monitoring & Management

### Prometheus Metrics

**Endpoint**: http://192.168.100.20:9090

**Targets**:
- Router: 192.168.100.1:9100
- AI Agent: 192.168.100.20:9100
- Proxmox: 192.168.100.10:9100

**Sample Queries**:
```promql
# WAN bandwidth (Mbps)
rate(node_network_receive_bytes_total{device="eth0",instance="192.168.100.1:9100"}[5m]) * 8 / 1000000

# CPU usage
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

### Grafana Dashboards

**Access**: http://192.168.100.20:3000
**Login**: admin / orion2025

**Pre-configured Dashboards**:
- ORION Network Overview
- Router Performance
- BGP Session Status
- Bandwidth Analysis
- System Resources

### AI Agent Status

```bash
# Check agent status
ssh admin@192.168.100.20 "systemctl status orion-agent"

# View logs
ssh admin@192.168.100.20 "journalctl -u orion-agent -f"

# View alerts
ssh admin@192.168.100.20 "tail -f /var/log/orion-agent.log"
```

### iDRAC Management

**Access**: https://192.168.1.2
**Login**: root / calvin

**Python CLI**:
```bash
# Power on
python3 deploy-orion-hybrid.py power-on

# Power off
python3 deploy-orion-hybrid.py power-off

# Reboot
python3 deploy-orion-hybrid.py reboot

# Status
python3 deploy-orion-hybrid.py status
```

---

## Troubleshooting

### Router VM Issues

#### BGP Sessions Not Establishing

```bash
# Check BGP status
ssh admin@192.168.100.1 "birdc show protocols all"

# Check firewall
ssh admin@192.168.100.1 "nft list ruleset | grep 179"

# Test connectivity to BGP peers
ssh admin@192.168.100.1 "ping -c 3 206.75.1.127"

# Restart BIRD
ssh admin@192.168.100.1 "sudo systemctl restart bird2"
```

#### DHCP Not Working

```bash
# Check Kea DHCP status
ssh admin@192.168.100.1 "systemctl status kea-dhcp4"

# View DHCP leases
ssh admin@192.168.100.1 "cat /var/lib/kea/dhcp4.leases"

# Restart DHCP
ssh admin@192.168.100.1 "sudo systemctl restart kea-dhcp4"
```

#### DNS Not Resolving

```bash
# Check Unbound status
ssh admin@192.168.100.1 "systemctl status unbound"

# Test DNS resolution
ssh admin@192.168.100.1 "dig @127.0.0.1 google.com"

# View Unbound logs
ssh admin@192.168.100.1 "journalctl -u unbound -f"
```

### AI Agent Issues

#### Agent Not Running

```bash
# Check service status
ssh admin@192.168.100.20 "systemctl status orion-agent"

# View recent logs
ssh admin@192.168.100.20 "journalctl -u orion-agent --since '10 minutes ago'"

# Restart agent
ssh admin@192.168.100.20 "sudo systemctl restart orion-agent"
```

#### Prometheus Not Collecting Metrics

```bash
# Check Prometheus targets
curl http://192.168.100.20:9090/api/v1/targets

# Check Prometheus config
ssh admin@192.168.100.20 "systemctl status prometheus"

# Restart Prometheus
ssh admin@192.168.100.20 "sudo systemctl restart prometheus"
```

### macOS VM Issues

Refer to OSX-PROXMOX documentation and existing troubleshooting guides.

### Network Performance Issues

```bash
# Check interface status on router
ssh admin@192.168.100.1 "ip link show"

# Monitor bandwidth
ssh admin@192.168.100.1 "iftop -i eth0"

# Check for errors
ssh admin@192.168.100.1 "ip -s link show eth0"

# Test throughput
iperf3 -s # on router
iperf3 -c 192.168.100.1 # from client
```

---

## Maintenance

### Regular Tasks

**Daily**:
- Check Grafana dashboards for anomalies
- Review AI agent alerts

**Weekly**:
- Review BGP session uptime
- Check system resource usage
- Review firewall logs

**Monthly**:
- Update NixOS VMs: `nixos-rebuild switch --upgrade`
- Update Proxmox: `apt update && apt upgrade`
- Review and rotate logs
- Test backup restore

### Backup Strategy

**Proxmox VZ Backup**:
```bash
# Backup all VMs
vzdump --all --mode snapshot --compress zstd

# Backup specific VM
vzdump 200 --mode snapshot --compress zstd
```

**NixOS Configuration Backup**:
```bash
# Configurations are in Git - commit regularly
git add vm-configs/
git commit -m "Update VM configurations"
git push
```

---

## Support & Documentation

- **Main Documentation**: `DELL_R730_ORION_PROXMOX_INTEGRATION.md`
- **Quickstart Guide**: `ORION_QUICKSTART.md`
- **Configuration**: `orion-config.json`
- **Deployment Script**: `deploy-orion-hybrid.py`
- **Legacy Script**: `deploy-orion.sh`

---

## Version History

- **2.0.0-hybrid** (2025-01-20): Hybrid architecture with NixOS router and AI agent
- **1.0.0** (2025-01-19): Initial Proxmox + pfSense deployment

---

**End of Documentation**
