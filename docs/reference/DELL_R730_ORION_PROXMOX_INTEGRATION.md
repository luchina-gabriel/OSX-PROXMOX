# Dell R730 CQ5QBM2 ORION - Proxmox with macOS Integration Guide

## 🎯 Overview

This guide integrates the **OSX-PROXMOX** solution with the Dell PowerEdge R730 (Service Tag: CQ5QBM2) **ORION** deployment, creating a unified platform that provides:

1. **High-Performance Routing** - Replace Telus NH20T modem with enterprise routing capabilities
2. **macOS Virtualization** - Run macOS VMs (High Sierra through Sequoia) on AMD/Intel hardware
3. **Multi-Service Platform** - Host additional VMs and containers for development, testing, and production workloads

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Dell PowerEdge R730 - CQ5QBM2                        │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                      Proxmox VE 8.4.x                             │ │
│  │                   (Hypervisor - Bare Metal)                       │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────┐ │
│  │  Router VM/LXC   │  │  macOS VM        │  │  Development VMs     │ │
│  │                  │  │  (Sequoia 15)    │  │  (Linux/Windows)     │ │
│  │  - pfSense/VyOS  │  │                  │  │                      │ │
│  │  - BGP Routing   │  │  OpenCore 1.0.4  │  │  - Docker Host       │ │
│  │  - Firewall      │  │  GPU Passthrough │  │  - K8s Cluster       │ │
│  │  - VPN Gateway   │  │  USB Passthrough │  │  - CI/CD Runners     │ │
│  └──────────────────┘  └──────────────────┘  └──────────────────────┘ │
│         │                      │                       │               │
│  ┌──────┴──────────────────────┴───────────────────────┴────────────┐ │
│  │              Virtual Network Bridges (vmbr0-vmbr3)               │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│         │                      │                       │               │
│  ┌──────┴──────────────────────┴───────────────────────┴────────────┐ │
│  │            Physical NICs (4x10GbE + 2x1GbE + 2x10GbE)            │ │
│  │  eth0: WAN (D0:94:66:24:96:7E) - Telus Fiber                    │ │
│  │  eth1: LAN (D0:94:66:24:96:80) - Internal Network               │ │
│  │  eth2-7: Additional NICs for VMs and Passthrough                │ │
│  └──────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 💻 Hardware Specifications

### Dell PowerEdge R730 - CQ5QBM2

| Component | Specification | Allocation Strategy |
|-----------|--------------|---------------------|
| **CPUs** | 2x Intel Xeon E5-2690 v4 (28 cores, 56 threads) | Host: 4 cores, Router: 8 cores, macOS: 12 cores, Dev: 32 cores |
| **RAM** | 384GB DDR4-2400 (12x 32GB Samsung) | Host: 16GB, Router: 32GB, macOS: 64GB, Dev: 272GB |
| **NICs** | 4x 10GbE + 2x 1GbE (Integrated) | WAN, LAN, Management, Storage |
| **NICs** | 2x 10GbE (Slot 3) | Passthrough to Router VM |
| **Storage** | PERC H730 Mini RAID Controller | ZFS/LVM for VM storage |
| **iDRAC** | iDRAC 8 Enterprise | Out-of-band management |

### Resource Allocation Table

```
┌──────────────────┬───────────┬─────────────┬──────────────┬─────────────┐
│ VM/Service       │ CPU Cores │ RAM (GB)    │ Storage (GB) │ Network     │
├──────────────────┼───────────┼─────────────┼──────────────┼─────────────┤
│ Proxmox Host     │ 4         │ 16          │ 100 (OS)     │ All NICs    │
│ Router VM        │ 8         │ 32          │ 50           │ 4x 10GbE    │
│ macOS Sequoia    │ 12        │ 64          │ 256          │ 1x 10GbE    │
│ macOS Sonoma     │ 8         │ 32          │ 128          │ virtio      │
│ Development VMs  │ 24        │ 240         │ 1000+        │ virtio      │
│ RESERVED         │ -         │ -           │ -            │ -           │
└──────────────────┴───────────┴─────────────┴──────────────┴─────────────┘
Total: 56 cores, 384GB RAM
```

---

## 📋 Prerequisites

### Required Components

- ✅ Dell PowerEdge R730 with iDRAC access
- ✅ Proxmox VE 8.4.x installation media (ISO)
- ✅ Active internet connection during installation
- ✅ Telus Fiber gateway credentials (for BGP configuration)
- ✅ USB drive (8GB+) for Proxmox installer

### Network Requirements

- ✅ Static IP for Proxmox management (e.g., 192.168.100.10/24)
- ✅ Gateway IP for internet access during setup
- ✅ DNS servers (e.g., 1.1.1.1, 8.8.8.8)
- ✅ Telus BGP peer IPs: 206.75.1.127, 206.75.1.47, 206.75.1.48
- ✅ IPv6 prefix: 2602:F674::/48

---

## 🚀 Installation Process

### Phase 1: Install Proxmox VE Base System

#### Step 1.1: Prepare Installation Media

```bash
# On your workstation, download Proxmox VE ISO
wget https://www.proxmox.com/en/downloads/proxmox-virtual-environment/iso/proxmox-ve-8-4-iso-installer

# Create bootable USB (Linux/macOS)
sudo dd if=proxmox-ve_8.4.iso of=/dev/sdX bs=1M status=progress
sync

# Or use Rufus on Windows
```

#### Step 1.2: Boot and Install Proxmox

1. **Access iDRAC** - https://192.168.1.2 (default Dell IP)
2. **Launch Virtual Console** - Console/Media > Launch Virtual Console
3. **Mount ISO** - Virtual Media > Connect CD/DVD > Select Proxmox ISO
4. **Boot from Virtual CD** - Next Boot > Virtual CD/DVD/ISO

**Installation Wizard:**

```
┌─────────────────────────────────────────────────┐
│ Proxmox VE Installer                            │
├─────────────────────────────────────────────────┤
│ Welcome - Select "Install Proxmox VE (Graphical)│
│                                                  │
│ EULA - Accept License Agreement                 │
│                                                  │
│ Target Disk:                                     │
│   ▸ /dev/sda (PERC H730 RAID Volume)            │
│   Filesystem: ext4 (or ZFS RAID1 for production)│
│   Disk Setup: Use entire disk                   │
│                                                  │
│ Location and Timezone:                           │
│   Country: Canada (or your location)             │
│   Timezone: America/Vancouver                    │
│   Keyboard: US                                   │
│                                                  │
│ Administrator Password:                          │
│   Password: **************** (secure password)  │
│   Confirm:  ****************                     │
│   Email: admin@orion.local                       │
│                                                  │
│ Network Configuration:                           │
│   Management Interface: eno1 (1GbE)              │
│   Hostname: orion-pve.local                      │
│   IP Address: 192.168.100.10                     │
│   Netmask: 255.255.255.0                         │
│   Gateway: 192.168.100.1                         │
│   DNS: 1.1.1.1                                   │
│                                                  │
│ Summary - Verify settings and click "Install"   │
└─────────────────────────────────────────────────┘
```

5. **Wait for Installation** (~10-15 minutes)
6. **Reboot** when prompted
7. **Access Web UI** - https://192.168.100.10:8006

#### Step 1.3: Post-Installation Configuration

**Login to Proxmox Shell** (via web UI: Datacenter > orion-pve > Shell)

```bash
# Disable Enterprise Repository (requires subscription)
rm -f /etc/apt/sources.list.d/pve-enterprise.list
rm -f /etc/apt/sources.list.d/pve-enterprise.sources

# Add No-Subscription Repository
cat <<EOF > /etc/apt/sources.list.d/pve-no-subscription.list
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF

# Update system
apt-get update
apt-get dist-upgrade -y

# Install essential tools
apt-get install -y \
    git curl wget vim tmux htop \
    net-tools bridge-utils vlan \
    ethtool smartmontools \
    iperf3 tcpdump nmap \
    jq bc
```

---

### Phase 2: Configure Network Bridges for Routing and VMs

#### Step 2.1: Identify Network Interfaces

```bash
# List all network interfaces
ip link show

# Expected output:
# 1: lo: <LOOPBACK,UP,LOWER_UP>
# 2: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> (1GbE - Management)
# 3: eno2: <BROADCAST,MULTICAST> (1GbE)
# 4: eno3: <BROADCAST,MULTICAST> (10GbE - WAN)
# 5: eno4: <BROADCAST,MULTICAST> (10GbE - LAN)
# 6: eno5: <BROADCAST,MULTICAST> (10GbE)
# 7: eno6: <BROADCAST,MULTICAST> (10GbE)
# 8: enp3s0f0: <BROADCAST,MULTICAST> (10GbE Slot 3)
# 9: enp3s0f1: <BROADCAST,MULTICAST> (10GbE Slot 3)

# Verify MAC addresses match documentation
ip link show | grep -A1 "eno3\|eno4"
# eno3: D0:94:66:24:96:7E (WAN)
# eno4: D0:94:66:24:96:80 (LAN)
```

#### Step 2.2: Configure Network Bridges

**Edit `/etc/network/interfaces`:**

```bash
# Backup original configuration
cp /etc/network/interfaces /etc/network/interfaces.backup

# Edit configuration
nano /etc/network/interfaces
```

**Configuration:**

```bash
# /etc/network/interfaces

auto lo
iface lo inet loopback

# Management Interface (Proxmox Web UI)
auto eno1
iface eno1 inet static
    address 192.168.100.10/24
    gateway 192.168.100.1
    dns-nameservers 1.1.1.1 8.8.8.8

# WAN Bridge (for Router VM) - eno3 (D0:94:66:24:96:7E)
auto vmbr0
iface vmbr0 inet manual
    bridge-ports eno3
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
    #WAN interface for Router VM

# LAN Bridge (Internal Network) - eno4 (D0:94:66:24:96:80)
auto vmbr1
iface vmbr1 inet static
    address 192.168.100.1/24
    bridge-ports eno4
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
    #LAN interface for all VMs

# macOS VM Bridge (Dedicated 10GbE) - eno5
auto vmbr2
iface vmbr2 inet manual
    bridge-ports eno5
    bridge-stp off
    bridge-fd 0
    #Dedicated network for macOS VMs (can enable passthrough)

# Storage/Backup Bridge - eno6
auto vmbr3
iface vmbr3 inet manual
    bridge-ports eno6
    bridge-stp off
    bridge-fd 0
    #Storage network (NFS, iSCSI, etc.)
```

**Apply Network Configuration:**

```bash
# Test configuration syntax
ifup --no-act vmbr0
ifup --no-act vmbr1
ifup --no-act vmbr2
ifup --no-act vmbr3

# Apply configuration (WARNING: May disconnect SSH)
systemctl restart networking

# Or reboot to be safe
reboot
```

#### Step 2.3: Verify Network Configuration

```bash
# Check bridges
ip addr show

# Verify bridge members
brctl show

# Expected output:
# bridge name     bridge id               STP enabled     interfaces
# vmbr0          8000.d094662496fe       no              eno3
# vmbr1          8000.d09466249680       no              eno4
# vmbr2          8000.xxxxxxxxxxxx       no              eno5
# vmbr3          8000.xxxxxxxxxxxx       no              eno6
```

---

### Phase 3: Install OSX-PROXMOX for macOS Support

#### Step 3.1: Run Automated Installer

```bash
# SSH to Proxmox host
ssh root@192.168.100.10

# Run the OSX-PROXMOX installer
/bin/bash -c "$(curl -fsSL https://install.osx-proxmox.com)"
```

**Expected Output:**

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│        Welcome to OSX-PROXMOX Installer v2025.07.23        │
│                                                             │
│  This script will configure your Proxmox VE server to      │
│  support macOS virtual machines with OpenCore 1.0.4        │
│                                                             │
│  Supported macOS Versions:                                 │
│    • High Sierra (10.13) through Sequoia (15)              │
│                                                             │
│  Features:                                                  │
│    ✓ Automated OpenCore ISO generation                     │
│    ✓ GPU passthrough support                               │
│    ✓ USB passthrough support                               │
│    ✓ VFIO configuration                                     │
│    ✓ SIP enabled with Apple-signed DMGs only               │
│                                                             │
└─────────────────────────────────────────────────────────────┘

[INFO] Cleaning up existing files...
[INFO] Preparing to install OSX-PROXMOX...
[INFO] Updating package lists...
[INFO] Installing git...
[INFO] Cloning OSX-PROXMOX repository...
[INFO] Running setup script...

┌─────────────────────────────────────────────────────────────┐
│              OSX-PROXMOX Setup - Main Menu                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Create macOS Virtual Machine                           │
│  2. Configure Network Bridges                              │
│  3. Setup GPU Passthrough (IOMMU)                          │
│  4. Generate SMBIOS Serial Numbers                         │
│  5. Download macOS Recovery Images                         │
│  6. Advanced Configuration                                 │
│  7. Exit                                                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Select option: 1
```

#### Step 3.2: Create First macOS VM

**Follow the interactive wizard:**

```
┌─────────────────────────────────────────────────────────────┐
│         Create macOS Virtual Machine - Step 1/7            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Select macOS Version:                                      │
│                                                             │
│  1. High Sierra (10.13)   - Legacy hardware support        │
│  2. Mojave (10.14)        - Last 32-bit app support        │
│  3. Catalina (10.15)      - 64-bit only                    │
│  4. Big Sur (11)          - ARM transition                 │
│  5. Monterey (12)         - Universal Control              │
│  6. Ventura (13)          - Stage Manager                  │
│  7. Sonoma (14)           - Widgets on desktop             │
│  8. Sequoia (15)          - Latest (2025) ⭐ RECOMMENDED   │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Selection: 8

┌─────────────────────────────────────────────────────────────┐
│         Create macOS Virtual Machine - Step 2/7            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  VM Configuration:                                          │
│                                                             │
│  VM ID: 100 (auto-assigned)                                │
│  VM Name: HACK-Sequoia-01                                  │
│  CPU Cores: 12 (recommended: 8-16 for Sequoia)             │
│  RAM: 64GB (recommended: 32GB+ for Sequoia)                │
│  Disk Size: 256GB (minimum: 128GB)                         │
│  Storage: local-lvm                                         │
│  Network Bridge: vmbr2 (macOS dedicated)                   │
│                                                             │
│  Advanced Options:                                          │
│  [ ] Enable GPU Passthrough (requires IOMMU)               │
│  [✓] Enable USB Passthrough (keyboard/mouse)               │
│  [✓] CPU Type: Haswell-noTSX (macOS compatible)            │
│  [✓] Machine Type: q35                                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Proceed? (y/n): y

[INFO] Downloading macOS Sequoia Recovery Image...
[INFO] Creating OpenCore bootloader ISO...
[INFO] Generating SMBIOS serial numbers (iMacPro1,1)...
[INFO] Creating VM 100 (HACK-Sequoia-01)...
[INFO] Configuring CPU (12 cores, Haswell-noTSX)...
[INFO] Configuring RAM (64GB)...
[INFO] Creating disk (256GB on local-lvm)...
[INFO] Attaching OpenCore ISO...
[INFO] Attaching macOS Recovery ISO...
[INFO] Configuring network (vmbr2, virtio)...
[INFO] Applying macOS-specific QEMU arguments...
[INFO] VM created successfully!

┌─────────────────────────────────────────────────────────────┐
│                  ✅ VM Creation Complete                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  VM ID: 100                                                 │
│  VM Name: HACK-Sequoia-01                                  │
│  Status: Stopped                                            │
│                                                             │
│  Next Steps:                                                │
│  1. Start the VM from Proxmox web UI                       │
│  2. Open VNC console (VM > Console)                        │
│  3. Boot from "macOS Installer"                            │
│  4. Use Disk Utility to format the main disk (APFS)        │
│  5. Install macOS to the formatted disk                    │
│  6. After installation, configure macOS settings           │
│  7. Disable Gatekeeper: sudo spctl --master-disable        │
│                                                             │
│  Web Console: https://192.168.100.10:8006                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

### Phase 4: Create Router VM for Network Services

Now we'll create a dedicated router VM (pfSense or VyOS) to handle the routing, BGP, and firewall functions originally planned for the ORION deployment.

#### Step 4.1: Download pfSense ISO

```bash
# Download pfSense CE (latest stable)
cd /var/lib/vz/template/iso/
wget https://sgpfiles.netgate.com/mirror/downloads/pfSense-CE-2.7.2-RELEASE-amd64.iso.gz
gunzip pfSense-CE-2.7.2-RELEASE-amd64.iso.gz

# Or VyOS (open-source router)
wget https://github.com/vyos/vyos-rolling/releases/download/1.5-rolling-202501/vyos-1.5-rolling-202501-amd64.iso
```

#### Step 4.2: Create Router VM via CLI

```bash
# Create VM
qm create 200 \
  --name ORION-Router \
  --memory 32768 \
  --cores 8 \
  --cpu host \
  --sockets 1 \
  --numa 1 \
  --ostype other \
  --boot order='ide2;scsi0' \
  --ide2 local:iso/pfSense-CE-2.7.2-RELEASE-amd64.iso,media=cdrom \
  --scsi0 local-lvm:50,cache=writeback,discard=on,ssd=1 \
  --scsihw virtio-scsi-pci \
  --net0 virtio,bridge=vmbr0,firewall=0 \
  --net1 virtio,bridge=vmbr1,firewall=0 \
  --net2 virtio,bridge=vmbr2,firewall=0 \
  --net3 virtio,bridge=vmbr3,firewall=0 \
  --agent 1 \
  --onboot 1 \
  --startup order=1,up=30

# Alternative: PCI Passthrough for 10GbE NICs (better performance)
# First, identify the NIC PCI addresses
lspci | grep -i ethernet

# Example output:
# 03:00.0 Ethernet controller: Intel Corporation 82599ES 10-Gigabit
# 03:00.1 Ethernet controller: Intel Corporation 82599ES 10-Gigabit

# Enable IOMMU and passthrough
nano /etc/default/grub
# Add: intel_iommu=on iommu=pt (or amd_iommu=on for AMD)
# GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"

update-grub
reboot

# After reboot, configure VFIO
echo "vfio" >> /etc/modules
echo "vfio_iommu_type1" >> /etc/modules
echo "vfio_pci" >> /etc/modules
echo "vfio_virqfd" >> /etc/modules

update-initramfs -u -k all
reboot

# Attach PCI devices to VM
qm set 200 --hostpci0 03:00.0
qm set 200 --hostpci1 03:00.1
```

#### Step 4.3: Install and Configure pfSense

1. **Start VM 200** - Proxmox UI > VM 200 > Start
2. **Open Console** - VM 200 > Console
3. **Install pfSense** - Follow installation wizard
   - Accept EULA
   - Select "Install pfSense"
   - Partition: Auto (UFS)
   - Reboot after installation

4. **Configure Interfaces**

```
┌───────────────────────────────────────────┐
│    pfSense Initial Configuration          │
├───────────────────────────────────────────┤
│                                           │
│  Should VLANs be set up now? n            │
│                                           │
│  Enter WAN interface name: vtnet0         │
│  Enter LAN interface name: vtnet1         │
│  Enter OPT1 interface name: vtnet2        │
│  Enter OPT2 interface name: vtnet3        │
│                                           │
│  Proceed? y                               │
│                                           │
└───────────────────────────────────────────┘

┌───────────────────────────────────────────┐
│    Configure WAN Interface                │
├───────────────────────────────────────────┤
│  Configure IPv4 via DHCP? n               │
│  IPv4 Address: 206.75.1.126               │
│  Subnet: 24                                │
│  Upstream Gateway: 206.75.1.1             │
│                                           │
│  Configure IPv6 via DHCP6? n              │
│  IPv6 Address: 2602:F674::1               │
│  Prefix: 48                                │
│                                           │
└───────────────────────────────────────────┘

┌───────────────────────────────────────────┐
│    Configure LAN Interface                │
├───────────────────────────────────────────┤
│  IPv4 Address: 192.168.100.1              │
│  Subnet: 24                                │
│  IPv6 Address: 2602:F674:1000::1          │
│  Prefix: 64                                │
│                                           │
│  Enable DHCP server? y                    │
│  Start: 192.168.100.100                   │
│  End: 192.168.100.254                     │
│                                           │
└───────────────────────────────────────────┘
```

5. **Access Web UI** - https://192.168.100.1 (admin/pfsense)

6. **Configure BGP** (via FRR package)

```bash
# In pfSense Web UI:
# System > Package Manager > Available Packages
# Search for "FRR" and install

# Services > FRR > Global Settings
# Enable: [✓] Enable FRR
# Default Router ID: 100.64.0.1

# Services > FRR > BGP
# Enable: [✓] Enable BGP Routing
# Local AS: 394955

# Add BGP Neighbors (Telus Gateways)
┌─────────────────────────────────────────────┐
│ Neighbor 1:                                 │
│   IP: 206.75.1.127                          │
│   Remote AS: 6939 (Hurricane Electric)     │
│   Description: Telus Gateway 1              │
│   Enable: ✓                                 │
│                                             │
│ Neighbor 2:                                 │
│   IP: 206.75.1.47                           │
│   Remote AS: 6939                           │
│   Description: Telus Gateway 2              │
│   Enable: ✓                                 │
│                                             │
│ Neighbor 3:                                 │
│   IP: 206.75.1.48                           │
│   Remote AS: 6939                           │
│   Description: Telus Gateway 3              │
│   Enable: ✓                                 │
└─────────────────────────────────────────────┘

# Configure Route Redistribution
# Services > FRR > BGP > Advanced
# Redistribute: Connected Routes, Static Routes
```

---

### Phase 5: Testing and Validation

#### Test 1: Proxmox Host Connectivity

```bash
# From Proxmox host
ping -c 4 1.1.1.1
ping -c 4 google.com
ip addr show
brctl show
```

#### Test 2: Router VM Network

```bash
# From pfSense console (VM 200)
# Option 7: Ping host
ping -c 4 206.75.1.127  # Telus gateway
ping -c 4 8.8.8.8       # Internet

# Check BGP sessions
# Option 8: Shell
vtysh
show ip bgp summary
show ip bgp neighbors
show ip route
```

#### Test 3: macOS VM Installation

```
1. Start VM 100 (HACK-Sequoia-01)
2. Open VNC Console
3. Boot to macOS Installer
4. Expected: OpenCore boot menu appears
5. Select "macOS Installer"
6. Open Disk Utility
7. Erase main disk as APFS
8. Close Disk Utility
9. Install macOS to the formatted disk
10. Wait 30-45 minutes for installation
11. Complete macOS setup wizard
12. Verify network connectivity (should get IP from 192.168.100.0/24)
```

#### Test 4: Performance Validation

```bash
# Network throughput test
# From a client on LAN:
iperf3 -s  # On macOS VM or dev VM

# From another client:
iperf3 -c 192.168.100.x -t 60 -P 10

# Expected: >9 Gbps on 10GbE interfaces

# CPU performance (on macOS VM)
# Install Geekbench from App Store
# Run CPU benchmark
# Expected: Single-core >1000, Multi-core >10000 (12 cores)

# Storage performance (on macOS VM)
# Install Blackmagic Disk Speed Test
# Run test
# Expected: >500 MB/s read/write on virtio-scsi
```

---

## 📊 Monitoring and Management

### Proxmox Monitoring

```bash
# Install monitoring tools
apt-get install -y prometheus prometheus-node-exporter grafana

# Enable Prometheus
systemctl enable prometheus prometheus-node-exporter
systemctl start prometheus prometheus-node-exporter

# Configure Grafana
systemctl enable grafana-server
systemctl start grafana-server

# Access Grafana: http://192.168.100.10:3000
# Default credentials: admin/admin
# Import Proxmox dashboard: Dashboard ID 10048
```

### Router Monitoring

```
pfSense Web UI > Status > Dashboard
- Interface Statistics
- BGP Session Status
- Gateway Status
- Traffic Graphs
- System Resources

Configure Alerts:
System > Advanced > Notifications
- Email alerts for gateway down
- BGP session state changes
- High CPU/memory usage
```

### macOS VM Monitoring

```bash
# From macOS terminal
# CPU usage
top

# Network stats
nettop

# Disk I/O
iostat -w 1

# System info
system_profiler SPHardwareDataType
```

---

## 🔧 Troubleshooting

### Issue 1: macOS VM Won't Boot

**Symptoms:** Stuck at Apple logo, blank screen, or reboot loop

**Solutions:**

```bash
# 1. Check VM configuration
qm config 100 | grep -E "cpu|args"

# 2. Verify OpenCore ISO is attached
qm config 100 | grep ide2

# 3. Ensure CPU type is compatible
qm set 100 --cpu Haswell-noTSX

# 4. Check TSC (timestamp counter)
dmesg | grep -i tsc
# Should show: "clocksource: Switched to clocksource tsc"

# 5. Force TSC if needed
nano /etc/default/grub
# Add: clocksource=tsc tsc=reliable
update-grub
reboot
```

### Issue 2: BGP Sessions Not Establishing

**Symptoms:** pfSense shows BGP neighbors in "Active" or "Connect" state

**Solutions:**

```bash
# 1. Verify WAN interface has correct IP
# pfSense > Interfaces > WAN
# Ensure static IP is configured correctly

# 2. Check routing to BGP peers
# pfSense > Diagnostics > Ping
ping -S 206.75.1.126 206.75.1.127  # Use WAN IP as source

# 3. Verify FRR is running
# pfSense > Status > Services
# Ensure FRR service is running

# 4. Check BGP configuration
vtysh
show run
# Verify "router bgp 394955" section exists

# 5. Debug BGP
debug bgp
tail -f /var/log/frr/frr.log
```

### Issue 3: Poor Network Performance

**Symptoms:** Low throughput (<1 Gbps on 10GbE), high latency

**Solutions:**

```bash
# 1. Enable virtio offloading
qm set 100 --net0 virtio,bridge=vmbr2,firewall=0

# 2. Tune VM CPU settings
qm set 100 --cpu host

# 3. Enable NUMA
qm set 100 --numa 1

# 4. Disable firewall on bridge (if not needed)
qm set 100 --net0 virtio,bridge=vmbr2,firewall=0

# 5. Check for packet loss
ethtool -S vmbr2 | grep -i drop

# 6. Increase TX/RX ring buffers
ethtool -g eno5
ethtool -G eno5 rx 4096 tx 4096
```

### Issue 4: GPU Passthrough Not Working

**Symptoms:** macOS shows black screen on external monitor

**Solutions:**

```bash
# 1. Verify IOMMU is enabled
dmesg | grep -i iommu
# Should show IOMMU enabled messages

# 2. Check IOMMU groups
find /sys/kernel/iommu_groups/ -type l

# 3. Verify GPU is bound to vfio-pci
lspci -k | grep -A 3 VGA

# 4. Disable "Above 4G Decoding" in BIOS
# (Access via iDRAC > BIOS Settings)

# 5. Add ACS override if needed
nano /etc/default/grub
# Add: pcie_acs_override=downstream,multifunction
update-grub
reboot
```

---

## 📚 Additional Resources

### Documentation

- **Proxmox VE:** https://pve.proxmox.com/pve-docs/
- **OSX-PROXMOX:** https://github.com/luchina-gabriel/OSX-PROXMOX
- **pfSense:** https://docs.netgate.com/pfsense/
- **FRR (BGP):** https://docs.frrouting.org/
- **OpenCore:** https://dortania.github.io/OpenCore-Install-Guide/

### Community Support

- **Proxmox Forum:** https://forum.proxmox.com/
- **Universo Hackintosh (Discord):** https://discord.universohackintosh.com.br
- **pfSense Forum:** https://forum.netgate.com/
- **Reddit:** r/Proxmox, r/hackintosh, r/homelab

---

## ✅ Success Criteria Checklist

- [ ] Proxmox VE installed and accessible via web UI
- [ ] All 8 network interfaces detected and configured
- [ ] Network bridges (vmbr0-vmbr3) created and functional
- [ ] OSX-PROXMOX installer completed successfully
- [ ] macOS Sequoia VM created and boots to installer
- [ ] macOS installation completes and reaches desktop
- [ ] Router VM (pfSense) installed and configured
- [ ] BGP sessions established with all 3 Telus gateways
- [ ] IPv4 and IPv6 routing working (can reach internet from LAN)
- [ ] Network performance >9 Gbps on 10GbE interfaces
- [ ] Latency <2ms to Telus gateways from router
- [ ] All VMs auto-start on boot (onboot=1)
- [ ] Monitoring dashboards operational (Grafana, pfSense)
- [ ] Backup strategy configured (Proxmox Backup Server or scripts)
- [ ] Documentation updated with actual IP addresses and settings

---

## 🎯 Next Steps After Deployment

### Week 1: Stabilization
- Monitor all VMs for 7 days
- Fine-tune CPU core allocation
- Optimize network throughput
- Configure automated backups

### Week 2: Development Environment
- Create Linux dev VMs (Ubuntu, Debian)
- Setup Docker host VM
- Configure NFS/iSCSI storage
- Deploy CI/CD runners

### Week 3: Advanced Features
- Implement HA (High Availability) clustering
- Configure GPU passthrough for macOS
- Setup VPN server (WireGuard/OpenVPN)
- Implement monitoring alerts

### Week 4: Production Hardening
- Security audit (firewall rules, SSH hardening)
- Disaster recovery testing
- Performance benchmarking
- Documentation finalization

---

## 🔐 Security Recommendations

### Proxmox Host

```bash
# Change default SSH port
nano /etc/ssh/sshd_config
# Port 2222

# Disable root SSH login
# PermitRootLogin no

# Enable fail2ban
apt-get install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# Configure UFW firewall
apt-get install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow 2222/tcp  # SSH
ufw allow 8006/tcp  # Proxmox web UI
ufw enable
```

### pfSense Router

```
1. Enable automatic updates
   System > Update > Check for Updates

2. Configure firewall rules (deny-all default)
   Firewall > Rules > WAN
   - Block all inbound except established/related
   - Rate limit ICMP

3. Enable IDS/IPS (Snort or Suricata)
   System > Package Manager > Install Suricata
   Services > Suricata > Enable

4. Configure VPN (WireGuard recommended)
   VPN > WireGuard > Add Tunnel
   - Use for remote management

5. Enable logging
   Status > System Logs > Settings
   - Log to remote syslog server
```

---

## 📝 Conclusion

You now have a **unified Proxmox-based platform** running on the Dell PowerEdge R730 (ORION) that provides:

✅ **Enterprise Routing** - pfSense with BGP, replacing Telus modem
✅ **macOS Virtualization** - Run Sequoia and other macOS versions
✅ **Development Platform** - Host additional VMs and containers
✅ **High Performance** - 10GbE networking, 56 CPU cores, 384GB RAM
✅ **Scalability** - Easy to add more VMs and services
✅ **Manageability** - Centralized Proxmox web UI for all resources

**Total Setup Time:** ~4-6 hours (depending on experience level)

**Questions or issues?** Refer to the troubleshooting section or community resources above.

---

**Document Version:** 1.0.0
**Last Updated:** 2025-01-19
**Maintained By:** ORION Project Team
**License:** MIT (where applicable, respecting upstream licenses)
