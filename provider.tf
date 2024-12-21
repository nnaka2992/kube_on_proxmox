terraform {
  required_version  = ">=1.10.3"
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "=3.0.1-rc6"
    }
  }
}

provider "proxmox" {
  pm_api_url = "${var.proxmox_uri}/api2/json"
  pm_tls_insecure = true # By default Proxmox Virtual Environment uses self-signed certificates.
}
