data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "${path.root}/../network/terraform.tfstate"
  }
}

locals {
  node_vnets = data.terraform_remote_state.network.outputs.node_vnets

  # タグは PVE が保持するソート順に合わせる
  vm_tags = {
    for name in keys(var.vms) : name => (
      startswith(name, "control-plane")
      ? ["control-plane", "kubernetes", "terraform"]
      : ["kubernetes", "terraform", "worker"]
    )
  }
}

resource "proxmox_virtual_environment_vm" "main" {
  for_each = var.vms

  node_name   = each.value.node
  vm_id       = each.value.vm_id
  name        = each.key
  description = each.key
  tags        = local.vm_tags[each.key]

  on_boot    = true
  bios       = "seabios"
  boot_order = ["scsi0", "ide2"]
  # true にすると pending な変更で全台並列再起動になり etcd のクォーラムを失う
  reboot_after_update = false
  scsi_hardware       = "virtio-scsi-pci"
  kvm_arguments       = "-cpu host,+invtsc"

  cpu {
    cores   = each.value.cores
    sockets = 1
    type    = "host"
    numa    = true
    # PVE の vcpus 行に対応
    hotplugged = each.value.cores
  }

  memory {
    dedicated = each.value.memory
    floating  = 0 # balloon 無効
  }

  agent {
    enabled = true
  }

  operating_system {
    type = "other"
  }

  disk {
    interface    = "scsi0"
    datastore_id = var.disk_datastore
    size         = var.disk_size
    file_format  = "raw"
    replicate    = false
  }

  # ディスクが空の初回起動時は ide2 (Talos ISO) へフォールバックする
  cdrom {
    interface = "ide2"
    file_id   = var.talos_iso
  }

  serial_device {
    device = "socket"
  }

  # MAC は宣言しない。Proxmox 生成値を outputs 経由で talos の deviceSelector に流す
  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  network_device {
    bridge = local.node_vnets[each.value.node]
    model  = "virtio"
  }
}
