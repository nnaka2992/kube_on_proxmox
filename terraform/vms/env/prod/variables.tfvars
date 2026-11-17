proxmox_uri = "https://192.168.2.253:8006"

talos_iso = "local:iso/talos-1.13.9-amd64.iso"

vms = {
  "control-plane-a" = {
    node   = "pve-a"
    vm_id  = 107
    cores  = 2
    memory = 4096
    disk   = 100
  }
  "control-plane-b" = {
    node   = "pve-b"
    vm_id  = 105
    cores  = 2
    memory = 4096
    disk   = 100
  }
  "control-plane-c" = {
    node   = "pve-c"
    vm_id  = 104
    cores  = 2
    memory = 4096
    disk   = 100
  }
  "worker-a-1" = {
    node   = "pve-a"
    vm_id  = 102
    cores  = 6
    memory = 26624
    disk   = 300
  }
  "worker-a-2" = {
    node   = "pve-a"
    vm_id  = 100
    cores  = 6
    memory = 26624
    disk   = 300
  }
  "worker-b-1" = {
    node   = "pve-b"
    vm_id  = 103
    cores  = 6
    memory = 26624
    disk   = 300
  }
  "worker-b-2" = {
    node   = "pve-b"
    vm_id  = 106
    cores  = 6
    memory = 26624
    disk   = 300
  }
  "worker-c-1" = {
    node   = "pve-c"
    vm_id  = 101
    cores  = 14
    memory = 57220
    disk   = 300
  }
}
