variable "proxmox_uri" {
  description = "Proxmox VE API の URI"
  type        = string
}

variable "vm_configs" {
  description = "VM の設定"
  type = map(object({
    vm_name          = string
    proxmox_node     = string
    vmid             = number
    memory           = number
    cores            = number
    is_control_plane = bool
  }))
}
