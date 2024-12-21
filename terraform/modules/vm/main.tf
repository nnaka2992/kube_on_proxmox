resource "proxmox_vm_qemu" "main" {
  name        = var.vm_name
  target_node = var.proxmox_node
  vmid        = var.vmid

  onboot = true
  memory = var.memory
  cores  = var.cores

  disks {
    ide {
      ide2 {
        cdrom {
          iso = "devian-12.4.0-amd64-netinst.iso"
        }
      }
    }
  }

  tags = var.is_control_plane ? "kubernetes,terraform,control-plane" : "kubernetes,terraform,worker"
}
