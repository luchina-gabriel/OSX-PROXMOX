# Terraform Outputs for ORION Infrastructure

output "router_vm_id" {
  description = "Router VM ID"
  value       = proxmox_vm_qemu.router.vmid
}

output "router_ip_lan" {
  description = "Router LAN IP"
  value       = "192.168.100.1"
}

output "ai_coordinator_vm_id" {
  description = "AI Coordinator VM ID"
  value       = proxmox_vm_qemu.ai_coordinator.vmid
}

output "ai_coordinator_ip" {
  description = "AI Coordinator IP"
  value       = "192.168.100.30"
}

output "netbox_vm_id" {
  description = "NetBox VM ID"
  value       = var.enable_netbox ? proxmox_vm_qemu.netbox[0].vmid : null
}

output "netbox_ip" {
  description = "NetBox IP address"
  value       = var.enable_netbox ? var.netbox_ip_address : null
}

output "netbox_url" {
  description = "NetBox web URL"
  value       = var.enable_netbox ? "http://${var.netbox_ip_address}:8000" : null
}

output "k8s_master_ips" {
  description = "K8s master node IPs"
  value       = var.enable_k8s_cluster ? [for i in range(var.k8s_master_count) : cidrhost("${var.k8s_ip_range_start}/24", i)] : []
}

output "k8s_worker_ips" {
  description = "K8s worker node IPs"
  value       = var.enable_k8s_cluster ? [for i in range(var.k8s_worker_count) : cidrhost("${var.k8s_ip_range_start}/24", var.k8s_master_count + i)] : []
}

output "k8s_api_server" {
  description = "K8s API server URL"
  value       = var.enable_k8s_cluster ? "https://${cidrhost("${var.k8s_ip_range_start}/24", 0)}:6443" : null
}

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = <<-EOT

  ╔═══════════════════════════════════════════════════════════════╗
  ║           ORION Infrastructure Deployment Summary             ║
  ╚═══════════════════════════════════════════════════════════════╝

  Router:
    - VM ID: ${proxmox_vm_qemu.router.vmid}
    - LAN IP: 192.168.100.1
    - WAN: DHCP (Telus)
    - Services: BIRD2 BGP, IPv6, Firewall

  AI Coordinator:
    - VM ID: ${proxmox_vm_qemu.ai_coordinator.vmid}
    - IP: 192.168.100.30
    - Purpose: Multi-agent orchestration

  NetBox:
    - VM ID: ${var.enable_netbox ? proxmox_vm_qemu.netbox[0].vmid : "N/A"}
    - IP: ${var.enable_netbox ? var.netbox_ip_address : "N/A"}
    - URL: ${var.enable_netbox ? "http://${var.netbox_ip_address}:8000" : "N/A"}

  Kubernetes Cluster:
    - Master IPs: ${var.enable_k8s_cluster ? join(", ", [for i in range(var.k8s_master_count) : cidrhost("${var.k8s_ip_range_start}/24", i)]) : "N/A"}
    - Worker IPs: ${var.enable_k8s_cluster ? join(", ", [for i in range(var.k8s_worker_count) : cidrhost("${var.k8s_ip_range_start}/24", var.k8s_master_count + i)]) : "N/A"}
    - API Server: ${var.enable_k8s_cluster ? "https://${cidrhost("${var.k8s_ip_range_start}/24", 0)}:6443" : "N/A"}

  Next Steps:
    1. Configure VMs: cd ../ansible && ansible-playbook -i inventory playbooks/site.yml
    2. Deploy K8s apps: cd ../kubernetes && kubectl apply -k infrastructure/
    3. Access NetBox: http://${var.enable_netbox ? var.netbox_ip_address : "N/A"}:8000
    4. Configure BGP: SSH to router and verify BIRD2 sessions

  EOT
}
