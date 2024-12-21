variable "vm_name" {
  description = "コントロールプレーンをホストする VM 名"
  type        = string
}

variable "proxmox_node" {
  description = "VM をホストする Proxmox ノード名"
  type        = string
}

variable "vmid" {
  description = "VM ID"
  type        = number
}

variable "memory" {
  description = "メモリ (MB)： 2048 以上の値を指定してください。"
  type        = number
}

variable "cores" {
  description = "vCPUs 数： 2 以上の値を指定してください。"
  type        = number
}

variable "is_control_plane" {
  description = "コントロールプレーンであれば true、ワーカーであれば false を指定してください。"
  type        = bool
}
