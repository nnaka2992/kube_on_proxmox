variable "vm_name" {
  description = "コントロールプレーンをホストする VM 名"
  type        = string
}

variable "proxmox_node" {
  description = "VM をホストする Proxmox ノード名"
  type        = string
}

variable "cloud_init_template" {
  description = "クローン元のテンプレート名"
  type        = string
}

variable "max_vcpus" {
  description = "最大 vCPUs 数： 2 以上の値を指定してください。"
  type        = number
}

variable "vcpus" {
  description = "vCPUs 数： 2 以上の値を指定してください。"
  type        = number
}

variable "sockets" {
  description = "ソケット数： 1 以上の値を指定してください。"
  type        = number
  default     = 1
}

variable "memory" {
  description = "メモリ (MB)： 2048 以上の値を指定してください。"
  type        = number
}

variable "cloud_init_storage" {
  description = "cloud-init イメージを保存しているストレージ名"
  type        = string
}

variable "disks" {
  description = "VM に割り当てるディスク設定"
  type        = map(object({
    storage = string
    size    = number
    format  = string
  }))
}

variable "net_configs" {
  description = "VM に割り当てるネットワーク設定"
  type        = map(object({
    id              = number
    bridge          = string
  }))
}

variable "ipconfig0" {
  description = "VM に設定する IP アドレス: Format: '[gw=<GatewayIPv4>] [,gw6=<GatewayIPv6>] [,ip=<IPv4Format/CIDR>] [,ip6=<IPv6Format/CIDR>]'"
  type        = string
  default     = "ip=dhcp"
}

variable "ipconfig1" {
  description = "VM に設定する IP アドレス: Format: '[gw=<GatewayIPv4>] [,gw6=<GatewayIPv6>] [,ip=<IPv4Format/CIDR>] [,ip6=<IPv6Format/CIDR>]'"
  type        = string
  default     = ""
}

variable "ipconfig2" {
  description = "VM に設定する IP アドレス: Format: '[gw=<GatewayIPv4>] [,gw6=<GatewayIPv6>] [,ip=<IPv4Format/CIDR>] [,ip6=<IPv6Format/CIDR>]'"
  type        = string
  default     = ""
}

variable "ipconfig3" {
  description = "VM に設定する IP アドレス: Format: '[gw=<GatewayIPv4>] [,gw6=<GatewayIPv6>] [,ip=<IPv4Format/CIDR>] [,ip6=<IPv6Format/CIDR>]'"
  type        = string
  default     = ""
}

variable "ipconfig4" {
  description = "VM に設定する IP アドレス: Format: '[gw=<GatewayIPv4>] [,gw6=<GatewayIPv6>] [,ip=<IPv4Format/CIDR>] [,ip6=<IPv6Format/CIDR>]'"
  type        = string
  default     = ""
}

variable "ipconfig5" {
  description = "VM に設定する IP アドレス: Format: '[gw=<GatewayIPv4>] [,gw6=<GatewayIPv6>] [,ip=<IPv4Format/CIDR>] [,ip6=<IPv6Format/CIDR>]'"
  type        = string
  default     = ""
}

variable "vm_user" {
  description = "VM に設定するユーザ名"
  type        = string
}

variable "vm_password" {
  description = "VM に設定するパスワード"
  type        = string
}

variable "ssh_public_keys" {
  description = "VM に設定する SSH 公開鍵"
  type        = string
}

variable "ssh_private_key" {
  description = "VM に設定する SSH 秘密鍵"
  type        = string
}

variable "desc" {
  description = "VM の説明"
  type        = string
}

variable "is_control_plane" {
  description = "コントロールプレーンであれば true、ワーカーであれば false を指定してください。"
  type        = bool
}

