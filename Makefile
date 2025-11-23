# ORION Infrastructure - One-Command Deployment
# Usage: make deploy

.PHONY: help init plan apply destroy clean status verify

# Default target
.DEFAULT_GOAL := help

##@ General

help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Setup

check-prereqs: ## Check prerequisites
	@echo "🔍 Checking prerequisites..."
	@command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform not installed"; exit 1; }
	@command -v ansible >/dev/null 2>&1 || { echo "❌ Ansible not installed"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "⚠️  kubectl not installed (optional)"; }
	@test -f terraform/terraform.tfvars || { echo "❌ terraform/terraform.tfvars not found. Copy terraform.tfvars.example"; exit 1; }
	@echo "✅ Prerequisites OK"

init: check-prereqs ## Initialize Terraform
	@echo "🏗️  Initializing Terraform..."
	@cd terraform && terraform init

##@ Deployment

plan: init ## Plan infrastructure changes
	@echo "📋 Planning infrastructure..."
	@cd terraform && terraform plan

apply: init ## Deploy infrastructure
	@echo "🚀 Deploying infrastructure..."
	@cd terraform && terraform apply
	@echo ""
	@echo "✅ Infrastructure deployed!"
	@echo "📊 Run 'make outputs' to see deployment details"

deploy: apply configure ## Full deployment: infrastructure + configuration
	@echo "🎉 ORION deployment complete!"

deploy-full: apply deploy-lxc configure k8s-deploy ## Complete deployment: VMs + LXC + Ansible + K8s
	@echo "🎉 Full ORION stack deployed!"

##@ LXC Containers (Helper Scripts)

deploy-lxc: deploy-ai-stack deploy-infrastructure ## Deploy all LXC containers
	@echo "✅ All LXC containers deployed!"

deploy-ai-stack: ## Deploy AI/ML stack (LXC containers via helper scripts)
	@echo "🤖 Deploying AI/ML stack with helper scripts..."
	@echo "📦 Installing: Ollama, OpenWebUI, LiteLLM, FlowiseAI, PostgreSQL, Redis"
	@echo ""
	@echo "⚠️  Run these commands on your Proxmox host:"
	@echo ""
	@echo "# Ollama (LLM inference)"
	@echo "bash -c \"\$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/ollama.sh)\""
	@echo ""
	@echo "# OpenWebUI (ChatGPT-like interface)"
	@echo "bash -c \"\$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/openwebui.sh)\""
	@echo ""
	@echo "# LiteLLM (API Gateway)"
	@echo "bash -c \"\$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/litellm.sh)\""
	@echo ""
	@echo "# FlowiseAI (Visual agent builder)"
	@echo "bash -c \"\$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/flowiseai.sh)\""
	@echo ""
	@echo "# PostgreSQL + pgvector (Vector DB)"
	@echo "bash -c \"\$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/postgresql.sh)\""
	@echo ""
	@echo "# Redis (Caching)"
	@echo "bash -c \"\$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/redis.sh)\""
	@echo ""
	@echo "💡 These scripts create LXC containers automatically on your Proxmox host"

deploy-infrastructure: ## Deploy infrastructure services (Minio, Nginx Proxy Manager, Wireguard)
	@echo "🏗️  Deploying infrastructure services..."
	@echo ""
	@echo "⚠️  Run these commands on your Proxmox host:"
	@echo ""
	@echo "# Minio (S3-compatible storage)"
	@echo "bash -c \"\$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/minio.sh)\""
	@echo ""
	@echo "# Nginx Proxy Manager (Reverse proxy with SSL)"
	@echo "bash -c \"\$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/nginxproxymanager.sh)\""
	@echo ""
	@echo "# Wireguard (VPN for secure remote access)"
	@echo "bash -c \"\$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/wireguard.sh)\""

deploy-dev-tools: ## Deploy development tools (Gitea, N8N)
	@echo "🛠️  Deploying development tools..."
	@echo ""
	@echo "⚠️  Run these commands on your Proxmox host:"
	@echo ""
	@echo "# Gitea (Self-hosted Git)"
	@echo "bash -c \"\$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/gitea.sh)\""
	@echo ""
	@echo "# N8N (Workflow automation)"
	@echo "bash -c \"\$$(wget -qLO - https://github.com/luci-digital/ProxmoxVE/raw/main/ct/n8n.sh)\""

##@ Configuration

configure: ## Configure VMs with Ansible
	@echo "⚙️  Configuring VMs with Ansible..."
	@echo "⚠️  Ansible playbooks need to be created first"
	@echo "📝 Next step: cd ansible && ansible-playbook -i inventory playbooks/site.yml"

##@ Kubernetes

k8s-deploy: ## Deploy Kubernetes workloads
	@echo "☸️  Deploying Kubernetes workloads..."
	@kubectl apply -k kubernetes/infrastructure/
	@kubectl apply -k kubernetes/applications/
	@kubectl apply -k kubernetes/ai-agents/

##@ Management

outputs: ## Show Terraform outputs
	@cd terraform && terraform output deployment_summary

status: ## Show infrastructure status
	@echo "📊 Infrastructure Status:"
	@cd terraform && terraform show -json | jq -r '.values.root_module.resources[] | select(.type == "proxmox_vm_qemu") | "\(.values.name) (VM \(.values.vmid)): \(.values.ipconfig0)"'

destroy: ## Destroy infrastructure (DANGEROUS!)
	@echo "⚠️  WARNING: This will destroy all infrastructure!"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read confirm
	@cd terraform && terraform destroy

clean: ## Clean Terraform state and cache
	@echo "🧹 Cleaning Terraform files..."
	@rm -rf terraform/.terraform
	@rm -f terraform/.terraform.lock.hcl
	@rm -f terraform/terraform-plugin-proxmox.log

##@ Validation

verify: ## Verify deployment
	@echo "✅ Verifying deployment..."
	@echo ""
	@echo "Checking VMs..."
	@cd terraform && terraform output k8s_master_ips
	@cd terraform && terraform output k8s_worker_ips
	@echo ""
	@echo "Testing connectivity..."
	@ping -c 1 192.168.100.1 >/dev/null 2>&1 && echo "✅ Router reachable" || echo "❌ Router not reachable"
	@ping -c 1 192.168.100.30 >/dev/null 2>&1 && echo "✅ AI Coordinator reachable" || echo "❌ AI Coordinator not reachable"
	@ping -c 1 192.168.100.50 >/dev/null 2>&1 && echo "✅ NetBox reachable" || echo "❌ NetBox not reachable"

##@ Documentation

docs: ## Generate documentation
	@echo "📚 Documentation:"
	@echo "  Architecture: ARCHITECTURE_REVIEW.md"
	@echo "  Reference: docs/reference/"
	@echo "  Terraform: terraform/README.md"

##@ Development

fmt: ## Format Terraform files
	@cd terraform && terraform fmt -recursive

validate: init ## Validate Terraform configuration
	@cd terraform && terraform validate

##@ Quick Start

quickstart: check-prereqs ## Quick start guide
	@echo "╔═══════════════════════════════════════════════════════════════╗"
	@echo "║          ORION Infrastructure - Quick Start                   ║"
	@echo "╚═══════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "1️⃣  Setup:"
	@echo "   cp terraform/terraform.tfvars.example terraform/terraform.tfvars"
	@echo "   # Edit terraform.tfvars with your Proxmox API token"
	@echo ""
	@echo "2️⃣  Deploy Infrastructure (VMs):"
	@echo "   make apply"
	@echo ""
	@echo "3️⃣  Deploy AI/ML Stack (LXC containers):"
	@echo "   make deploy-ai-stack  # See commands to run on Proxmox host"
	@echo ""
	@echo "4️⃣  Configure VMs:"
	@echo "   make configure"
	@echo ""
	@echo "5️⃣  Deploy K8s Workloads:"
	@echo "   make k8s-deploy"
	@echo ""
	@echo "6️⃣  Verify:"
	@echo "   make verify"
	@echo ""
	@echo "💡 Full deployment: make deploy-full"
	@echo "📚 Documentation: make docs"
