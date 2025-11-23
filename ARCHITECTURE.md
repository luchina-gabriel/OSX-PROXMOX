# ORION Infrastructure Architecture

**Dell PowerEdge R730 - Proxmox VE Multi-Layer Infrastructure**

Version: 2.0 (Post-Refactoring)
Last Updated: 2025-11-22

---

## 🎯 Overview

ORION is a complete infrastructure stack built on a Dell R730 Proxmox VE hypervisor, designed from the ground up as an **AI-first, agent-driven architecture** with security hardening through technological obscurity ("AI Maze").

### Design Philosophy

1. **Proper Domain Separation**: Clear boundaries between Infrastructure, Platform, Applications, AI/Agent, IPAM, and Observability layers
2. **Infrastructure as Code**: Terraform for declarative VM deployment, Ansible for configuration
3. **Hybrid Approach**: VMs for infrastructure, LXC for AI/ML, Kubernetes for applications
4. **AI-First**: Built around multi-agent orchestration with proper inference layer
5. **Security Through Obscurity**: Non-standard tech stack (Swift/Vapor, Backstage) to confuse automated scanners

---

## 🏗️ Architecture Layers

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Dell R730 Proxmox VE Host                     │
│              (56 cores, 384GB RAM, dual 10GbE, iDRAC9)               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────── Layer 0: Infrastructure VMs ──────────────┐  │
│  │  VM 200: Router (BIRD2 BGP, IPv6, Firewall) - 8C/32GB        │  │
│  │  VM 300: AI Coordinator (Multi-agent orchestration) - 4C/16GB│  │
│  │  VM 500: NetBox (IPAM, network docs) - 4C/8GB                │  │
│  │  VM 600-603: K3s Cluster (1 master, 3 workers) - 4C/8-16GB   │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌───────────────── Layer 1: LXC Containers (AI/ML) ────────────┐  │
│  │  LXC 1000: Ollama (llama3, codellama, mistral)               │  │
│  │  LXC 1001: OpenWebUI (ChatGPT-like interface)                │  │
│  │  LXC 1002: LiteLLM (API gateway, OpenAI compatible)           │  │
│  │  LXC 1003: FlowiseAI (Visual agent workflow builder)          │  │
│  │  LXC 1004: PostgreSQL + pgvector (Vector DB for RAG)         │  │
│  │  LXC 1005: Redis (Caching, rate limiting)                    │  │
│  │  LXC 1006: Minio (S3-compatible storage)                     │  │
│  │  LXC 1007: Nginx Proxy Manager (Reverse proxy with SSL)      │  │
│  │  LXC 1008: Wireguard (VPN for secure remote access)          │  │
│  │  LXC 1009: N8N (Workflow automation)                         │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌────────────── Layer 2: Kubernetes Workloads (K3s) ───────────┐  │
│  │                                                                │  │
│  │  Infrastructure:                                               │  │
│  │  ├─ kube-prometheus-stack (Prometheus, Grafana, AlertManager) │  │
│  │  ├─ Cilium (CNI, network policy, eBPF)                        │  │
│  │  └─ Longhorn (Distributed block storage)                      │  │
│  │                                                                │  │
│  │  Applications:                                                 │  │
│  │  ├─ Backstage (Developer portal - "AI Maze" frontend)         │  │
│  │  └─ Vapor API (Swift middleware layer)                        │  │
│  │                                                                │  │
│  │  AI Agents:                                                    │  │
│  │  ├─ Infrastructure Agent (resource management)                │  │
│  │  ├─ Network Agent (BGP, routing, firewall)                    │  │
│  │  ├─ Security Agent (threat detection, hardening)              │  │
│  │  └─ DevOps Agent (CI/CD, deployments)                         │  │
│  │                                                                │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔌 Network Architecture

### Physical Interfaces

```
Dell R730:
├─ eno1 (10GbE) → vmbr0 (WAN - Telus Fiber)
├─ eno2 (10GbE) → vmbr1 (LAN - 192.168.100.0/24)
├─ eno3 (1GbE)  → vmbr2 (Guest - 192.168.200.0/24)
└─ iDRAC (IPMI) → 192.168.1.100/24
```

### IP Allocation

| Network Segment | CIDR | Purpose |
|----------------|------|---------|
| WAN | DHCP from Telus | Internet uplink |
| LAN | 192.168.100.0/24 | Internal services |
| Guest | 192.168.200.0/24 | Isolated guest network |
| Management | 192.168.1.0/24 | iDRAC and management |

### IPv6 BGP Routing

**AS Number**: 394955
**IPv6 Prefix**: 2602:F674::/48
**Peer**: AS6939 (Telus)

```
Subnet Allocation (2602:F674::/48):
├─ 2602:F674:0000::/64 → WAN/Transit
├─ 2602:F674:1000::/64 → LAN
├─ 2602:F674:2000::/64 → Guest
├─ 2602:F674:3000::/64 → Management
├─ 2602:F674:4000::/64 → K8s Pods
└─ 2602:F674:5000::/64 → K8s Services
```

**BGP Implementation**: BIRD2 (Phase 1) → GoBGP (Phase 2 migration)

---

## 🤖 AI/Agent Architecture (4-Layer Stack)

### Layer 0: Inference (Ollama - LXC 1000)

**Purpose**: Local LLM inference engine

- **Models**: llama3, codellama, mistral, neural-chat
- **API**: OpenAI-compatible REST API
- **Hardware**: Direct hardware access for GPU (if available)
- **Deployment**: LXC container via helper script

### Layer 1: Orchestration (LiteLLM - LXC 1002)

**Purpose**: Unified API gateway for multiple LLM backends

- **Features**:
  - OpenAI-compatible API
  - Multi-model routing
  - Rate limiting (Redis integration)
  - Caching
  - Load balancing
- **Backends**: Ollama (local), OpenAI (fallback), Anthropic (fallback)

### Layer 2: Agent Framework (K8s Pods)

**Specialized Agents**:

1. **Infrastructure Agent**
   - Resource monitoring (CPU, RAM, disk, network)
   - VM lifecycle management
   - Storage provisioning
   - Capacity planning

2. **Network Agent**
   - BGP session monitoring
   - Route optimization
   - Firewall rule management
   - Traffic analysis

3. **Security Agent**
   - Threat detection
   - Vulnerability scanning
   - Hardening recommendations
   - Compliance checking

4. **DevOps Agent**
   - CI/CD pipeline management
   - Deployment automation
   - Rollback strategies
   - Log analysis

### Layer 3: Coordinator (AI Coordinator - VM 300)

**Purpose**: Multi-agent orchestration and decision-making

- **Framework**: LangGraph for workflow orchestration
- **Capabilities**:
  - Inter-agent communication
  - Task delegation
  - Conflict resolution
  - State management
  - Human-in-the-loop approvals

---

## 🔐 "AI Maze" Security Architecture

### Concept

Use uncommon technology stack to confuse automated vulnerability scanners and bots:

1. **Backstage (Developer Portal)** - Not commonly scanned by bots
2. **Vapor (Swift Web Framework)** - Extremely rare in infrastructure
3. **Unusual Port Assignments** - Non-standard ports for services
4. **Request Routing Obfuscation** - Multi-layer proxying

### Flow

```
Internet → Nginx Proxy Manager → Backstage (Node.js)
                                       ↓
                                 Vapor API (Swift)
                                       ↓
                            Internal Services (Go, Python, Rust)
```

**Scanner Perspective**:
- Sees Backstage (JavaScript/TypeScript) - expects Node.js backend
- Actually hits Vapor (Swift) - no known exploits, confuses scanners
- By the time scanner adapts, requests are rate-limited/blocked

---

## 📦 Deployment Strategy

### Why LXC for AI/ML?

| Aspect | LXC Containers | K8s Pods | VMs |
|--------|---------------|----------|-----|
| **Deployment Time** | 5 minutes | Hours | Hours |
| **Resource Overhead** | Low | Medium | High |
| **GPU Access** | Direct | Complex | Passthrough |
| **Storage** | Persistent | Volumes | Easy |
| **Management** | Proxmox UI | kubectl | Proxmox UI |
| **Maintenance** | Community | Self | Self |

**Decision**: Use LXC containers (via tteck's helper scripts) for AI/ML stack

### Deployment Phases

#### Phase 1: Infrastructure VMs (Terraform)

```bash
make apply
```

Deploys:
- VM 200: Router
- VM 300: AI Coordinator
- VM 500: NetBox
- VM 600-603: K3s cluster

#### Phase 2: AI/ML Stack (LXC Helper Scripts)

```bash
make deploy-ai-stack
```

Provides commands to run on Proxmox host:
- LXC 1000: Ollama
- LXC 1001: OpenWebUI
- LXC 1002: LiteLLM
- LXC 1003: FlowiseAI
- LXC 1004: PostgreSQL + pgvector
- LXC 1005: Redis

#### Phase 3: Infrastructure Services (LXC)

```bash
make deploy-infrastructure
```

Deploys:
- LXC 1006: Minio
- LXC 1007: Nginx Proxy Manager
- LXC 1008: Wireguard

#### Phase 4: VM Configuration (Ansible)

```bash
make configure
```

Configures:
- Router: BIRD2, firewall, routing
- NetBox: IPAM setup
- K3s: Cluster initialization

#### Phase 5: K8s Workloads

```bash
make k8s-deploy
```

Deploys:
- Infrastructure: Prometheus, Grafana, Cilium, Longhorn
- Applications: Backstage, Vapor API
- AI Agents: All 4 specialized agents

### Complete Deployment

```bash
make deploy-full
```

Runs all phases sequentially.

---

## 📁 Repository Structure

```
luci-macOSX-PROXMOX/
├── terraform/               # Infrastructure as Code
│   ├── main.tf             # VM definitions
│   ├── variables.tf        # Variable definitions
│   ├── outputs.tf          # Output values
│   ├── providers.tf        # Proxmox provider config
│   └── terraform.tfvars    # Actual values (gitignored)
│
├── ansible/                # Configuration management
│   ├── inventory/          # Host inventory
│   ├── playbooks/          # Playbooks
│   │   ├── site.yml       # Main playbook
│   │   ├── router.yml     # Router config
│   │   ├── netbox.yml     # NetBox setup
│   │   └── k8s.yml        # K8s cluster
│   ├── group_vars/         # Group variables
│   ├── host_vars/          # Host-specific variables
│   └── roles/              # Ansible roles
│       ├── common/         # Common setup
│       ├── bird2/          # BIRD2 BGP
│       ├── gobgp/          # GoBGP (Phase 2)
│       ├── k3s-master/     # K3s master
│       ├── k3s-worker/     # K3s worker
│       ├── netbox/         # NetBox
│       └── ai-coordinator/ # AI coordinator
│
├── kubernetes/             # K8s manifests
│   ├── infrastructure/     # Core services
│   │   ├── kube-prometheus-stack/
│   │   ├── cilium/
│   │   └── longhorn/
│   ├── applications/       # Apps
│   │   ├── backstage/
│   │   └── vapor-api/
│   └── ai-agents/          # AI agents
│       ├── ollama/         # Ollama client
│       ├── litellm/        # LiteLLM client
│       └── agents/
│           ├── infrastructure/
│           ├── network/
│           ├── security/
│           └── devops/
│
├── router-configs/         # Router configurations
│   ├── bird2/             # BIRD2 configs
│   │   ├── bird.conf      # IPv4
│   │   └── bird6.conf     # IPv6
│   └── gobgp/             # GoBGP configs (Phase 2)
│
├── docs/                   # Documentation
│   ├── deployment-guide/  # Deployment docs
│   ├── ai-agent-design/   # AI agent architecture
│   ├── network-design/    # Network diagrams
│   └── reference/         # Old docs (archived)
│
├── Makefile               # One-command deployment
├── ARCHITECTURE.md        # This file
├── ARCHITECTURE_REVIEW.md # AI engineering review
├── README.md              # Project overview
└── .gitignore
```

---

## 🚀 Quick Start

### Prerequisites

1. **Dell R730** with Proxmox VE 8.x installed
2. **Terraform** >= 1.6.0
3. **Ansible** >= 2.15
4. **kubectl** (for K8s management)
5. **Proxmox API Token** created

### Deployment

```bash
# 1. Clone repository
git clone https://github.com/luci-digital/luci-macOSX-PROXMOX.git
cd luci-macOSX-PROXMOX

# 2. Configure Terraform
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
nano terraform/terraform.tfvars  # Add your Proxmox API token

# 3. Deploy everything
make deploy-full

# 4. Verify
make verify
make outputs
```

### Individual Deployments

```bash
# Deploy VMs only
make apply

# Deploy AI/ML stack only
make deploy-ai-stack

# Deploy infrastructure services only
make deploy-infrastructure

# Deploy K8s workloads only
make k8s-deploy
```

---

## 📊 Resource Allocation

| Component | CPU Cores | Memory | Disk | Network |
|-----------|-----------|--------|------|---------|
| **Router** | 8 | 32GB | 50GB | 4x virtio |
| **AI Coordinator** | 4 | 16GB | 100GB | 1x virtio |
| **NetBox** | 4 | 8GB | 100GB | 1x virtio |
| **K3s Master** | 4 | 8GB | 100GB | 1x virtio |
| **K3s Workers (×3)** | 4 each | 16GB each | 100GB each | 1x virtio |
| **LXC Containers** | Variable | Variable | Variable | Bridge |
| **Total Used** | ~40 cores | ~120GB | ~750GB | - |
| **Available** | 16 cores | 264GB | - | - |

---

## 🔄 Migration Paths

### BIRD2 → GoBGP (Phase 2)

**Why Migrate?**
- API-driven configuration (vs. config files)
- Better integration with K8s
- Programmable routing policies
- Real-time monitoring via gRPC

**Timeline**: After Phase 1 stabilization (3-6 months)

**Migration Steps**:
1. Deploy GoBGP alongside BIRD2
2. Configure GoBGP with same peering
3. Test in parallel
4. Gracefully shutdown BIRD2 sessions
5. Cutover to GoBGP
6. Monitor for 48 hours
7. Remove BIRD2

### Future Enhancements

- **GPU Passthrough**: Add NVIDIA GPU for faster LLM inference
- **HA Setup**: Proxmox cluster with second R730
- **Object Storage**: Expand Minio for backups and AI model storage
- **Monitoring**: Enhanced metrics with VictoriaMetrics
- **GitOps**: Implement ArgoCD for K8s deployments

---

## 📚 Documentation

- **[Deployment Guide](docs/deployment-guide/)** - Step-by-step instructions
- **[AI Agent Design](docs/ai-agent-design/)** - Agent architecture details
- **[Network Design](docs/network-design/)** - Network topology and routing
- **[Helper Scripts Integration](docs/HELPER_SCRIPTS_INTEGRATION.md)** - LXC deployment guide
- **[IPv6 Routing](docs/IPV6_ROUTING_INTEGRATION.md)** - BGP configuration
- **[Claude Code Integration](docs/CLAUDE_CODE_INTEGRATION.md)** - AI-assisted development setup
- **[Development Environment](docs/DEVELOPMENT_ENVIRONMENT.md)** - Zsh, Oh My Zsh, Antigen setup
- **[Architecture Review](ARCHITECTURE_REVIEW.md)** - AI engineering analysis

---

## 🔧 Operations

### Monitoring

- **Proxmox Web UI**: https://192.168.1.100:8006
- **NetBox**: http://192.168.100.50:8000
- **Grafana**: http://192.168.100.60:30080 (K8s NodePort)
- **OpenWebUI**: http://192.168.100.30:3000 (LXC 1001)
- **Backstage**: http://192.168.100.60:30000 (K8s NodePort)

### Troubleshooting

```bash
# Check Terraform state
make status

# View all outputs
make outputs

# Verify connectivity
make verify

# View Terraform plan
make plan

# SSH to VMs
ssh root@192.168.100.1   # Router
ssh root@192.168.100.30  # AI Coordinator
ssh root@192.168.100.50  # NetBox
ssh root@192.168.100.60  # K3s Master
```

---

## 🎯 Design Decisions

### Why This Architecture?

1. **VMs for Infrastructure**: Stable, proven, easy to manage
2. **LXC for AI/ML**: Lightweight, fast deployment, community-maintained scripts
3. **K8s for Applications**: Modern orchestration, perfect for stateless apps
4. **Hybrid Approach**: Right tool for the right job

### What We Eliminated

- ❌ All-in-one deployment scripts (replaced with Terraform + Makefile)
- ❌ VMs 400/401 (Backstage/Vapor moved to K8s)
- ❌ Conflicting deployment paths (single path now)
- ❌ Ambiguous documentation (consolidated)

### What We Kept

- ✅ Terraform for VMs (declarative, reproducible)
- ✅ Ansible for configuration (proven, flexible)
- ✅ BIRD2 for routing (stable, will migrate to GoBGP later)
- ✅ K3s for K8s (lightweight, perfect for single-node)
- ✅ AI-first design (multi-agent architecture)

---

## 🔐 Security Considerations

1. **Firewall**: nftables on router VM
2. **VPN**: Wireguard for remote access
3. **SSL/TLS**: Nginx Proxy Manager with Let's Encrypt
4. **Network Segmentation**: VLANs for LAN/Guest/Management
5. **API Security**: Rate limiting via LiteLLM + Redis
6. **Obscurity**: Uncommon tech stack (Vapor/Backstage)

---

## 📝 Notes

- This architecture is post-refactoring (v2.0)
- All obsolete deployment scripts removed
- Single deployment path via Makefile
- Proper domain separation established
- AI/agent architecture clearly defined
- Helper scripts integration discovered and documented

---

**Last Updated**: 2025-11-22
**Status**: Active Development
**Next Milestone**: Complete Ansible playbooks for VM configuration
