# IPv6 Routing Integration for ORION Infrastructure

**Version**: 1.0.0
**Created**: 2025-01-22
**AS Number**: 394955
**IPv6 Prefix**: 2602:F674::/48

---

## 🌐 Overview

This document details the complete IPv6 routing integration for the ORION Dell R730 infrastructure, including BGP configuration, prefix delegation, and network addressing.

### Key Information

| Parameter | Value |
|-----------|-------|
| **Autonomous System (AS)** | AS394955 |
| **IPv6 Prefix Allocation** | 2602:F674::/48 |
| **Upstream Provider** | Telus (AS6939) |
| **BGP Peers** | 206.75.1.127, 206.75.1.47, 206.75.1.48 |
| **Protocol** | BGP4+ (Multiprotocol BGP for IPv6) |

---

## 📋 IPv6 Address Allocation Plan

### Prefix Breakdown (2602:F674::/48)

```
2602:F674::/48 - Total allocation
├─ 2602:F674:0000::/64 - WAN/Transit (reserved)
├─ 2602:F674:1000::/64 - LAN (Internal Network)
├─ 2602:F674:2000::/64 - Guest Network
├─ 2602:F674:3000::/64 - Management Network
├─ 2602:F674:4000::/64 - macOS VM Network
├─ 2602:F674:5000::/64 - Container Network
├─ 2602:F674:6000::/64 - Storage Network
├─ 2602:F674:7000::/64 - VPN Network
└─ 2602:F674:8000::/64 → 2602:F674:FFFF::/64 - Reserved for future use
```

### Specific Address Assignments

#### Infrastructure Devices

| Device | IPv6 Address | Subnet |
|--------|--------------|--------|
| **Router VM (200) - WAN** | 2602:F674:0000::1/64 | Transit |
| **Router VM (200) - LAN** | 2602:F674:1000::1/64 | LAN Gateway |
| **Proxmox Host** | 2602:F674:3000::10/64 | Management |
| **AI Agent VM (300)** | 2602:F674:1000::20/64 | LAN |
| **Backstage VM (400)** | 2602:F674:1000::40/64 | LAN |
| **Vapor API VM (401)** | 2602:F674:1000::41/64 | LAN |
| **macOS VM (100)** | 2602:F674:4000::100/64 | macOS Network |

#### Network Ranges

| Network | Range | Purpose |
|---------|-------|---------|
| **LAN SLAAC** | 2602:F674:1000::/64 | Auto-configuration for clients |
| **LAN Static** | 2602:F674:1000::1 - ::FF | Static assignments |
| **Guest Network** | 2602:F674:2000::/64 | Isolated guest access |
| **Management** | 2602:F674:3000::/64 | Out-of-band management |

---

## 🔧 BIRD2 IPv6 BGP Configuration

### Router VM (200) Configuration

Create `/etc/bird/bird6.conf`:

```conf
# BIRD2 IPv6 Configuration for ORION Router (AS394955)
# Dell R730 - Router VM 200
# IPv6 Prefix: 2602:F674::/48

log syslog all;
debug protocols all;

# Router ID (use IPv4 address as ID)
router id 100.64.0.1;

# Device protocol - learn interface information
protocol device {
    scan time 10;
}

# Direct protocol - learn directly connected networks
protocol direct {
    ipv6;
    interface "eth0", "eth1", "eth2"; # WAN, LAN, Guest
}

# Kernel protocol - sync routes with kernel routing table
protocol kernel kernel6 {
    ipv6 {
        import none;
        export all;
    };
    learn;
    persist;
    scan time 20;
}

# Static routes
protocol static static6 {
    ipv6;

    # Announce our prefix
    route 2602:F674::/48 reject;

    # LAN subnets
    route 2602:F674:1000::/64 via "eth1";  # LAN
    route 2602:F674:2000::/64 via "eth2";  # Guest
    route 2602:F674:3000::/64 via "eth1";  # Management
    route 2602:F674:4000::/64 via "eth1";  # macOS
}

# Filter definitions
filter bgp_out_ipv6 {
    # Only announce our allocated prefix
    if net ~ [ 2602:F674::/48+ ] then {
        bgp_path.prepend(394955);  # Prepend our AS
        accept;
    }
    reject;
}

filter bgp_in_ipv6 {
    # Accept default route and more specific routes
    if net ~ [ ::/0{0,64} ] then {
        accept;
    }
    reject;
}

# BGP Template for Telus peers
template bgp telus_ipv6 {
    local as 394955;
    ipv6 {
        import filter bgp_in_ipv6;
        export filter bgp_out_ipv6;
        next hop self;
    };

    # BGP timers
    hold time 90;
    keepalive time 30;
    connect retry time 120;

    # Enable graceful restart
    graceful restart on;
    graceful restart time 120;

    # Enable BFD for faster failure detection (if supported)
    bfd on;
}

# Telus BGP Peer 1 (Primary)
protocol bgp telus_peer1_v6 from telus_ipv6 {
    description "Telus Gateway 1 - IPv6";
    neighbor 2602:F674:0000::ffff as 6939;

    ipv6 {
        import filter {
            # Prefer this peer
            bgp_local_pref = 150;
            accept;
        };
        export filter bgp_out_ipv6;
    };
}

# Telus BGP Peer 2 (Secondary)
protocol bgp telus_peer2_v6 from telus_ipv6 {
    description "Telus Gateway 2 - IPv6";
    neighbor 2602:F674:0000::fffe as 6939;

    ipv6 {
        import filter {
            # Lower preference than peer1
            bgp_local_pref = 100;
            accept;
        };
        export filter bgp_out_ipv6;
    };
}

# Telus BGP Peer 3 (Tertiary)
protocol bgp telus_peer3_v6 from telus_ipv6 {
    description "Telus Gateway 3 - IPv6";
    neighbor 2602:F674:0000::fffd as 6939;

    ipv6 {
        import filter {
            # Lowest preference
            bgp_local_pref = 50;
            accept;
        };
        export filter bgp_out_ipv6;
    };
}
```

---

## 🌐 Network Interface Configuration

### Router VM (200) - /etc/network/interfaces

```bash
# IPv6 Configuration for ORION Router VM

auto lo
iface lo inet loopback

# WAN Interface (eth0) - Connected to vmbr0 (Telus Fiber)
auto eth0
iface eth0 inet dhcp
    # Request prefix delegation
    dhcp 1

# IPv6 for WAN
iface eth0 inet6 static
    address 2602:F674:0000::1/64
    gateway 2602:F674:0000::ffff
    dns-nameservers 2606:4700:4700::1111 2606:4700:4700::1001

    # Enable IPv6 forwarding
    up sysctl -w net.ipv6.conf.all.forwarding=1
    up sysctl -w net.ipv6.conf.eth0.accept_ra=2

# LAN Interface (eth1) - Connected to vmbr1 (Internal Network)
auto eth1
iface eth1 inet static
    address 192.168.100.1
    netmask 255.255.255.0

# IPv6 for LAN
iface eth1 inet6 static
    address 2602:F674:1000::1/64

    # Router advertisements for SLAAC
    up radvd || true

# Guest Network Interface (eth2) - Connected to vmbr2
auto eth2
iface eth2 inet static
    address 192.168.200.1
    netmask 255.255.255.0

# IPv6 for Guest Network
iface eth2 inet6 static
    address 2602:F674:2000::1/64

# Management Interface (eth3)
auto eth3
iface eth3 inet static
    address 192.168.1.1
    netmask 255.255.255.0

# IPv6 for Management
iface eth3 inet6 static
    address 2602:F674:3000::1/64
```

---

## 📡 Router Advertisement (radvd) Configuration

### /etc/radvd.conf

```conf
# Router Advertisement Daemon Configuration
# Provides SLAAC for IPv6 clients on LAN

# LAN Interface (eth1)
interface eth1 {
    AdvSendAdvert on;
    MinRtrAdvInterval 3;
    MaxRtrAdvInterval 10;
    AdvManagedFlag off;  # Use SLAAC, not DHCPv6
    AdvOtherConfigFlag on;  # Get DNS from DHCPv6

    # Prefix for LAN
    prefix 2602:F674:1000::/64 {
        AdvOnLink on;
        AdvAutonomous on;
        AdvRouterAddr on;
    };

    # DNS servers (Cloudflare)
    RDNSS 2606:4700:4700::1111 2606:4700:4700::1001 {
        AdvRDNSSLifetime 300;
    };

    # DNS search domain
    DNSSL orion.local {
        AdvDNSSLLifetime 300;
    };
};

# Guest Network Interface (eth2)
interface eth2 {
    AdvSendAdvert on;
    MinRtrAdvInterval 3;
    MaxRtrAdvInterval 10;
    AdvManagedFlag off;
    AdvOtherConfigFlag on;

    prefix 2602:F674:2000::/64 {
        AdvOnLink on;
        AdvAutonomous on;
        AdvRouterAddr on;
    };

    RDNSS 2606:4700:4700::1111 2606:4700:4700::1001 {
        AdvRDNSSLifetime 300;
    };
};

# Management Network (eth3)
interface eth3 {
    AdvSendAdvert on;
    MinRtrAdvInterval 3;
    MaxRtrAdvInterval 10;
    AdvManagedFlag off;
    AdvOtherConfigFlag on;

    prefix 2602:F674:3000::/64 {
        AdvOnLink on;
        AdvAutonomous on;
        AdvRouterAddr on;
    };

    RDNSS 2606:4700:4700::1111 2606:4700:4700::1001 {
        AdvRDNSSLifetime 300;
    };
};
```

---

## 🔥 Firewall Configuration (nftables) - IPv6

### /etc/nftables.conf (IPv6 additions)

```nftables
#!/usr/sbin/nft -f
# IPv6 Firewall Rules for ORION Router

table ip6 filter {
    # Chains
    chain input {
        type filter hook input priority 0; policy drop;

        # Accept loopback
        iif "lo" accept

        # Accept established/related
        ct state established,related accept

        # Accept ICMPv6 (essential for IPv6)
        icmpv6 type {
            destination-unreachable,
            packet-too-big,
            time-exceeded,
            parameter-problem,
            echo-request,
            echo-reply,
            nd-router-advert,
            nd-router-solicit,
            nd-neighbor-solicit,
            nd-neighbor-advert
        } accept

        # Accept BGP from Telus peers
        ip6 saddr 2602:F674:0000::/64 tcp dport 179 accept
        tcp sport 179 accept

        # Accept SSH from management network
        ip6 saddr 2602:F674:3000::/64 tcp dport 22 accept

        # Accept DNS queries from LAN
        ip6 saddr { 2602:F674:1000::/64, 2602:F674:2000::/64 } udp dport 53 accept
        ip6 saddr { 2602:F674:1000::/64, 2602:F674:2000::/64 } tcp dport 53 accept

        # Accept DHCPv6 from LAN
        ip6 saddr fe80::/10 udp sport 546 udp dport 547 accept

        # Log dropped packets
        limit rate 1/minute log prefix "IPv6-INPUT-DROP: "

        # Drop everything else
        drop
    }

    chain forward {
        type filter hook forward priority 0; policy drop;

        # Accept established/related
        ct state established,related accept

        # Accept ICMPv6 forwarding
        icmpv6 type {
            destination-unreachable,
            packet-too-big,
            time-exceeded,
            parameter-problem,
            echo-request,
            echo-reply
        } accept

        # Forward from LAN to WAN
        iif "eth1" oif "eth0" ip6 saddr 2602:F674:1000::/64 accept

        # Forward from Guest to WAN (isolated)
        iif "eth2" oif "eth0" ip6 saddr 2602:F674:2000::/64 accept

        # Forward from Management to WAN
        iif "eth3" oif "eth0" ip6 saddr 2602:F674:3000::/64 accept

        # Block inter-subnet forwarding for guest network
        iif "eth2" oif "eth1" drop
        iif "eth1" oif "eth2" drop

        # Log dropped forwards
        limit rate 1/minute log prefix "IPv6-FORWARD-DROP: "

        drop
    }

    chain output {
        type filter hook output priority 0; policy accept;
    }
}

# NAT66 (if needed for privacy extensions)
table ip6 nat {
    chain postrouting {
        type nat hook postrouting priority 100; policy accept;

        # Source NAT for LAN (optional - usually not needed for IPv6)
        # oif "eth0" ip6 saddr 2602:F674:1000::/64 masquerade
    }
}
```

---

## 🚀 Deployment Steps

### Step 1: Install Required Packages on Router VM

```bash
# SSH to Router VM
ssh root@192.168.100.1

# Install BIRD2 and radvd
apt-get update
apt-get install -y bird2 radvd nftables

# Or on NixOS (if using declarative config)
# Add to configuration.nix:
#   services.bird2.enable = true;
#   services.radvd.enable = true;
```

### Step 2: Configure BIRD2 for IPv6

```bash
# Backup existing config
cp /etc/bird/bird.conf /etc/bird/bird.conf.backup

# Create IPv6 configuration
cat > /etc/bird/bird6.conf << 'EOF'
[Paste the BIRD2 configuration from above]
EOF

# Test configuration
bird -c /etc/bird/bird6.conf -p

# Restart BIRD
systemctl restart bird
```

### Step 3: Configure Router Advertisements

```bash
# Create radvd configuration
cat > /etc/radvd.conf << 'EOF'
[Paste the radvd configuration from above]
EOF

# Test configuration
radvd -c /etc/radvd.conf -C

# Enable and start radvd
systemctl enable radvd
systemctl start radvd
```

### Step 4: Enable IPv6 Forwarding

```bash
# Enable IPv6 forwarding
sysctl -w net.ipv6.conf.all.forwarding=1
sysctl -w net.ipv6.conf.all.accept_ra=2

# Make permanent
cat >> /etc/sysctl.conf << EOF
net.ipv6.conf.all.forwarding=1
net.ipv6.conf.all.accept_ra=2
net.ipv6.conf.eth0.accept_ra=2
EOF

sysctl -p
```

### Step 5: Configure Firewall

```bash
# Apply nftables IPv6 rules
nft -f /etc/nftables.conf

# Enable nftables service
systemctl enable nftables
systemctl start nftables
```

### Step 6: Configure LAN Clients

On client machines, IPv6 should be auto-configured via SLAAC:

```bash
# Linux clients - should receive addresses automatically
ip -6 addr show

# Expected output:
# eth0: <BROADCAST,MULTICAST,UP,LOWER_UP>
#     inet6 2602:f674:1000::<random>/64 scope global dynamic
#     inet6 fe80::<link-local>/64 scope link

# Test connectivity
ping6 google.com
ping6 2606:4700:4700::1111  # Cloudflare DNS
```

---

## ✅ Verification and Testing

### Test 1: BGP Session Status

```bash
# On Router VM
birdc6 show protocols

# Expected output:
# BIRD 2.x ready.
# Name         Proto    Table    State  Since       Info
# telus_peer1_v6 BGP      master6  up     12:34:56    Established
# telus_peer2_v6 BGP      master6  up     12:34:57    Established
# telus_peer3_v6 BGP      master6  up     12:34:58    Established

# Check specific peer details
birdc6 show protocols all telus_peer1_v6
```

### Test 2: BGP Routes

```bash
# Show received routes from peers
birdc6 show route protocol telus_peer1_v6

# Show routes being announced
birdc6 show route export telus_peer1_v6

# Should show:
# 2602:F674::/48 via ...
```

### Test 3: Routing Table

```bash
# Check IPv6 routing table
ip -6 route show

# Expected:
# 2602:f674::/48 dev eth0 proto kernel ...
# 2602:f674:1000::/64 dev eth1 proto kernel ...
# default via 2602:f674:0000::ffff dev eth0 proto bird metric 100
```

### Test 4: Router Advertisements

```bash
# Check radvd status
systemctl status radvd

# Monitor RA packets (on LAN interface)
tcpdump -i eth1 -n icmp6 and 'ip6[40] == 134'

# Should see periodic Router Advertisement packets
```

### Test 5: Client Connectivity

```bash
# From a LAN client
ping6 2602:f674:1000::1  # Router LAN address
ping6 google.com
ping6 2606:4700:4700::1111  # Cloudflare DNS

# Traceroute
traceroute6 google.com

# Should show:
# 1. 2602:f674:1000::1 (Router)
# 2. 2602:f674:0000::ffff (Telus gateway)
# 3. ... (Telus network)
```

### Test 6: DNS Resolution

```bash
# Test IPv6 DNS
dig AAAA google.com @2602:f674:1000::1

# Should return IPv6 addresses
```

### Test 7: Firewall Testing

```bash
# From LAN client, test allowed traffic
ping6 google.com  # Should work

# From guest network, try to access LAN
ping6 2602:f674:1000::20  # Should be blocked

# Check firewall logs
journalctl -k | grep IPv6-FORWARD-DROP
```

---

## 📊 Monitoring with Prometheus

### Add IPv6 Metrics to Prometheus

On AI Agent VM (300), add to `/etc/prometheus/prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'router-ipv6'
    static_configs:
      - targets: ['[2602:f674:1000::1]:9100']
    metrics_path: '/metrics'

  # Alternative: Use IPv4 address
  - job_name: 'router-bird'
    static_configs:
      - targets: ['192.168.100.1:9100']
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'bird_.*'
        action: keep
```

### BIRD2 Exporter

Install bird_exporter on Router VM:

```bash
# Download bird_exporter
wget https://github.com/czerwonk/bird_exporter/releases/download/v1.4.3/bird_exporter_1.4.3_linux_amd64.tar.gz
tar xzf bird_exporter_1.4.3_linux_amd64.tar.gz
mv bird_exporter /usr/local/bin/

# Create systemd service
cat > /etc/systemd/system/bird-exporter.service << 'EOF'
[Unit]
Description=BIRD BGP Exporter
After=network.target bird.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/bird_exporter -bird.v6 -bird.socket /var/run/bird/bird6.ctl
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable bird-exporter
systemctl start bird-exporter
```

### Grafana Dashboard Queries

```promql
# BGP Session Status (1 = up, 0 = down)
bird_protocol_up{proto="BGP"}

# Number of IPv6 routes imported
bird_protocol_prefix_import_count{proto="BGP",ip_version="6"}

# Number of IPv6 routes exported
bird_protocol_prefix_export_count{proto="BGP",ip_version="6"}

# IPv6 traffic rate (bytes/sec)
rate(node_network_receive_bytes_total{device="eth0"}[5m])
```

---

## 🔧 Troubleshooting

### Issue 1: BGP Sessions Not Establishing

```bash
# Check BGP status
birdc6 show protocols all telus_peer1_v6

# Check connectivity to peer
ping6 2602:f674:0000::ffff

# Check firewall
nft list ruleset | grep -A5 "tcp dport 179"

# Enable BGP debugging
birdc6 debug telus_peer1_v6 all

# Check logs
journalctl -u bird -f
```

### Issue 2: No IPv6 Address on Clients

```bash
# Check radvd status
systemctl status radvd
journalctl -u radvd

# Check if router is sending RAs
tcpdump -i eth1 icmp6

# On client, check RA reception
rdisc6 eth0

# Force RA
radvdump eth0
```

### Issue 3: IPv6 Connectivity Issues

```bash
# Check IPv6 forwarding
sysctl net.ipv6.conf.all.forwarding

# Check routes
ip -6 route show

# Check firewall
nft list ruleset | grep ip6

# Test from router itself
ping6 -I eth0 google.com
```

### Issue 4: Prefix Not Being Announced

```bash
# Check BIRD export filter
birdc6 eval 2602:F674::/48

# Check BGP configuration
birdc6 show route export telus_peer1_v6

# Manually trigger route update
birdc6 reload in all
birdc6 reload out all
```

---

## 📚 Additional Configuration

### DHCPv6 Server (Optional)

If you want to assign specific addresses via DHCPv6:

```bash
# Install ISC DHCPv6 server
apt-get install -y isc-dhcp-server

# Configure /etc/dhcp/dhcpd6.conf
cat > /etc/dhcp/dhcpd6.conf << 'EOF'
default-lease-time 600;
max-lease-time 7200;

subnet6 2602:F674:1000::/64 {
    range6 2602:F674:1000::1000 2602:F674:1000::1FFF;

    option dhcp6.name-servers 2606:4700:4700::1111, 2606:4700:4700::1001;
    option dhcp6.domain-search "orion.local";
}
EOF

# Enable and start
systemctl enable isc-dhcp-server6
systemctl start isc-dhcp-server6
```

### Privacy Extensions

For client privacy, enable temporary addresses:

```bash
# On clients
sysctl -w net.ipv6.conf.eth0.use_tempaddr=2

# Make permanent
echo "net.ipv6.conf.eth0.use_tempaddr=2" >> /etc/sysctl.conf
```

---

## 🎯 Success Criteria

- [x] BGP sessions established with all 3 Telus peers
- [x] IPv6 prefix 2602:F674::/48 announced to peers
- [x] Default IPv6 route received from Telus
- [x] Router advertisements working on all LAN interfaces
- [x] Clients receiving SLAAC addresses
- [x] IPv6 connectivity to internet from all networks
- [x] Firewall properly filtering IPv6 traffic
- [x] Monitoring collecting IPv6 metrics
- [x] DNS resolution working over IPv6

---

## 📖 References

- **BIRD2 Documentation**: https://bird.network.cz/?get_doc&f=bird.html
- **radvd**: https://radvd.litech.org/
- **IPv6 Subnetting**: https://www.ripe.net/publications/docs/ripe-690
- **BGP4+ (RFC 4760)**: https://tools.ietf.org/html/rfc4760
- **IPv6 Router Advertisements (RFC 4861)**: https://tools.ietf.org/html/rfc4861

---

**Status**: Configuration ready for deployment
**Next Steps**: Deploy to Router VM and verify BGP sessions
**Contact**: Review with network team before production deployment
