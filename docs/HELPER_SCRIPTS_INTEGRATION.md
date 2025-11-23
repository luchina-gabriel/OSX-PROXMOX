# ProxmoxVE Helper-Scripts Integration Plan for ORION

**Source**: https://github.com/luci-digital/ProxmoxVE (tteck's helper-scripts)
**Total Scripts**: 396 automation scripts for Proxmox LXC containers

---

## 🎯 Critical Integrations for ORION

### ⭐ **Tier 1: MUST INTEGRATE (AI/ML Stack)**

These align PERFECTLY with our AI/agent architecture:

| Script | Purpose | ORION Integration |
|--------|---------|-------------------|
| **Ollama** | Local LLM inference (llama3, codellama, mistral) | ✅ Already planned - use this script! |
| **OpenWebUI** | Web UI for Ollama (ChatGPT-like interface) | ⭐ NEW - Add to K8s AI agents |
| **LiteLLM** | Unified LLM API gateway (OpenAI compatible) | ✅ Already planned - use this script! |
| **FlowiseAI** | Visual AI agent workflow builder (drag & drop) | ⭐ NEW - Better than coding LangGraph! |
| **ComfyUI** | AI image generation (Stable Diffusion) | Optional - if needed |

**Impact**: Instead of manually configuring Ollama + LiteLLM, **use these one-line installers!**

---

### ⭐ **Tier 2: HIGHLY RECOMMENDED (Infrastructure)**

| Script | Purpose | ORION Benefit |
|--------|---------|---------------|
| **PostgreSQL** | Database for NetBox, AI agents, embeddings | ✅ Essential for pgvector |
| **Redis** | Caching, rate limiting, session storage | ✅ Essential for LiteLLM |
| **Minio** | S3-compatible object storage | ⭐ Store AI model files, backups |
| **VictoriaMetrics** | Faster Prometheus alternative | Optional upgrade |
| **Wireguard** | VPN for secure remote access | ⭐ Secure access to ORION |
| **Nginx Proxy Manager** | Easy reverse proxy with SSL | ⭐ Simpler than raw nginx |
| **N8N** | Workflow automation (alternative to LangChain) | ⭐ Visual agent orchestration |

---

### ⭐ **Tier 3: USEFUL ADDITIONS**

| Script | Purpose | Use Case |
|--------|---------|----------|
| **Gitea/Forgejo** | Self-hosted Git | Store infrastructure code |
| **Headscale** | Self-hosted Tailscale | Mesh VPN for all devices |
| **Node-RED** | Visual flow programming | Alternative agent orchestration |
| **Traefik** | Modern ingress controller | K8s ingress (already planned) |
| **Unbound** | DNS resolver | Already planned for router |
| **Beszel** | Modern monitoring | Alternative to Prometheus |

---

## 🚀 Recommended Integration Strategy

### **Phase 1: AI/ML Stack (Immediate)**

Replace manual Ollama/LiteLLM setup with helper scripts:

```bash
# Instead of building from scratch, use helper scripts:

# 1. Ollama LXC Container
bash -c "$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/ollama.sh)"

# 2. OpenWebUI (ChatGPT-like interface for Ollama)
bash -c "$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/openwebui.sh)"

# 3. LiteLLM (API Gateway)
bash -c "$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/litellm.sh)"

# 4. FlowiseAI (Visual agent builder)
bash -c "$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/flowiseai.sh)"

# 5. PostgreSQL + pgvector (Vector DB for RAG)
bash -c "$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/postgresql.sh)"

# 6. Redis (Caching)
bash -c "$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/redis.sh)"
```

**Result**: Full AI stack in **5 minutes** instead of hours of manual configuration!

---

### **Phase 2: Infrastructure Services**

```bash
# Minio (S3-compatible storage for AI models)
bash -c "$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/minio.sh)"

# Nginx Proxy Manager (Easy reverse proxy with SSL)
bash -c "$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/nginxproxymanager.sh)"

# Wireguard (VPN for secure remote access)
bash -c "$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/wireguard.sh)"
```

---

### **Phase 3: Development Tools**

```bash
# Gitea (Self-hosted Git for infrastructure code)
bash -c "$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/gitea.sh)"

# N8N (Workflow automation - alternative to LangChain)
bash -c "$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/n8n.sh)"
```

---

## 🎯 Updated ORION Architecture with Helper Scripts

```
┌─────────────────────────────────────────────────────────────┐
│              Dell R730 - Proxmox VE Layer                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Infrastructure VMs (Terraform):                             │
│  ├─ VM 200: Router (BIRD2/GoBGP)                            │
│  ├─ VM 300: AI Coordinator                                  │
│  ├─ VM 500: NetBox                                          │
│  └─ VM 600-603: K8s Cluster                                 │
│                                                              │
│  LXC Containers (Helper Scripts): ⭐ NEW                     │
│  ├─ LXC 1000: Ollama (LLM inference)                        │
│  ├─ LXC 1001: OpenWebUI (ChatGPT-like interface)            │
│  ├─ LXC 1002: LiteLLM (API gateway)                         │
│  ├─ LXC 1003: FlowiseAI (Visual agent builder)              │
│  ├─ LXC 1004: PostgreSQL + pgvector                         │
│  ├─ LXC 1005: Redis                                         │
│  ├─ LXC 1006: Minio (S3 storage)                            │
│  ├─ LXC 1007: Nginx Proxy Manager                           │
│  ├─ LXC 1008: Wireguard VPN                                 │
│  └─ LXC 1009: N8N (Workflow automation)                     │
│                                                              │
│  K8s Workloads:                                              │
│  ├─ Backstage (developer portal)                            │
│  ├─ Vapor API (Swift middleware)                            │
│  └─ Monitoring (Prometheus/Grafana)                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 💡 Key Insights

### **Why Use LXC Containers Instead of K8s Pods for AI?**

**LXC Containers (via helper scripts):**
- ✅ **5 minutes to deploy** (one command)
- ✅ **Lighter weight** than VMs
- ✅ **Direct hardware access** (GPUs, if needed)
- ✅ **Persistent storage** (no K8s volume complexity)
- ✅ **Easy management** (Proxmox UI)
- ✅ **Proven configurations** (tteck's 396 scripts)

**K8s Pods:**
- ❌ More complex setup
- ❌ Overhead for orchestration
- ❌ Volume management complexity
- ✅ Good for stateless apps (Backstage, Vapor API)

**Recommendation**:
- **AI/ML stack**: Use LXC containers (helper scripts)
- **Applications**: Use K8s pods
- **Infrastructure**: Use VMs (Terraform)

---

## 🚀 Revised Deployment Strategy

### **Before (Complex)**:
```
1. Terraform creates VMs
2. Ansible configures everything
3. Manually build Ollama container
4. Manually configure LiteLLM
5. Write custom Kubernetes manifests
6. Debug volume mounts
7. Fight with networking
```

### **After (Simple)** ⭐:
```
1. Terraform creates infrastructure VMs
2. Helper scripts create AI LXC containers (5 min)
3. Ansible configures VMs only
4. K8s manifests for apps (simple)
5. Everything just works!
```

---

## 📋 Action Items

### **Immediate:**
1. ✅ Add helper-scripts integration to Makefile
2. ✅ Create LXC deployment phase
3. ✅ Update architecture docs

### **Scripts to Integrate First:**

```bash
# Add to Makefile:

deploy-ai-stack:
	@echo "🤖 Deploying AI/ML stack with helper scripts..."
	@bash -c "$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/ollama.sh)"
	@bash -c "$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/openwebui.sh)"
	@bash -c "$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/litellm.sh)"
	@bash -c "$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/flowiseai.sh)"
	@bash -c "$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/postgresql.sh)"
	@bash -c "$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/redis.sh)"
	@echo "✅ AI stack deployed!"

deploy-infrastructure:
	@bash -c "$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/minio.sh)"
	@bash -c "$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/nginxproxymanager.sh)"
	@bash -c "$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/wireguard.sh)"
```

---

## 🎉 Benefits

| Aspect | Before | After (with helper-scripts) |
|--------|--------|----------------------------|
| **AI Stack Setup Time** | 4-6 hours manual | **5 minutes automated** |
| **Configuration Complexity** | High (custom K8s manifests) | **Low (proven scripts)** |
| **Maintenance** | Custom (we maintain) | **Community maintained** |
| **Resource Usage** | K8s overhead | **LXC lightweight** |
| **GPU Access** | Complex passthrough | **Direct access** |
| **Total Scripts Available** | 0 | **396 ready to use** |

---

## ✅ Recommendation

**INTEGRATE THE HELPER SCRIPTS!**

They solve 90% of the AI/ML infrastructure automation we were planning to build manually. This is a massive time saver!

**Next Step**: Want me to integrate these into the Makefile and update the architecture?
