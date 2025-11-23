# Terraform Proxmox Provider Configuration
# ORION Infrastructure as Code

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9.14"
    }
  }

  # Backend configuration for state management
  # Uncomment and configure based on your needs

  # Option 1: Local backend (default)
  # backend "local" {
  #   path = "terraform.tfstate"
  # }

  # Option 2: S3-compatible backend (MinIO, AWS S3, etc.)
  # backend "s3" {
  #   bucket = "orion-terraform-state"
  #   key    = "infrastructure/terraform.tfstate"
  #   region = "us-east-1"
  #   endpoint = "https://minio.orion.local"
  #   skip_credentials_validation = true
  #   skip_metadata_api_check = true
  #   force_path_style = true
  # }

  # Option 3: Consul backend
  # backend "consul" {
  #   address = "192.168.100.1:8500"
  #   scheme  = "http"
  #   path    = "orion/terraform/state"
  # }
}

# Proxmox Provider
provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret

  # Or use username/password (less secure)
  # pm_user     = var.proxmox_user
  # pm_password = var.proxmox_password

  # TLS verification
  pm_tls_insecure = var.proxmox_tls_insecure

  # Logging
  pm_log_enable = true
  pm_log_file   = "terraform-plugin-proxmox.log"
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }

  # Timeout for API calls
  pm_timeout = 600

  # Parallel operations
  pm_parallel = 2
}
