data "local_file" "ssh_private_key" {
  filename = "./ssh_private_key"
}

data "local_file" "ssh_public_key" {
  filename = "./ssh_public_key"
}

module "vm" {
  for_each = var.vm_configs
  source   = "../modules/vm"

  is_control_plane = each.value.is_control_plane

  vm_name             = each.value.vm_name
  proxmox_node        = each.value.proxmox_node
  max_vcpus           = each.value.max_vcpus
  vcpus               = each.value.vcpus
  sockets             = each.value.sockets
  memory              = each.value.memory
  desc                = each.value.vm_name
  cloud_init_template = each.value.cloud_init_template
  cloud_init_storage  = each.value.cloud_init_storage
  disks               = each.value.disks
  net_configs         = each.value.net_configs
  ipconfig0           = each.value.ipconfig0
  ipconfig1           = each.value.ipconfig1
  ipconfig2           = each.value.ipconfig2
  vm_user             = each.value.vm_user
  vm_password         = "nnaka2992@pve"
  ssh_private_key     = data.local_file.ssh_private_key.content
  ssh_public_keys     = data.local_file.ssh_public_key.content
}
