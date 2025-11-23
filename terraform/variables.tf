# Terraform Variables for ORION Infrastructure
# Define all input variables here

# =============================================================================
# Proxmox Connection
# =============================================================================

variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://192.168.100.10:8006/api2/json"
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification (use for self-signed certs)"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "orion-pve"
}

# =============================================================================
# Network Configuration
# =============================================================================

variable "network_gateway" {
  description = "Default gateway for VMs"
  type        = string
  default     = "192.168.100.1"
}

variable "network_dns" {
  description = "DNS servers for VMs"
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "network_domain" {
  description = "DNS domain for VMs"
  type        = string
  default     = "orion.local"
}

variable "network_vlan_id" {
  description = "VLAN ID (0 = no VLAN)"
  type        = number
  default     = 0
}

# =============================================================================
# VM Defaults
# =============================================================================

variable "vm_default_user" {
  description = "Default username for cloud-init"
  type        = string
  default     = "ubuntu"
}

variable "vm_ssh_keys" {
  description = "SSH public keys for VM access"
  type        = list(string)
  default     = []
}

variable "vm_storage_pool" {
  description = "Storage pool for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "vm_iso_storage" {
  description = "Storage for ISO files"
  type        = string
  default     = "local"
}

# =============================================================================
# NetBox VM Configuration
# =============================================================================

variable "netbox_vm_id" {
  description = "VM ID for NetBox"
  type        = number
  default     = 500
}

variable "netbox_cores" {
  description = "CPU cores for NetBox VM"
  type        = number
  default     = 4
}

variable "netbox_memory" {
  description = "Memory (MB) for NetBox VM"
  type        = number
  default     = 8192
}

variable "netbox_disk_size" {
  description = "Disk size (GB) for NetBox VM"
  type        = string
  default     = "100G"
}

variable "netbox_ip_address" {
  description = "IP address for NetBox"
  type        = string
  default     = "192.168.100.50"
}

variable "netbox_cidr" {
  description = "CIDR notation for NetBox IP"
  type        = number
  default     = 24
}

# =============================================================================
# K8s Cluster Configuration
# =============================================================================

variable "k8s_master_vm_id" {
  description = "Starting VM ID for K8s master nodes"
  type        = number
  default     = 600
}

variable "k8s_worker_vm_id_start" {
  description = "Starting VM ID for K8s worker nodes"
  type        = number
  default     = 601
}

variable "k8s_master_count" {
  description = "Number of K8s master nodes"
  type        = number
  default     = 1
}

variable "k8s_worker_count" {
  description = "Number of K8s worker nodes"
  type        = number
  default     = 3
}

variable "k8s_master_cores" {
  description = "CPU cores for K8s master nodes"
  type        = number
  default     = 4
}

variable "k8s_master_memory" {
  description = "Memory (MB) for K8s master nodes"
  type        = number
  default     = 8192
}

variable "k8s_worker_cores" {
  description = "CPU cores for K8s worker nodes"
  type        = number
  default     = 4
}

variable "k8s_worker_memory" {
  description = "Memory (MB) for K8s worker nodes"
  type        = number
  default     = 16384
}

variable "k8s_disk_size" {
  description = "Disk size for K8s nodes"
  type        = string
  default     = "100G"
}

variable "k8s_ip_range_start" {
  description = "Starting IP for K8s cluster"
  type        = string
  default     = "192.168.100.60"
}

# =============================================================================
# Tags and Metadata
# =============================================================================

variable "tags" {
  description = "Tags to apply to all resources"
  type        = list(string)
  default     = ["terraform", "orion", "iac"]
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

# =============================================================================
# Cloud-init Template
# =============================================================================

variable "cloud_init_template" {
  description = "Cloud-init template name (must exist in Proxmox)"
  type        = string
  default     = "ubuntu-2404-cloudinit-template"
}

# =============================================================================
# Feature Flags
# =============================================================================

variable "enable_netbox" {
  description = "Deploy NetBox VM"
  type        = bool
  default     = true
}

variable "enable_k8s_cluster" {
  description = "Deploy K8s cluster"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Install monitoring agents on VMs"
  type        = bool
  default     = true
}

variable "auto_start" {
  description = "Auto-start VMs on Proxmox boot"
  type        = bool
  default     = true
}
