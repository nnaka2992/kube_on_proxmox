resource "proxmox_vm_qemu" "resource-name" {
  name        = "test"
  target_node = "pve"

  disks {
    ide {
      ide2 {
        cdrom {
          iso = "devian-12.4.0-amd64-netinst.iso"
        }
      }
    }
  }

  ### or for a Clone VM operation
  # clone = "template to clone"

  ### or for a PXE boot VM operation
  # pxe = true
  # boot = "scsi0;net0"
  # agent = 0
}
