terraform {
  required_version = ">=1.11"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.84.0, < 1.0.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_uri
  insecure = true # 自己署名証明書のため
}
