terraform {
  required_version = ">=1.10.3"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "=3.0.1-rc6"
    }
  }
}
