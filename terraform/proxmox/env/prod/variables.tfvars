proxmox_uri = "https://192.168.2.253:8006"

vm_configs = {
  pve_control_plane_1 = {
    vm_name          = "control-plane-1"
    proxmox_node     = "pve"
    vmid             = 101
    memory           = 2048
    cores            = 2
    is_control_plane = true
  }
  pve_worker_1 = {
    vm_name          = "worker-1"
    proxmox_node     = "pve"
    vmid             = 111
    memory           = 20480
    cores            = 4
    is_control_plane = false
  }
  pve_worker_2 = {
    vm_name          = "worker-2"
    proxmox_node     = "pve"
    vmid             = 112
    memory           = 20480
    cores            = 4
    is_control_plane = false
  }
  pve_worker_3 = {
    vm_name          = "worker-3"
    proxmox_node     = "pve"
    vmid             = 113
    memory           = 20480
    cores            = 4
    is_control_plane = false
  }
}
