variable "proxmox_uri" {
  description = "Proxmox VE API のエンドポイント (例: https://192.168.2.253:8006)"
  type        = string
}

variable "ssh_user" {
  description = "PVE ホストへの SSH ユーザー"
  type        = string
  default     = "root"
}

variable "ssh_password" {
  description = "PVE ホストへの SSH パスワード。環境変数 TF_VAR_ssh_password 経由で設定する"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "pve_nodes" {
  description = "PVE ノード名 → underlay (vmbr0) 側 IP アドレス"
  type        = map(string)
}

variable "underlay_bridge" {
  description = "underlay 側のブリッジ名。OSPF の隣接を張るインターフェイス。"
  type        = string
  default     = "vmbr0"
}

variable "underlay_cidr" {
  description = "underlay ネットワークの CIDR (OSPF の network 文)"
  type        = string
}

variable "sdn_supernet" {
  description = "SDN 全体を包含するスーパーネット。OSPF への広告・ファイアウォール・ゲスト側ルートの宛先の定義元。"
  type        = string
}

variable "ospf_area" {
  description = "OSPF エリア"
  type        = string
  default     = "0"
}

variable "zones" {
  description = "SDN Simple ゾーンの定義。ゾーン名 → 配置ノード・VNet 名 (= ゲストから見たブリッジ名)・サブネット CIDR。ゲートウェイは CIDR の先頭アドレス、DHCP レンジは 2〜254 番ホストを使う。"
  type = map(object({
    node = string
    vnet = string
    cidr = string
  }))
}

variable "assume_hosts_unchanged" {
  description = "ホスト (FRR/dnsmasq) 設定に変更が不要であると表明し、plan 時の SSH ドリフト検査をスキップする。PVE ホストに到達できないが SDN/FW など API のみの変更を適用したい場合に true。"
  type        = bool
  default     = false
}
