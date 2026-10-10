proxmox_uri = "https://192.168.2.253:8006"

pve_nodes = {
  "pve-a" = "192.168.2.253"
  "pve-b" = "192.168.2.252"
  "pve-c" = "192.168.2.251"
}

underlay_cidr = "192.168.2.0/24"
sdn_supernet  = "10.0.0.0/8"

zones = {
  "zonea" = {
    node = "pve-a"
    vnet = "pvea"
    cidr = "10.1.0.0/16"
  }
  "zoneb" = {
    node = "pve-b"
    vnet = "pveb"
    cidr = "10.2.0.0/16"
  }
  "zonec" = {
    node = "pve-c"
    vnet = "pvec"
    cidr = "10.3.0.0/16"
  }
}

