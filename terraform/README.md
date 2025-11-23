# ORION Terraform Infrastructure

Infrastructure as Code for the ORION Dell R730 Proxmox environment.

## 🚀 Quick Start

### Prerequisites

1. **Terraform** installed (>= 1.6.0)
   ```bash
   # Install Terraform
   wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
   unzip terraform_1.7.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **Proxmox API Token** created
   ```bash
   # On Proxmox host, create API token:
   pveum user add terraform@pam
   pveum role add TerraformRole -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Monitor VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify"
   pveum aclmod / -user terraform@pam -role TerraformRole
   pveum user token add terraform@pam terraform-token --privsep=0

   # Save the token ID and secret that are displayed
   ```

3. **Cloud-init template** in Proxmox
   ```bash
   # Create Ubuntu 24.04 cloud-init template
   # (See detailed instructions in docs/proxmox-cloud-init-template.md)
   ```

### Setup

1. **Copy and configure variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   nano terraform.tfvars

   # Update:
   # - proxmox_api_token_id
   # - proxmox_api_token_secret
   # - vm_ssh_keys
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Plan deployment:**
   ```bash
   terraform plan
   ```

4. **Apply configuration:**
   ```bash
   terraform apply
   ```

## 📁 Directory Structure

```
terraform/
├── providers.tf              # Provider configuration
├── variables.tf              # Variable definitions
├── main.tf                   # Main infrastructure (to be created)
├── outputs.tf                # Output values (to be created)
├── terraform.tfvars.example  # Example variables
├── terraform.tfvars          # Actual variables (gitignored)
├── modules/
│   ├── proxmox-vm/           # Reusable VM module (to be created)
│   ├── k8s-cluster/          # K8s cluster module (to be created)
│   └── networking/           # Network module (to be created)
└── environments/
    ├── dev/                  # Development environment
    ├── staging/              # Staging environment
    └── production/           # Production environment
```

## 🎯 What Gets Deployed

When you run `terraform apply`, the following VMs will be created:

### NetBox (VM 500)
- **Purpose**: IP Address Management and network documentation
- **Resources**: 4 cores, 8GB RAM, 100GB disk
- **IP**: 192.168.100.50
- **Services**: NetBox web UI, PostgreSQL, Redis

### Kubernetes Cluster (VMs 600-603)
- **Master** (VM 600): 4 cores, 8GB RAM
- **Workers** (VMs 601-603): 4 cores, 16GB RAM each
- **IP Range**: 192.168.100.60-63

## 🔧 Common Operations

### Check Current State
```bash
terraform show
terraform state list
```

### View Planned Changes
```bash
terraform plan
```

### Apply Changes
```bash
terraform apply

# Or auto-approve (skip confirmation)
terraform apply -auto-approve
```

### Destroy Infrastructure
```bash
# Destroy specific resource
terraform destroy -target=module.netbox_vm

# Destroy everything
terraform destroy
```

### Update a Single VM
```bash
# Taint a resource to force recreation
terraform taint module.netbox_vm.proxmox_vm_qemu.vm
terraform apply
```

### Import Existing VM
```bash
# Import an existing VM into Terraform state
terraform import module.router_vm.proxmox_vm_qemu.vm orion-pve/qemu/200
```

## 📊 Outputs

After applying, Terraform will output useful information:

```bash
terraform output

# Example outputs:
# netbox_ip = "192.168.100.50"
# netbox_url = "http://192.168.100.50:8000"
# k8s_master_ip = "192.168.100.60"
# k8s_worker_ips = ["192.168.100.61", "192.168.100.62", "192.168.100.63"]
```

## 🔐 Security

- **Never commit** `terraform.tfvars` or `*.tfstate` files
- **Use API tokens** instead of passwords
- **Encrypt state** if using remote backend
- **Limit token permissions** to minimum required

## 🐛 Troubleshooting

### "Error acquiring the state lock"
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### "Error creating VM: timeout while waiting"
```bash
# Increase timeout in provider configuration
# Or check Proxmox host resources
```

### "Template not found"
```bash
# Ensure cloud-init template exists:
qm list | grep template

# Or create it (see docs)
```

### API Token Permission Denied
```bash
# Verify token permissions:
pveum user token permissions terraform@pam terraform-token
```

## 🔄 Integration with Ansible

After Terraform creates VMs, use Ansible to configure them:

```bash
# Generate Ansible inventory from Terraform outputs
terraform output -json > ../ansible/inventory/terraform.json

# Run Ansible playbooks
cd ../ansible
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

## 📚 Next Steps

1. **Create main.tf** - Define your infrastructure
2. **Customize modules** - Tailor VM configurations
3. **Set up remote state** - Use S3 or Consul backend
4. **Integrate with CI/CD** - Automate deployments
5. **Add monitoring** - Track infrastructure changes

## 📖 Documentation

- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Main Architecture](../INFRASTRUCTURE_AS_CODE_ARCHITECTURE.md)
- [ORION Overview](../README.md)

## ⚠️ Important Notes

- Always run `terraform plan` before `apply`
- Review changes carefully before confirming
- Keep state files secure and backed up
- Test in dev environment first
- Document any manual changes outside Terraform
