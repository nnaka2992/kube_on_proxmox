import {
  for_each = var.vms
  to       = proxmox_virtual_environment_vm.main[each.key]
  id       = "${each.value.node}/${each.value.vm_id}"
}
