# Claude Code Integration for ORION Infrastructure

**Optimizing AI-Assisted Infrastructure Development**

---

## 🎯 Overview

This document describes how to use **Claude Code** effectively with the ORION infrastructure project, including configuration, security best practices, and recommended workflows.

---

## 📋 Table of Contents

1. [Project Configuration](#project-configuration)
2. [Security Considerations](#security-considerations)
3. [Network Configuration](#network-configuration)
4. [Third-Party Integrations](#third-party-integrations)
5. [Workflows & Best Practices](#workflows--best-practices)
6. [MCP Integration Opportunities](#mcp-integration-opportunities)
7. [Troubleshooting](#troubleshooting)

---

## 🔧 Project Configuration

### Settings File

The ORION project includes a `.claude/settings.json` configuration optimized for infrastructure development:

**Key Features:**
- ✅ **Infrastructure-aware permissions** - Pre-approved patterns for Terraform, Ansible, kubectl
- ✅ **Credential protection** - Blocks access to `.pem`, `.key`, `terraform.tfvars`, etc.
- ✅ **Git status hook** - Shows working tree status before each action
- ✅ **Sandbox enabled** - Secure command execution
- ✅ **90-day retention** - Extended chat history for complex infrastructure work

### Configuration Location

```
.claude/
├── settings.json          # Shared team settings (committed to git)
└── settings.local.json    # Your personal overrides (gitignored)
```

### Customizing Settings

Create `.claude/settings.local.json` for personal preferences:

```json
{
  "model": "opus",
  "statusLine": "🏗️ ORION | {user}@{model}",
  "permissions": {
    "defaultMode": "allow"
  }
}
```

---

## 🔐 Security Considerations

### Credential Protection

The project configuration **blocks** Claude Code from accessing:

- Private keys: `*.pem`, `*.key`, `id_rsa*`, `*.pfx`
- Terraform secrets: `terraform.tfvars`
- Environment files: `.env`, `credentials*`

**Best Practice**: Always use `terraform.tfvars.example` for documentation, never commit actual secrets.

### Dangerous Operations

These require manual approval:

```bash
# Network operations
ssh, scp, rsync

# Destructive commands
rm -rf, terraform destroy

# Disk operations (blocked entirely)
dd, mkfs, fdisk
```

### Sandbox Mode

Enabled by default for security:

```json
{
  "sandbox": {
    "enabled": true,
    "network": {
      "allowLocalBinding": true,
      "allowUnixSockets": ["/var/run/docker.sock"]
    }
  }
}
```

**What this means:**
- ✅ Bash commands run in isolated environment
- ✅ Network access controlled
- ✅ Docker socket accessible for container operations
- ✅ Prevents accidental system-wide changes

---

## 🌐 Network Configuration

### Corporate Proxy Setup

If deploying from behind a corporate firewall:

**Option 1: Environment Variables**

```bash
export HTTPS_PROXY="https://proxy.example.com:8080"
export NO_PROXY="localhost,127.0.0.1,192.168.*"
```

**Option 2: Settings File**

Add to `.claude/settings.local.json`:

```json
{
  "env": {
    "HTTPS_PROXY": "https://proxy.example.com:8080",
    "NO_PROXY": "localhost,127.0.0.1,192.168.*"
  }
}
```

### Custom SSL Certificates

For self-signed certificates or corporate CA:

```bash
export NODE_EXTRA_CA_CERTS="/path/to/corporate-ca.pem"
```

### Mutual TLS (mTLS)

For enterprises requiring client certificates:

```bash
export CLAUDE_CODE_CLIENT_CERT="/path/to/client.crt"
export CLAUDE_CODE_CLIENT_KEY="/path/to/client.key"
export CLAUDE_CODE_CLIENT_KEY_PASSPHRASE="your-passphrase"
```

### Firewall Allowlist

Ensure these domains are accessible:

```
api.anthropic.com      # Claude API
claude.ai              # Safeguards
statsig.anthropic.com  # Telemetry (optional)
sentry.io              # Error reporting (optional)
```

**Disable telemetry** if required:

```json
{
  "env": {
    "DISABLE_TELEMETRY": "1",
    "DISABLE_ERROR_REPORTING": "1"
  }
}
```

---

## 🔌 Third-Party Integrations

### Cloud Provider Options

Claude Code can route requests through enterprise infrastructure:

#### AWS Bedrock

```bash
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION="us-west-2"
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
```

**Use case**: Organizations with AWS Enterprise Support, AWS billing integration

#### Google Vertex AI

```bash
export CLAUDE_CODE_USE_VERTEX=1
export VERTEX_PROJECT_ID="your-project"
export VERTEX_REGION="us-central1"
```

**Use case**: GCP-native organizations, data residency requirements

#### Microsoft Foundry (Azure)

```bash
export CLAUDE_CODE_USE_FOUNDRY=1
export ANTHROPIC_FOUNDRY_API_KEY="your-key"
```

**Use case**: Azure-committed enterprises, Microsoft Entra ID integration

### LLM Gateway

For centralized management with budget controls:

```bash
export ANTHROPIC_BASE_URL="https://llm-gateway.example.com/v1"
export ANTHROPIC_API_KEY="gateway-api-key"
```

**Benefits**:
- Usage tracking across teams
- Budget enforcement
- Audit logging
- Rate limiting

---

## 💡 Workflows & Best Practices

### Infrastructure Development Workflow

**1. Planning Phase**

```bash
# Let Claude Code analyze the requirements
"I need to add a new VM for monitoring. Can you review the architecture and suggest the best approach?"
```

**2. Implementation Phase**

```bash
# Use TodoWrite to track multi-step tasks
"Add a Prometheus VM (ID 700) with 4 cores, 8GB RAM, and integrate it with the existing K8s cluster"
```

**3. Review Phase**

```bash
# Review changes before applying
make plan           # Terraform dry-run
git diff           # Review all changes
```

**4. Deployment Phase**

```bash
# Apply with monitoring
make apply
make verify
```

### Best Practices for AI-Assisted IaC

**DO:**
- ✅ Always review Terraform plans before applying
- ✅ Use `make plan` to preview changes
- ✅ Commit frequently with descriptive messages
- ✅ Let Claude Code generate documentation
- ✅ Use TodoWrite for complex multi-step tasks

**DON'T:**
- ❌ Blindly approve `terraform apply` without reviewing plan
- ❌ Share actual credentials with Claude Code
- ❌ Deploy to production without testing in staging
- ❌ Skip reading generated Ansible playbooks

### Effective Prompts for Infrastructure

**Good Prompts:**

```
"Add IPv6 support to the router VM and update BIRD2 configuration"
"Create an Ansible role for deploying K3s with these requirements: ..."
"Review the current Terraform state and identify resource waste"
"Generate K8s manifests for deploying Backstage with SSL via Nginx Proxy Manager"
```

**Avoid:**

```
"Fix everything"  # Too vague
"Make it work"    # No context
"Deploy stuff"    # Unclear requirements
```

---

## 🔗 MCP Integration Opportunities

### What is MCP?

**Model Context Protocol** enables Claude Code to integrate with external systems for enhanced capabilities.

### Potential MCP Integrations for ORION

#### 1. Proxmox API Integration

**Purpose**: Direct VM management via Proxmox API

```json
{
  "mcpServers": {
    "proxmox": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-proxmox"],
      "env": {
        "PROXMOX_API_URL": "https://192.168.1.100:8006/api2/json",
        "PROXMOX_API_TOKEN": "PVEAPIToken=user@pam!token=secret"
      }
    }
  }
}
```

**Capabilities**:
- List VMs and their status
- Start/stop/restart VMs
- Monitor resource usage
- Create snapshots

#### 2. NetBox IPAM Integration

**Purpose**: IP address management and network documentation

```json
{
  "mcpServers": {
    "netbox": {
      "command": "python",
      "args": ["-m", "netbox_mcp_server"],
      "env": {
        "NETBOX_URL": "http://192.168.100.50:8000",
        "NETBOX_TOKEN": "your-api-token"
      }
    }
  }
}
```

**Capabilities**:
- Query available IP addresses
- Allocate IPs for new VMs
- Update network documentation
- Track VLAN assignments

#### 3. Prometheus Metrics Integration

**Purpose**: Real-time infrastructure monitoring

```json
{
  "mcpServers": {
    "prometheus": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-prometheus"],
      "env": {
        "PROMETHEUS_URL": "http://192.168.100.60:30080"
      }
    }
  }
}
```

**Capabilities**:
- Query current resource usage
- Identify performance bottlenecks
- Trigger alerts based on metrics
- Generate capacity planning reports

#### 4. Git Repository Integration

**Purpose**: Enhanced version control workflows

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_..."
      }
    }
  }
}
```

**Capabilities**:
- Create pull requests with detailed descriptions
- Search issues and discussions
- Review code changes
- Manage project boards

### Enabling MCP Servers

**Option 1: Project-wide** (`.claude/settings.json`)

```json
{
  "enableAllProjectMcpServers": true,
  "mcpServers": {
    "proxmox": { ... },
    "netbox": { ... }
  }
}
```

**Option 2: Selective** (`.claude/settings.json`)

```json
{
  "enabledMcpjsonServers": ["proxmox", "netbox"],
  "mcpServers": { ... }
}
```

---

## 🛠️ Troubleshooting

### Issue: Permission Denied on Terraform Commands

**Symptom**: Claude Code asks permission for every `terraform` command

**Solution**: Add to `.claude/settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      {
        "tool": "Bash",
        "patterns": ["terraform.*"],
        "description": "Auto-approve Terraform commands"
      }
    ]
  }
}
```

### Issue: Cannot Access Docker Socket

**Symptom**: Docker commands fail in sandbox mode

**Solution**: Add to settings:

```json
{
  "sandbox": {
    "network": {
      "allowUnixSockets": ["/var/run/docker.sock"]
    }
  }
}
```

### Issue: Proxy Connection Failures

**Symptom**: API requests timeout or fail

**Solution**: Configure proxy with credentials:

```bash
export HTTPS_PROXY="https://username:password@proxy.example.com:8080"
export NO_PROXY="localhost,127.0.0.1,192.168.*,*.local"
```

### Issue: SSH Keys Being Blocked

**Symptom**: Cannot read SSH keys for Git operations

**Solution**: This is intentional for security. Use SSH agent instead:

```bash
ssh-add ~/.ssh/id_rsa
git config --global credential.helper store
```

### Issue: Too Many "Ask" Prompts

**Symptom**: Every Edit operation requires confirmation

**Solution**: Adjust default mode (use with caution):

```json
{
  "permissions": {
    "defaultMode": "allow"
  }
}
```

---

## 📚 Additional Resources

### Documentation

- **[ARCHITECTURE.md](../ARCHITECTURE.md)** - Complete infrastructure architecture
- **[Makefile](../Makefile)** - One-command deployment targets
- **[HELPER_SCRIPTS_INTEGRATION.md](HELPER_SCRIPTS_INTEGRATION.md)** - LXC deployment guide

### Claude Code Documentation

- **[Third-Party Integrations](https://code.claude.com/docs/en/third-party-integrations)** - Cloud providers, gateways
- **[Network Configuration](https://code.claude.com/docs/en/network-config)** - Proxy, SSL, firewall
- **[Settings Reference](https://code.claude.com/docs/en/settings)** - Complete settings documentation

### External Tools

- **[Terraform](https://www.terraform.io/)** - Infrastructure as Code
- **[Ansible](https://www.ansible.com/)** - Configuration management
- **[Proxmox VE](https://www.proxmox.com/)** - Virtualization platform
- **[NetBox](https://netbox.dev/)** - IPAM and network documentation

---

## 🎯 Quick Reference

### Essential Commands

```bash
# Show available Make targets
make help

# Plan infrastructure changes
make plan

# Deploy VMs
make apply

# Deploy AI/ML stack
make deploy-ai-stack

# Deploy complete stack
make deploy-full

# Verify deployment
make verify

# Show outputs
make outputs
```

### Configuration Files

| File | Purpose | Committed |
|------|---------|-----------|
| `.claude/settings.json` | Team-shared settings | ✅ Yes |
| `.claude/settings.local.json` | Personal overrides | ❌ No (gitignored) |
| `terraform/terraform.tfvars` | Proxmox credentials | ❌ No (gitignored) |
| `terraform/terraform.tfvars.example` | Template for credentials | ✅ Yes |

### Security Checklist

- [ ] Never commit `terraform.tfvars` with real credentials
- [ ] Review all Terraform plans before applying
- [ ] Keep sandbox mode enabled
- [ ] Use `.claude/settings.local.json` for API keys
- [ ] Enable git status hook to track changes
- [ ] Review generated Ansible playbooks before running
- [ ] Test destructive operations in dry-run mode first

---

**Last Updated**: 2025-11-22
**Status**: Active
**Maintained By**: ORION Infrastructure Team
