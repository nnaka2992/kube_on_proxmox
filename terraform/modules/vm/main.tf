resource "proxmox_vm_qemu" "main" {
  name             = var.vm_name
  target_node      = var.proxmox_node
  clone            = var.cloud_init_template
  agent            = 1
  bios             = "seabios"
  boot             = "order=scsi0"
  onboot           = true
  os_type          = "cloud-init"
  cores            = var.max_vcpus
  vcpus            = var.vcpus
  sockets          = var.sockets
  memory           = var.memory
  kvm              = true
  scsihw           = "virtio-scsi-pci"
  hotplug          = "network,disk,cpu"
  numa             = true
  automatic_reboot = true

  disks {
    ide {
      ide2 {
        cloudinit {
          storage = var.cloud_init_storage
        }
      }
    }
    scsi {
      scsi0 {
        dynamic disk {
          for_each = var.disks
          content {
            storage = disk.value.storage
            size    = disk.value.size
            format  = disk.value.format
          }
        }
      }
    }
  }


  dynamic network {
    for_each = var.net_configs
    content {
      id     = network.value.id
      model  = "virtio"
      bridge = network.value.bridge
    }
  }

  ipconfig0 = var.ipconfig0
  ipconfig1 = var.ipconfig1
  ipconfig2 = var.ipconfig2
  ipconfig3 = var.ipconfig3
  ipconfig4 = var.ipconfig4
  ipconfig5 = var.ipconfig5

  cicustom   = "vendor=local:snippets/cloudinit.yaml"
  ciuser     = var.vm_user
  cipassword = var.vm_password
  sshkeys    = var.ssh_public_keys

  connection {
    type        = "ssh"
    user        = self.vm_user
    private_key = self.ssh_private_key
  }

  serial {
    id   = 0
    type = "socket"
  }

  desc             = var.desc
  tags             = var.is_control_plane ? "kubernetes;terraform;control-plane" : "kubernetes;terraform;worker"

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

