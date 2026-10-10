# ipv4_addresses は mac_addresses と同じ並びのため net0 の MAC で引き当てる
output "vm_ipv4_addresses" {
  description = "VM 名 → qemu-guest-agent が報告する vmbr0 側 IPv4 アドレス"
  value = {
    for name, vm in proxmox_virtual_environment_vm.main : name => try(
      vm.ipv4_addresses[
        index([for m in vm.mac_addresses : lower(m)], lower(vm.network_device[0].mac_address))
      ][0],
      null
    )
  }
}

output "vm_kubenet_macaddrs" {
  description = "VM 名 → kubenet 側 NIC の MAC アドレス (talos の deviceSelector 用に小文字化)"
  value = {
    for name, vm in proxmox_virtual_environment_vm.main : name => lower(vm.network_device[1].mac_address)
  }
}

output "vm_kubenet_bridges" {
  description = "VM 名 → kubenet 側ブリッジ (= VNet) 名"
  value = {
    for name, vm in proxmox_virtual_environment_vm.main : name => vm.network_device[1].bridge
  }
}
