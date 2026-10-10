output "vnet_cidrs" {
  description = "VNet 名 (= ゲストから見たブリッジ名) → サブネット CIDR"
  value       = { for z in var.zones : z.vnet => z.cidr }
}

output "vnet_gateways" {
  description = "VNet 名 → ゲートウェイアドレス"
  value       = { for name, z in var.zones : z.vnet => local.zone_gateways[name] }
}

output "sdn_supernet" {
  description = "SDN 全体のスーパーネット (ゲスト側ルートの宛先)"
  value       = var.sdn_supernet
}

output "pve_node_ips" {
  description = "PVE ノード名 → underlay 側 IP アドレス"
  value       = var.pve_nodes
}

output "node_vnets" {
  description = "PVE ノード名 → そのノードにローカルな VNet 名 (VM の kubenet 側ブリッジの導出に使う)"
  value       = { for z in var.zones : z.node => z.vnet }
}
