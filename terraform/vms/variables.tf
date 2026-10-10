variable "proxmox_uri" {
  description = "Proxmox VE API のエンドポイント (例: https://192.168.2.253:8006)"
  type        = string
}

variable "talos_iso" {
  description = "Talos の ISO イメージ (例: local:iso/talos-1.13.9-amd64.iso)"
  type        = string
}

variable "disk_datastore" {
  description = "VM ディスクのデータストア"
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  description = "VM ディスクのサイズ (GB)"
  type        = number
  default     = 100
}

variable "vms" {
  description = "Talos ノード VM の定義。キーが VM 名 (= Talos のホスト名)。ロールは名前から、kubenet 側ブリッジは配置ノードから導出する。"
  type = map(object({
    node   = string # 配置する PVE ノード
    vm_id  = number
    cores  = number
    memory = number # MiB
  }))

  validation {
    condition     = alltrue([for n in keys(var.vms) : can(regex("^control-plane-[a-c]$|^worker-[a-c]-[0-9]+$", n))])
    error_message = "VM 名は control-plane-<a|b|c> または worker-<a|b|c>-<番号> の形式で指定してください。"
  }
}
