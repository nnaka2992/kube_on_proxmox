locals {
  zone_gateways    = { for name, z in var.zones : name => cidrhost(z.cidr, 1) }
  zone_dhcp_starts = { for name, z in var.zones : name => cidrhost(z.cidr, 2) }
  zone_dhcp_ends   = { for name, z in var.zones : name => cidrhost(z.cidr, 254) }

  max_prefix_len = max([for z in var.zones : tonumber(split("/", z.cidr)[1])]...)
}

resource "proxmox_sdn_zone_simple" "main" {
  for_each = var.zones

  id    = each.key
  nodes = [each.value.node]
  dhcp  = "dnsmasq"
  ipam  = "pve"
}

resource "proxmox_sdn_vnet" "main" {
  for_each = var.zones

  id   = each.value.vnet
  zone = proxmox_sdn_zone_simple.main[each.key].id
}

resource "proxmox_sdn_subnet" "main" {
  for_each = var.zones

  vnet    = proxmox_sdn_vnet.main[each.key].id
  cidr    = each.value.cidr
  gateway = local.zone_gateways[each.key]
  dhcp_range = {
    start_address = local.zone_dhcp_starts[each.key]
    end_address   = local.zone_dhcp_ends[each.key]
  }
}

# SDN の変更は applier の作り直しで適用が確定する
resource "proxmox_sdn_applier" "main" {
  depends_on = [proxmox_sdn_subnet.main]

  lifecycle {
    replace_triggered_by = [
      proxmox_sdn_zone_simple.main,
      proxmox_sdn_vnet.main,
      proxmox_sdn_subnet.main,
    ]
  }
}

# オプション (enable) は宣言するとプロバイダデフォルトのポリシーを書き込むため管理しない
resource "proxmox_virtual_environment_firewall_rules" "main" {
  # node_name / vm_id を指定しない場合はクラスタレベル

  rule {
    type    = "in"
    action  = "ACCEPT"
    macro   = "OSPF"
    source  = var.underlay_cidr
    comment = "ospf between pve nodes"
  }

  rule {
    type    = "in"
    action  = "ACCEPT"
    macro   = "DHCPfwd"
    comment = "sdn dhcp"
  }

  rule {
    type    = "in"
    action  = "ACCEPT"
    dest    = var.sdn_supernet
    proto   = "udp"
    dport   = "53"
    comment = "sdn dns"
  }

  rule {
    type    = "in"
    action  = "ACCEPT"
    dest    = var.sdn_supernet
    proto   = "tcp"
    dport   = "53"
    comment = "sdn dns"
  }

  rule {
    type    = "in"
    action  = "ACCEPT"
    source  = var.sdn_supernet
    dest    = var.sdn_supernet
    comment = "sdn inter-subnet"
  }

  # 以下 2 つは手動管理時代の無効化済みルール。import の整合のため保持。
  rule {
    enabled = false
    type    = "in"
    action  = "ACCEPT"
    macro   = "DNS"
    iface   = var.underlay_bridge
    dest    = "192.168.2.1"
    log     = "nolog"
    comment = "Allow dhcp traffic for local network"
  }

  rule {
    enabled = false
    type    = "in"
    action  = "ACCEPT"
    macro   = "DHCPfwd"
    iface   = var.underlay_bridge
    log     = "nolog"
    comment = "Allow dhcp traffic for local network"
  }
}

locals {
  frr_conf = {
    for node, ip in var.pve_nodes : node => templatefile("${path.module}/templates/frr.conf.tftpl", {
      hostname        = node
      router_id       = ip
      underlay_bridge = var.underlay_bridge
      underlay_cidr   = var.underlay_cidr
      ospf_area       = var.ospf_area
      sdn_supernet    = var.sdn_supernet
      max_prefix_len  = local.max_prefix_len
    })
  }
}

data "external" "host_drift" {
  for_each = var.pve_nodes

  program = ["bash", "${path.module}/scripts/check_drift.sh"]
  query = {
    host     = each.value
    ssh_user = var.ssh_user
    desired  = sha256(local.frr_conf[each.key])
    enabled  = tostring(!var.assume_hosts_unchanged)
  }
}

check "host_drift_check_enabled" {
  assert {
    condition     = !var.assume_hosts_unchanged
    error_message = "assume_hosts_unchanged が有効 — ホストのドリフト検査はスキップされています。"
  }
}

resource "terraform_data" "host" {
  for_each = var.pve_nodes

  triggers_replace = {
    desired = sha256(local.frr_conf[each.key])
    drift   = data.external.host_drift[each.key].result.drift
  }

  connection {
    type     = "ssh"
    host     = each.value
    user     = var.ssh_user
    password = var.ssh_password
  }

  provisioner "file" {
    content     = local.frr_conf[each.key]
    destination = "/etc/frr/frr.conf.tf-staged"
  }

  provisioner "remote-exec" {
    inline = [
      "set -eu",
      "dpkg -s frr frr-pythontools dnsmasq >/dev/null 2>&1 || { apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq frr frr-pythontools dnsmasq; }",
      "systemctl disable --now dnsmasq >/dev/null 2>&1 || true",
      "printf 'net.ipv4.ip_forward=1\\n' > /etc/sysctl.d/90-sdn-routing.conf && sysctl -q -p /etc/sysctl.d/90-sdn-routing.conf",
      "changed=0",
      "grep -q '^ospfd=yes' /etc/frr/daemons || { sed -i 's/^ospfd=no/ospfd=yes/' /etc/frr/daemons && changed=1; }",
      "cmp -s /etc/frr/frr.conf.tf-staged /etc/frr/frr.conf || { install -o frr -g frr -m 640 /etc/frr/frr.conf.tf-staged /etc/frr/frr.conf && changed=1; }",
      "rm -f /etc/frr/frr.conf.tf-staged",
      "[ \"$changed\" = 0 ] || systemctl reload-or-restart frr",
    ]
  }
}
