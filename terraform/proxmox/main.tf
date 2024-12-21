module "vm" {
  for_each = var.vm_configs
  source   = "../modules/vm"

  vm_name          = each.value.vm_name
  proxmox_node     = each.value.proxmox_node
  vmid             = each.value.vmid
  memory           = each.value.memory
  cores            = each.value.cores
  is_control_plane = each.value.is_control_plane
}
