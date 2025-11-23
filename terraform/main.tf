# ORION Infrastructure - Main Terraform Configuration
# Defines all VMs for the complete stack

locals {
  common_tags = concat(var.tags, [var.environment])
}

# =============================================================================
# VM 200: Router (BIRD2 BGP, IPv6, Firewall)
# =============================================================================

resource "proxmox_vm_qemu" "router" {
  name        = "ORION-Router"
  target_node = var.proxmox_node
  vmid        = 200

  clone      = var.cloud_init_template
  full_clone = true

  cores   = 8
  sockets = 1
  memory  = 32768

  disk {
    slot    = 0
    size    = "50G"
    type    = "scsi"
    storage = var.vm_storage_pool
    ssd     = 1
  }

  # WAN interface (vmbr0)
  network {
    model  = "virtio"
    bridge = "vmbr0"
    tag    = var.network_vlan_id
  }

  # LAN interface (vmbr1)
  network {
    model  = "virtio"
    bridge = "vmbr1"
  }

  # Guest network interface (vmbr2)
  network {
    model  = "virtio"
    bridge = "vmbr2"
  }

  # Management interface
  network {
    model  = "virtio"
    bridge = "vmbr1"
  }

  os_type    = "cloud-init"
  ipconfig0  = "ip=dhcp"  # WAN from Telus
  ipconfig1  = "ip=192.168.100.1/24"
  ipconfig2  = "ip=192.168.200.1/24"
  ipconfig3  = "ip=192.168.1.1/24"

  nameserver = join(" ", var.network_dns)

  sshkeys    = join("\n", var.vm_ssh_keys)

  onboot     = var.auto_start
  startup    = "order=1,up=30"

  tags = join(";", concat(local.common_tags, ["router", "network"]))
}

# =============================================================================
# VM 300: AI Coordinator (Multi-Agent Orchestration)
# =============================================================================

resource "proxmox_vm_qemu" "ai_coordinator" {
  name        = "ORION-AI-Coordinator"
  target_node = var.proxmox_node
  vmid        = 300

  clone      = var.cloud_init_template
  full_clone = true

  cores   = 4
  sockets = 1
  memory  = 16384

  disk {
    slot    = 0
    size    = "100G"
    type    = "scsi"
    storage = var.vm_storage_pool
    ssd     = 1
  }

  network {
    model  = "virtio"
    bridge = "vmbr1"
  }

  os_type    = "cloud-init"
  ipconfig0  = "ip=192.168.100.30/24,gw=${var.network_gateway}"
  nameserver = join(" ", var.network_dns)
  sshkeys    = join("\n", var.vm_ssh_keys)

  onboot  = var.auto_start
  startup = "order=3,up=30"

  tags = join(";", concat(local.common_tags, ["ai", "coordinator"]))
}

# =============================================================================
# VM 500: NetBox (IPAM and Network Documentation)
# =============================================================================

resource "proxmox_vm_qemu" "netbox" {
  count = var.enable_netbox ? 1 : 0

  name        = "ORION-NetBox"
  target_node = var.proxmox_node
  vmid        = var.netbox_vm_id

  clone      = var.cloud_init_template
  full_clone = true

  cores   = var.netbox_cores
  sockets = 1
  memory  = var.netbox_memory

  disk {
    slot    = 0
    size    = var.netbox_disk_size
    type    = "scsi"
    storage = var.vm_storage_pool
    ssd     = 1
  }

  network {
    model  = "virtio"
    bridge = "vmbr1"
  }

  os_type    = "cloud-init"
  ipconfig0  = "ip=${var.netbox_ip_address}/${var.netbox_cidr},gw=${var.network_gateway}"
  nameserver = join(" ", var.network_dns)
  sshkeys    = join("\n", var.vm_ssh_keys)

  onboot  = var.auto_start
  startup = "order=2,up=30"

  tags = join(";", concat(local.common_tags, ["netbox", "ipam"]))
}

# =============================================================================
# VMs 600-603: Kubernetes Cluster (K3s)
# =============================================================================

# K3s Master Node
resource "proxmox_vm_qemu" "k8s_master" {
  count = var.enable_k8s_cluster ? var.k8s_master_count : 0

  name        = "ORION-K3s-Master-${count.index + 1}"
  target_node = var.proxmox_node
  vmid        = var.k8s_master_vm_id + count.index

  clone      = var.cloud_init_template
  full_clone = true

  cores   = var.k8s_master_cores
  sockets = 1
  memory  = var.k8s_master_memory

  disk {
    slot    = 0
    size    = var.k8s_disk_size
    type    = "scsi"
    storage = var.vm_storage_pool
    ssd     = 1
  }

  network {
    model  = "virtio"
    bridge = "vmbr1"
  }

  os_type    = "cloud-init"
  ipconfig0  = "ip=${cidrhost("${var.k8s_ip_range_start}/24", count.index)}/${var.netbox_cidr},gw=${var.network_gateway}"
  nameserver = join(" ", var.network_dns)
  sshkeys    = join("\n", var.vm_ssh_keys)

  onboot  = var.auto_start
  startup = "order=4,up=30"

  tags = join(";", concat(local.common_tags, ["kubernetes", "k3s", "master"]))
}

# K3s Worker Nodes
resource "proxmox_vm_qemu" "k8s_workers" {
  count = var.enable_k8s_cluster ? var.k8s_worker_count : 0

  name        = "ORION-K3s-Worker-${count.index + 1}"
  target_node = var.proxmox_node
  vmid        = var.k8s_worker_vm_id_start + count.index

  clone      = var.cloud_init_template
  full_clone = true

  cores   = var.k8s_worker_cores
  sockets = 1
  memory  = var.k8s_worker_memory

  disk {
    slot    = 0
    size    = var.k8s_disk_size
    type    = "scsi"
    storage = var.vm_storage_pool
    ssd     = 1
  }

  network {
    model  = "virtio"
    bridge = "vmbr1"
  }

  os_type    = "cloud-init"
  ipconfig0  = "ip=${cidrhost("${var.k8s_ip_range_start}/24", var.k8s_master_count + count.index)}/${var.netbox_cidr},gw=${var.network_gateway}"
  nameserver = join(" ", var.network_dns)
  sshkeys    = join("\n", var.vm_ssh_keys)

  onboot  = var.auto_start
  startup = "order=5,up=30"

  tags = join(";", concat(local.common_tags, ["kubernetes", "k3s", "worker"]))
}

# =============================================================================
# VM 100: macOS Sequoia (Optional - Development)
# =============================================================================
# Note: macOS VM requires special OpenCore configuration
# This is a placeholder - use existing deploy-orion.sh macOS logic

# Uncomment and configure if deploying macOS:
# resource "proxmox_vm_qemu" "macos" {
#   name        = "HACK-Sequoia-01"
#   target_node = var.proxmox_node
#   vmid        = 100
#   # ... macOS-specific configuration
# }
