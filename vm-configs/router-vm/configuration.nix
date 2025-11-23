# NixOS Configuration for ORION Router VM
# Dell R730 - VM 200
# Purpose: High-performance routing with VyOS, BGP, firewall

{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # System
  system.stateVersion = "24.11";
  networking.hostName = "orion-router";
  networking.domain = "lucia-ai.internal";

  # Boot
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.kernelModules = [ "kvm-intel" ];

  # Enable IP forwarding
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
  };

  # Network Interfaces
  # eth0 = WAN (Telus Fiber)
  # eth1 = LAN (Internal 192.168.100.0/24)
  # eth2 = Guest (192.168.200.0/24)
  # eth3 = Management (192.168.1.0/24)

  networking.interfaces = {
    eth0.useDHCP = true;  # WAN - get IP from Telus

    eth1.ipv4.addresses = [{
      address = "192.168.100.1";
      prefixLength = 24;
    }];
    eth1.ipv6.addresses = [{
      address = "2602:F674:1000::1";
      prefixLength = 64;
    }];

    eth2.ipv4.addresses = [{
      address = "192.168.200.1";
      prefixLength = 24;
    }];

    eth3.ipv4.addresses = [{
      address = "192.168.1.1";
      prefixLength = 24;
    }];
  };

  # Firewall - use nftables
  networking.firewall.enable = false;  # We'll use nftables directly
  networking.nftables.enable = true;
  networking.nftables.ruleset = ''
    table inet filter {
      chain input {
        type filter hook input priority 0; policy drop;

        # Accept loopback
        iif lo accept

        # Accept established/related
        ct state {established, related} accept

        # Accept ICMP
        ip protocol icmp accept
        ip6 nexthdr icmpv6 accept

        # Accept SSH from LAN
        iif eth1 tcp dport 22 accept
        iif eth3 tcp dport 22 accept

        # Accept DNS from LAN
        iif eth1 udp dport 53 accept
        iif eth1 tcp dport 53 accept

        # Accept DHCP
        iif eth1 udp dport 67 accept

        # Accept BGP from WAN
        iif eth0 tcp dport 179 accept

        # Drop everything else
        counter drop
      }

      chain forward {
        type filter hook forward priority 0; policy drop;

        # Accept established/related
        ct state {established, related} accept

        # Allow LAN to WAN
        iif eth1 oif eth0 accept

        # Allow Guest to WAN (restricted)
        iif eth2 oif eth0 accept

        # Drop everything else
        counter drop
      }

      chain output {
        type filter hook output priority 0; policy accept;
      }
    }

    table ip nat {
      chain postrouting {
        type nat hook postrouting priority 100; policy accept;

        # NAT for LAN
        oif eth0 ip saddr 192.168.100.0/24 masquerade

        # NAT for Guest
        oif eth0 ip saddr 192.168.200.0/24 masquerade
      }
    }
  '';

  # Services
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
    settings.PasswordAuthentication = false;
  };

  # DHCP Server
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [ "eth1" ];
      };
      lease-database = {
        type = "memfile";
        persist = true;
        name = "/var/lib/kea/dhcp4.leases";
      };
      subnet4 = [{
        id = 1;
        subnet = "192.168.100.0/24";
        pools = [{ pool = "192.168.100.100 - 192.168.100.200"; }];
        option-data = [
          {
            name = "routers";
            data = "192.168.100.1";
          }
          {
            name = "domain-name-servers";
            data = "192.168.100.1";
          }
        ];
      }];
    };
  };

  # DNS Server (Unbound)
  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = [ "192.168.100.1" "127.0.0.1" ];
        access-control = [
          "192.168.100.0/24 allow"
          "127.0.0.0/8 allow"
        ];

        # Forward to Cloudflare/Google
        forward-zone = [
          {
            name = ".";
            forward-addr = [
              "1.1.1.1@853#cloudflare-dns.com"
              "1.0.0.1@853#cloudflare-dns.com"
              "8.8.8.8@853#dns.google"
              "8.8.4.4@853#dns.google"
            ];
            forward-tls-upstream = true;
          }
        ];
      };
    };
  };

  # BGP with BIRD2
  services.bird2 = {
    enable = true;
    config = ''
      log syslog all;

      router id 192.168.100.1;

      protocol device {
        scan time 10;
      }

      protocol direct {
        ipv4;
        ipv6;
      }

      protocol kernel {
        ipv4 {
          import all;
          export all;
        };
      }

      protocol kernel {
        ipv6 {
          import all;
          export all;
        };
      }

      protocol static {
        ipv4;
        route 192.168.100.0/24 blackhole;
      }

      # Telus BGP Peers
      protocol bgp telus_gw1 {
        local as 394955;
        neighbor 206.75.1.127 as 6939;

        ipv4 {
          import all;
          export where source = RTS_STATIC;
        };
      }

      protocol bgp telus_gw2 {
        local as 394955;
        neighbor 206.75.1.47 as 6939;

        ipv4 {
          import all;
          export where source = RTS_STATIC;
        };
      }

      protocol bgp telus_gw3 {
        local as 394955;
        neighbor 206.75.1.48 as 6939;

        ipv4 {
          import all;
          export where source = RTS_STATIC;
        };
      }
    '';
  };

  # Monitoring - node exporter for Prometheus
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" "network" ];
    port = 9100;
    openFirewall = true;
  };

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    htop
    iftop
    tcpdump
    mtr
    bind  # for dig/nslookup
    iproute2
    iptables
    nftables
    bird2
    python3
  ];

  # Users
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];  # sudo access
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
    ];
  };

  # Enable sudo without password for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Automatic system upgrades
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    dates = "weekly";
  };

  # Prometheus metrics endpoint
  services.prometheus.exporters.blackbox = {
    enable = true;
    configFile = pkgs.writeText "blackbox.yml" ''
      modules:
        icmp:
          prober: icmp
          timeout: 5s
        http_2xx:
          prober: http
          timeout: 5s
    '';
  };
}
