# NixOS Configuration for ORION AI Agent VM
# Dell R730 - VM 300
# Purpose: Autonomous network monitoring and management

{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # System
  system.stateVersion = "24.11";
  networking.hostName = "orion-ai-agent";
  networking.domain = "lucia-ai.internal";

  # Boot
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Network
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "192.168.100.20";
    prefixLength = 24;
  }];

  networking.defaultGateway = "192.168.100.1";
  networking.nameservers = [ "192.168.100.1" "1.1.1.1" ];

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22      # SSH
      3000    # Grafana
      9090    # Prometheus
      9100    # Node exporter
    ];
  };

  # Services - Prometheus
  services.prometheus = {
    enable = true;
    port = 9090;

    scrapeConfigs = [
      {
        job_name = "orion-router";
        static_configs = [{
          targets = [ "192.168.100.1:9100" ];
          labels = {
            alias = "router";
          };
        }];
      }
      {
        job_name = "orion-ai-agent";
        static_configs = [{
          targets = [ "localhost:9100" ];
          labels = {
            alias = "ai-agent";
          };
        }];
      }
      {
        job_name = "proxmox";
        static_configs = [{
          targets = [ "192.168.100.10:9100" ];
          labels = {
            alias = "proxmox-host";
          };
        }];
      }
    ];

    rules = [
      ''
        groups:
          - name: orion_alerts
            interval: 30s
            rules:
              - alert: HighCPUUsage
                expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
                for: 5m
                labels:
                  severity: warning
                annotations:
                  summary: "High CPU usage detected"
                  description: "CPU usage is above 90% for 5 minutes"

              - alert: HighMemoryUsage
                expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 95
                for: 5m
                labels:
                  severity: critical
                annotations:
                  summary: "Critical memory usage"
                  description: "Memory usage is above 95%"

              - alert: RouterDown
                expr: up{job="orion-router"} == 0
                for: 1m
                labels:
                  severity: critical
                annotations:
                  summary: "Router is down"
                  description: "Router is not responding to metrics collection"
      ''
    ];
  };

  # Prometheus exporters
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
    port = 9100;
  };

  # Grafana
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
      };
      security = {
        admin_user = "admin";
        admin_password = "orion2025";  # Change this!
      };
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [{
        name = "Prometheus";
        type = "prometheus";
        url = "http://localhost:9090";
        isDefault = true;
      }];
    };
  };

  # SSH
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
    settings.PasswordAuthentication = false;
  };

  # Autonomous Agent Service
  systemd.services.orion-agent = {
    description = "ORION Autonomous Network Agent";
    after = [ "network.target" "prometheus.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "orion-agent";
      Group = "orion-agent";
      ExecStart = "${pkgs.python3}/bin/python3 /opt/orion-agent/autonomous_agent.py";
      Restart = "on-failure";
      RestartSec = "10s";

      # Security hardening
      PrivateTmp = true;
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/var/log" ];
    };
  };

  # Create orion-agent user
  users.users.orion-agent = {
    isSystemUser = true;
    group = "orion-agent";
    description = "ORION Agent Service User";
  };

  users.groups.orion-agent = {};

  # Admin user
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
    ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    htop
    git
    python3
    python3Packages.requests
    python3Packages.prometheus-client
    tmux
    jq
  ];

  # Python environment for agent
  environment.etc."orion-agent/autonomous_agent.py" = {
    source = ./autonomous_agent.py;
    mode = "0755";
  };

  # Create /opt/orion-agent directory
  systemd.tmpfiles.rules = [
    "d /opt/orion-agent 0755 orion-agent orion-agent -"
    "L+ /opt/orion-agent/autonomous_agent.py - - - - /etc/orion-agent/autonomous_agent.py"
  ];

  # Enable sudo without password for wheel
  security.sudo.wheelNeedsPassword = false;

  # Automatic system upgrades
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    dates = "weekly";
  };
}
