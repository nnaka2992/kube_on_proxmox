import {
  for_each = var.zones
  to       = proxmox_sdn_zone_simple.main[each.key]
  id       = each.key
}

import {
  for_each = var.zones
  to       = proxmox_sdn_vnet.main[each.key]
  id       = each.value.vnet
}

import {
  for_each = var.zones
  to       = proxmox_sdn_subnet.main[each.key]
  id       = "${each.value.vnet}/${each.key}-${replace(each.value.cidr, "/", "-")}"
}

import {
  to = proxmox_virtual_environment_firewall_rules.main
  id = "cluster"
}
