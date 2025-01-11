variable "proxmox_uri" {
  description = "Proxmox VE API の URI"
  type        = string
}

variable "vm_configs" {
  description = "VM の設定"
  type = map(object({
    is_control_plane    = bool
    vm_name             = string
    proxmox_node        = string
    max_vcpus           = number
    vcpus               = number
    sockets             = number
    memory              = number
    cloud_init_template = string
    cloud_init_storage  = string
    net_configs         = map(object({
      id     = number
      bridge = string
    }))
    disks = map(object({
      storage = string
      size    = number
      format  = string
    }))
    ipconfig0           = optional(string)
    ipconfig1           = optional(string)
    ipconfig2           = optional(string)
    ipconfig3           = optional(string)
    ipconfig4           = optional(string)
    ipconfig5           = optional(string)
    vm_user             = string
  }))
}
