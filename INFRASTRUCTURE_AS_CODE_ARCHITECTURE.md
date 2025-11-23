# ORION Infrastructure as Code (IaC) - Complete Stack

**Version**: 2.0.0-iac
**Created**: 2025-01-22
**Status**: Architecture Design

---

## 🎯 Overview

Complete Infrastructure-as-Code stack for ORION Dell R730, integrating industry-standard tools for declarative infrastructure management, automated configuration, IP address management, container orchestration, and programmable routing.

### Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Infrastructure Provisioning** | Terraform | Declarative VM/container deployment |
| **Configuration Management** | Ansible | Automated OS and application configuration |
| **IPAM/Documentation** | NetBox | IP address management and network documentation |
| **Container Orchestration** | Kubernetes (K3s) | Lightweight K8s for container workloads |
| **Programmable Routing** | GoBGP | API-driven BGP routing with Go |
| **Secret Management** | Vault (optional) | Secrets and credential management |
| **State Backend** | Consul/S3 | Terraform state management |

---

## 🏗️ Complete Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CONTROL PLANE (Your Workstation)                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │  Terraform   │  │   Ansible    │  │   kubectl    │              │
│  │   (HCL)      │  │  (Playbooks) │  │    (K8s)     │              │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘              │
│         │                  │                  │                      │
│         │                  │                  │                      │
└─────────┼──────────────────┼──────────────────┼──────────────────────┘
          │                  │                  │
          ↓                  ↓                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│                  Dell R730 - Proxmox VE Layer                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Terraform creates/manages VMs ──→ Ansible configures ──→ Apps run  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │ VM 500: NetBox (IPAM)                                          │ │
│  │ - PostgreSQL database                                          │ │
│  │ - Redis cache                                                  │ │
│  │ - Web UI: 192.168.100.50:8000                                  │ │
│  │ Purpose: IP address management, network documentation          │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │ VM 200: Router (GoBGP + VyOS)                                  │ │
│  │ - GoBGP daemon (port 50051 - gRPC API)                         │ │
│  │ - REST API for BGP control                                     │ │
│  │ - AS394955 ←→ AS6939 (Telus)                                   │ │
│  │ Purpose: Programmable BGP routing                              │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │ VMs 600-603: Kubernetes Cluster (K3s)                          │ │
│  │                                                                │ │
│  │  ┌──────────────────────────────────────────────────────────┐ │ │
│  │  │ VM 600: K3s Master (Control Plane)                       │ │ │
│  │  │ - 4 cores, 8GB RAM                                       │ │ │
│  │  │ - etcd, API server, scheduler, controller                │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  │                                                                │ │
│  │  ┌──────────────────────────────────────────────────────────┐ │ │
│  │  │ VM 601-603: K3s Workers (3 nodes)                        │ │ │
│  │  │ - 4 cores, 16GB RAM each                                 │ │ │
│  │  │ - Run containerized workloads                            │ │ │
│  │  │ - CNI: Flannel or Cilium                                 │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  │                                                                │ │
│  │  Workloads on K8s:                                             │ │
│  │  - Backstage (Developer Portal)                                │ │
│  │  - Vapor API (Swift middleware)                                │ │
│  │  - Prometheus + Grafana (Monitoring)                           │ │
│  │  - Additional microservices                                    │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │ VM 100: macOS Sequoia (Development)                           │ │
│  │ - Still deployed via Terraform                                │ │
│  │ - Configured via Ansible (post-install scripts)               │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │ VM 300: AI Agent (Monitoring)                                 │ │
│  │ - Monitors K8s cluster health                                 │ │
│  │ - Integrates with GoBGP API                                   │ │
│  │ - Manages NetBox updates                                      │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Component 1: Terraform

### Purpose
Declarative infrastructure provisioning - define VMs, networks, and storage in code.

### What Terraform Will Manage

```hcl
# Infrastructure Components
- Proxmox VMs (all VMs defined as Terraform resources)
- Network bridges and VLANs
- Storage allocations
- VM snapshots and backups (scheduled)
- Cloud-init configurations
- DNS records (if using external DNS)
```

### Directory Structure

```
terraform/
├── main.tf                 # Main configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── terraform.tfvars        # Variable values (gitignored)
├── modules/
│   ├── proxmox-vm/         # Reusable VM module
│   ├── k8s-cluster/        # K8s cluster module
│   └── networking/         # Network configuration
├── environments/
│   ├── dev/                # Development environment
│   ├── staging/            # Staging environment
│   └── production/         # Production environment
└── state/
    └── backend.tf          # State backend configuration
```

### Example: VM Definition

```hcl
module "netbox_vm" {
  source = "./modules/proxmox-vm"

  vm_id       = 500
  name        = "ORION-NetBox"
  cores       = 4
  memory      = 8192
  disk_size   = 100
  bridge      = "vmbr1"
  ip_address  = "192.168.100.50"
  tags        = ["ipam", "infrastructure"]
}
```

### Benefits
- ✅ **Reproducible** - Rebuild entire infrastructure from code
- ✅ **Version controlled** - Track infrastructure changes in Git
- ✅ **Idempotent** - Run multiple times safely
- ✅ **Plan before apply** - Preview changes before execution
- ✅ **State management** - Track resource state

---

## 🔧 Component 2: Ansible

### Purpose
Automated configuration management - configure VMs after they're created by Terraform.

### What Ansible Will Manage

```yaml
# Configuration Tasks
- Operating system updates and packages
- User accounts and SSH keys
- Application installation (GoBGP, NetBox, etc.)
- Service configuration files
- Firewall rules
- Monitoring agents
- Security hardening
```

### Directory Structure

```
ansible/
├── ansible.cfg             # Ansible configuration
├── inventory/
│   ├── hosts.yml           # Static inventory
│   └── proxmox.py          # Dynamic inventory (from Proxmox)
├── playbooks/
│   ├── site.yml            # Master playbook
│   ├── router.yml          # Router VM configuration
│   ├── k8s-cluster.yml     # K8s cluster setup
│   ├── netbox.yml          # NetBox deployment
│   └── monitoring.yml      # Monitoring stack
├── roles/
│   ├── common/             # Common configuration
│   ├── gobgp/              # GoBGP installation
│   ├── k3s-master/         # K3s control plane
│   ├── k3s-worker/         # K3s worker node
│   ├── netbox/             # NetBox setup
│   └── security/           # Security hardening
├── group_vars/
│   ├── all.yml             # Variables for all hosts
│   ├── routers.yml         # Router-specific vars
│   └── k8s.yml             # K8s-specific vars
└── host_vars/
    └── router.yml          # Per-host variables
```

### Example: GoBGP Installation Role

```yaml
# roles/gobgp/tasks/main.yml
---
- name: Install GoBGP
  apt:
    name: golang-go
    state: present

- name: Download GoBGP binary
  get_url:
    url: "https://github.com/osrg/gobgp/releases/download/v3.20.0/gobgp_3.20.0_linux_amd64.tar.gz"
    dest: /tmp/gobgp.tar.gz

- name: Extract GoBGP
  unarchive:
    src: /tmp/gobgp.tar.gz
    dest: /usr/local/bin/
    remote_src: yes

- name: Create GoBGP config directory
  file:
    path: /etc/gobgp
    state: directory

- name: Deploy GoBGP configuration
  template:
    src: gobgpd.conf.j2
    dest: /etc/gobgp/gobgpd.conf
  notify: restart gobgp

- name: Install GoBGP systemd service
  template:
    src: gobgpd.service.j2
    dest: /etc/systemd/system/gobgpd.service
  notify: reload systemd
```

### Integration with Terraform

```bash
# Terraform creates VMs, then triggers Ansible
terraform apply
terraform output -json > ansible/inventory/terraform.json
ansible-playbook -i ansible/inventory ansible/playbooks/site.yml
```

---

## 🗄️ Component 3: NetBox (IPAM)

### Purpose
Centralized IP address management, network documentation, and source of truth for infrastructure.

### Features

- **IPAM**: IPv4 and IPv6 address management
- **DCIM**: Data center infrastructure management
- **Circuits**: ISP/provider circuit tracking
- **Secrets**: Encrypted credential storage
- **API**: RESTful API for automation
- **Plugins**: Extensible with custom plugins

### VM Specifications

```yaml
VM ID: 500
Name: ORION-NetBox
OS: Ubuntu 24.04 LTS
CPU: 4 cores
RAM: 8GB
Disk: 100GB
Network: 192.168.100.50/24 (vmbr1)
Services:
  - NetBox web UI (port 8000)
  - PostgreSQL 16
  - Redis 7
  - nginx (reverse proxy)
```

### NetBox Data Model for ORION

```python
# Sites
ORION-Datacenter (Home Lab)

# Racks
Dell-R730-Rack

# Devices
- Dell R730 (CQ5QBM2)
  - Type: Server
  - Role: Hypervisor
  - NICs: 8x (eno1-eno6, enp3s0f0-1)

# Virtual Machines (synced from Proxmox)
- ORION-Router (VM 200)
- ORION-AI-Agent (VM 300)
- ORION-Backstage (VM 400)
- ORION-VaporAPI (VM 401)
- ORION-NetBox (VM 500)
- ORION-K3s-Master (VM 600)
- ORION-K3s-Worker-1 (VM 601)
- ORION-K3s-Worker-2 (VM 602)
- ORION-K3s-Worker-3 (VM 603)

# IP Addresses (both IPv4 and IPv6)
# Prefixes
- 192.168.100.0/24 (LAN)
- 192.168.200.0/24 (Guest)
- 2602:F674::/48 (IPv6 allocation)
  - 2602:F674:1000::/64 (LAN)
  - 2602:F674:2000::/64 (Guest)

# Circuits
- Telus Fiber (10Gbps)
  - BGP AS: 6939
  - IPv6 Peers: 3x
```

### Integration Points

1. **Terraform** ↔ NetBox
   - Terraform reads IP allocations from NetBox API
   - Auto-assigns IPs based on NetBox IPAM

2. **Ansible** ↔ NetBox
   - Dynamic inventory from NetBox
   - Pull configuration data (VLANs, IPs)

3. **Proxmox** ↔ NetBox
   - Sync VMs to NetBox automatically
   - Track VM lifecycle

---

## ☸️ Component 4: Kubernetes (K3s)

### Purpose
Lightweight Kubernetes for container orchestration, replacing standalone VMs for certain workloads.

### Why K3s?

- **Lightweight**: 100MB binary vs 1GB+ for full K8s
- **Easy setup**: Single command installation
- **Low resource**: Runs on smaller VMs
- **Full K8s**: 100% Kubernetes API compatible
- **Built-in**: Traefik ingress, local storage

### Cluster Topology

```
┌─────────────────────────────────────────────────────────┐
│              K3s Cluster - ORION                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Control Plane (VM 600)                                 │
│  ┌───────────────────────────────────────────────────┐ │
│  │ - etcd (distributed key-value store)              │ │
│  │ - kube-apiserver                                  │ │
│  │ - kube-scheduler                                  │ │
│  │ - kube-controller-manager                         │ │
│  │ - Traefik ingress controller                      │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  Worker Nodes (VMs 601-603)                             │
│  ┌───────────────────────────────────────────────────┐ │
│  │ Worker 1 (601): General workloads                 │ │
│  │ Worker 2 (602): Stateful apps (databases)         │ │
│  │ Worker 3 (603): Monitoring stack                  │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### What Runs on K8s

**Instead of separate VMs, these run as Pods:**

1. **Backstage** (formerly VM 400)
   ```yaml
   Deployment: backstage
   Replicas: 2 (HA)
   Resources: 2 CPU, 4GB RAM per pod
   Service: LoadBalancer (192.168.100.40)
   Storage: PVC 50GB
   ```

2. **Vapor API** (formerly VM 401)
   ```yaml
   Deployment: vapor-api
   Replicas: 3 (load balanced)
   Resources: 1 CPU, 2GB RAM per pod
   Service: ClusterIP (internal only)
   ```

3. **Monitoring Stack**
   ```yaml
   - Prometheus (metrics)
   - Grafana (visualization)
   - AlertManager (alerting)
   - Node exporters (DaemonSet on all nodes)
   ```

4. **Additional Services**
   ```yaml
   - Redis (caching)
   - PostgreSQL (database)
   - RabbitMQ (message queue)
   - MinIO (S3-compatible storage)
   ```

### Storage

**Longhorn** - Distributed block storage for K8s
- Replicated volumes across worker nodes
- Snapshots and backups
- Web UI for management

### Networking

**CNI**: Cilium (instead of Flannel)
- Better performance
- Network policies
- Service mesh capabilities
- Observability

### Deployment via Terraform + Ansible

```hcl
# Terraform creates K8s VMs
module "k8s_cluster" {
  source = "./modules/k8s-cluster"

  master_count = 1
  worker_count = 3
  master_cpu   = 4
  master_ram   = 8192
  worker_cpu   = 4
  worker_ram   = 16384
}
```

```yaml
# Ansible installs K3s
- hosts: k8s_masters
  roles:
    - k3s-master

- hosts: k8s_workers
  roles:
    - k3s-worker
```

### Benefits

- ✅ **Higher density**: More services per VM
- ✅ **Auto-scaling**: HPA (Horizontal Pod Autoscaler)
- ✅ **Self-healing**: Automatic pod restarts
- ✅ **Rolling updates**: Zero-downtime deployments
- ✅ **Resource efficiency**: Better CPU/RAM utilization

---

## 🔀 Component 5: GoBGP (Programmable Routing)

### Purpose
Replace BIRD2 with GoBGP for API-driven, programmable BGP routing.

### Why GoBGP over BIRD2?

| Feature | BIRD2 | GoBGP |
|---------|-------|-------|
| **API** | Limited | Full gRPC/REST API |
| **Language** | C | Go (easier to extend) |
| **Configuration** | Text files | API + config file |
| **Monitoring** | birdc CLI | Prometheus metrics built-in |
| **Automation** | Manual | Programmatic |
| **Libraries** | None | Go client library |

### GoBGP Architecture

```
┌──────────────────────────────────────────────────────┐
│           Router VM (200) - GoBGP Stack              │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │ gobgpd (BGP Daemon)                            │ │
│  │ - Port 179: BGP protocol                       │ │
│  │ - Port 50051: gRPC API                         │ │
│  │ - Port 8080: REST API (optional)               │ │
│  └────────────────────────────────────────────────┘ │
│                      ↕                               │
│  ┌────────────────────────────────────────────────┐ │
│  │ GoBGP REST API Wrapper (Go service)            │ │
│  │ - Exposes REST endpoints for easy integration  │ │
│  │ - Integrates with Backstage/Vapor API          │ │
│  └────────────────────────────────────────────────┘ │
│                      ↕                               │
│  ┌────────────────────────────────────────────────┐ │
│  │ GoBGP Exporter (Prometheus)                    │ │
│  │ - Port 9100: Metrics endpoint                  │ │
│  │ - BGP session state, route counts, etc.        │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
└──────────────────────────────────────────────────────┘
              ↕
    ┌─────────────────┐
    │ Telus AS6939    │
    │ BGP Peers (3x)  │
    └─────────────────┘
```

### GoBGP Configuration

```toml
# /etc/gobgp/gobgpd.toml
[global.config]
  as = 394955
  router-id = "100.64.0.1"

# Telus Peer 1 (Primary)
[[neighbors]]
  [neighbors.config]
    neighbor-address = "2602:F674:0000::ffff"
    peer-as = 6939
    description = "Telus Gateway 1 - Primary"
  [neighbors.timers.config]
    hold-time = 90
    keepalive-interval = 30
  [neighbors.afi-safis]
    [[neighbors.afi-safis.list]]
      afi-safi-name = "ipv6-unicast"
      [neighbors.afi-safis.list.config]
        enabled = true

# Telus Peer 2 (Secondary)
[[neighbors]]
  [neighbors.config]
    neighbor-address = "2602:F674:0000::fffe"
    peer-as = 6939
    description = "Telus Gateway 2 - Secondary"
  [neighbors.afi-safis]
    [[neighbors.afi-safis.list]]
      afi-safi-name = "ipv6-unicast"

# Telus Peer 3 (Tertiary)
[[neighbors]]
  [neighbors.config]
    neighbor-address = "2602:F674:0000::fffd"
    peer-as = 6939
    description = "Telus Gateway 3 - Tertiary"
  [neighbors.afi-safis]
    [[neighbors.afi-safis.list]]
      afi-safi-name = "ipv6-unicast"
```

### API Usage Examples

**Add a route programmatically:**

```go
package main

import (
    "context"
    api "github.com/osrg/gobgp/v3/api"
    "google.golang.org/grpc"
)

func main() {
    conn, _ := grpc.Dial("192.168.100.1:50051", grpc.WithInsecure())
    defer conn.Close()

    client := api.NewGobgpApiClient(conn)

    // Announce a new prefix
    nlri := &api.IPAddressPrefix{
        PrefixLen: 48,
        Prefix:    "2602:F674::",
    }

    attrs := []*api.PathAttribute{
        api.NewOriginAttribute(0),
        api.NewNextHopAttribute("::"),
        api.NewAsPathAttribute([]uint32{394955}),
    }

    path := &api.Path{
        Nlri: api.NewAnyFromMessage(nlri),
        Pattrs: attrs,
    }

    client.AddPath(context.Background(), &api.AddPathRequest{
        Path: path,
    })
}
```

**REST API (via wrapper):**

```bash
# Get all neighbors
curl http://192.168.100.1:8080/v1/neighbors

# Get specific neighbor
curl http://192.168.100.1:8080/v1/neighbors/2602:F674:0000::ffff

# Add route
curl -X POST http://192.168.100.1:8080/v1/routes \
  -H "Content-Type: application/json" \
  -d '{
    "prefix": "2602:F674:5000::/64",
    "nexthop": "2602:F674:1000::1"
  }'
```

### Integration with AI Agent

```python
# AI Agent monitors and adjusts BGP automatically
import requests

class BGPController:
    def __init__(self, gobgp_url="http://192.168.100.1:8080"):
        self.base_url = gobgp_url

    def check_bgp_health(self):
        """Check BGP session health"""
        resp = requests.get(f"{self.base_url}/v1/neighbors")
        neighbors = resp.json()

        for neighbor in neighbors:
            if neighbor['state'] != 'established':
                self.alert(f"BGP peer {neighbor['address']} is down!")
                self.attempt_recovery(neighbor)

    def announce_prefix(self, prefix, nexthop):
        """Programmatically announce a new prefix"""
        requests.post(f"{self.base_url}/v1/routes", json={
            "prefix": prefix,
            "nexthop": nexthop
        })

    def withdraw_prefix(self, prefix):
        """Withdraw a prefix"""
        requests.delete(f"{self.base_url}/v1/routes/{prefix}")
```

### Benefits

- ✅ **API-driven**: Control BGP programmatically
- ✅ **Automation-friendly**: Easy integration with CI/CD
- ✅ **Metrics built-in**: Native Prometheus support
- ✅ **Modern codebase**: Active development, Go ecosystem
- ✅ **Flexible**: Add custom logic in Go

---

## 🔄 Complete Workflow

### Initial Deployment

```bash
# 1. Define infrastructure in Terraform
cd terraform/
terraform init
terraform plan
terraform apply

# VMs created:
# - VM 200: Router (GoBGP)
# - VM 300: AI Agent
# - VM 500: NetBox
# - VM 600-603: K8s cluster (K3s)

# 2. Configure VMs with Ansible
cd ../ansible/
ansible-playbook -i inventory/hosts.yml playbooks/site.yml

# Installs:
# - GoBGP on Router
# - NetBox on VM 500
# - K3s on cluster VMs
# - Monitoring agents everywhere

# 3. Deploy applications to K8s
cd ../k8s/
kubectl apply -f backstage/
kubectl apply -f vapor-api/
kubectl apply -f monitoring/

# 4. Configure NetBox
# - Import IP allocations
# - Sync VMs from Proxmox
# - Document network topology

# 5. Start BGP
# - GoBGP establishes sessions
# - Routes announced automatically
# - Monitoring begins
```

### Day-2 Operations

**Add a new VM:**

```bash
# 1. Define in Terraform
cat >> terraform/vms.tf << 'EOF'
module "new_app_vm" {
  source = "./modules/proxmox-vm"
  vm_id  = 700
  name   = "app-server"
  # ...
}
EOF

# 2. Apply
terraform apply

# 3. Ansible configures automatically (if in inventory)
ansible-playbook -i inventory playbooks/app-server.yml

# 4. NetBox updated automatically via API
```

**Deploy new app to K8s:**

```bash
# 1. Create Kubernetes manifest
cat > k8s/myapp/deployment.yaml

# 2. Apply
kubectl apply -f k8s/myapp/

# 3. Monitoring auto-discovers new pods
# 4. Logs aggregated automatically
```

**Modify BGP routing:**

```bash
# Option 1: Via API
curl -X POST http://192.168.100.1:8080/v1/routes \
  -d '{"prefix": "2602:F674:9000::/64", "nexthop": "..."}'

# Option 2: Via Terraform
# (if managing routes as code)
terraform apply

# Option 3: Via AI Agent
# (automatic based on conditions)
```

---

## 📊 Monitoring & Observability

### Metrics Collection

```
Prometheus scrapes:
├─ Node Exporter (all VMs) - System metrics
├─ GoBGP Exporter (Router) - BGP metrics
├─ K8s Metrics Server - Container metrics
├─ NetBox - IPAM metrics
└─ Custom exporters - Application metrics
```

### Dashboards (Grafana)

1. **Infrastructure Overview**
   - All VMs health
   - Resource utilization
   - Network throughput

2. **BGP Routing**
   - Session states
   - Route counts
   - Peer health
   - Prefix announcements

3. **Kubernetes Cluster**
   - Pod status
   - Resource requests/limits
   - Node health
   - Deployment status

4. **NetBox**
   - IP utilization
   - Prefix usage
   - Device inventory

### Alerting

```yaml
# Prometheus Alert Rules
groups:
  - name: infrastructure
    rules:
      - alert: BGPSessionDown
        expr: gobgp_peer_state != 6
        for: 5m

      - alert: VMHighCPU
        expr: node_cpu_usage > 90
        for: 10m

      - alert: K8sPodCrashLoop
        expr: kube_pod_container_status_restarts_total > 5
        for: 5m
```

---

## 🔐 Security Considerations

### Secrets Management

**Option 1: Ansible Vault**
```bash
ansible-vault encrypt group_vars/all.yml
```

**Option 2: HashiCorp Vault** (recommended)
```hcl
# Terraform reads secrets from Vault
data "vault_generic_secret" "proxmox" {
  path = "secret/proxmox"
}
```

### Access Control

- **Terraform**: State encryption, remote backend
- **Ansible**: SSH key-based auth, vault for secrets
- **NetBox**: RBAC, API tokens
- **K8s**: RBAC, network policies, Pod security standards
- **GoBGP**: API authentication, mTLS

---

## 📚 Documentation Standards

All infrastructure is documented as code:

```
docs/
├── architecture/
│   └── decisions/           # ADRs (Architecture Decision Records)
├── runbooks/
│   ├── deployment.md        # How to deploy
│   ├── disaster-recovery.md # DR procedures
│   └── troubleshooting.md   # Common issues
└── diagrams/
    ├── network-topology.png
    └── k8s-architecture.png
```

---

## 🎯 Implementation Plan

### Phase 1: Foundation (Week 1)
- [ ] Set up Terraform with Proxmox provider
- [ ] Create base VM modules
- [ ] Set up Ansible inventory and roles
- [ ] Deploy NetBox VM

### Phase 2: Routing (Week 2)
- [ ] Replace BIRD2 with GoBGP
- [ ] Create GoBGP REST API wrapper
- [ ] Test BGP sessions
- [ ] Integrate with monitoring

### Phase 3: Kubernetes (Week 3)
- [ ] Deploy K3s cluster (1 master, 3 workers)
- [ ] Set up Longhorn storage
- [ ] Install Cilium CNI
- [ ] Migrate Backstage to K8s
- [ ] Migrate Vapor API to K8s

### Phase 4: Integration (Week 4)
- [ ] Terraform ↔ NetBox integration
- [ ] Ansible dynamic inventory from NetBox
- [ ] GoBGP API integration with AI Agent
- [ ] Complete monitoring stack
- [ ] Documentation and runbooks

---

## 📈 Expected Outcomes

### Infrastructure Benefits

| Metric | Before | After |
|--------|--------|-------|
| **Deployment time** | 4-6 hours (manual) | 15 minutes (automated) |
| **VM utilization** | 40% (dedicated VMs) | 75% (K8s pods) |
| **Reproducibility** | Manual docs | 100% code-defined |
| **MTTR** | 30+ minutes | <5 minutes (auto-healing) |
| **Configuration drift** | Common | Eliminated |
| **Documentation** | Out of date | Always current (code) |

---

**Status**: Ready for implementation
**Next Steps**: Begin Phase 1 - Terraform foundation
