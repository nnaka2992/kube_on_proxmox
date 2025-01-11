proxmox_uri = "https://192.168.2.253:8006"

vm_configs = {
  pve_control_plane_a = {
    vm_name             = "control-plane-a"
    proxmox_node        = "pve-a"
    cloud_init_template = "debian-12-cloud-init"
    max_vcpus           = 4
    vcpus               = 4
    sockets             = 1
    memory              = 6144 # 6 GB
    cloud_init_storage  = "local-lvm"
    disks               = {
      "disk0" = {
        storage = "local-lvm"
        size    = 100 # 100 GB
        format  = "raw"
      }
    }
    net_configs         = {
      "local" = {
        id = 0
        bridge = "vmbr0"
      }
      "kubenet" = {
        id = 1
        bridge = "kubenet"
      }
    }
    ipconfig0           = "ip=dhcp"
    ipconfig1           = "ip=10.1.1.1/24"
    vm_user             = "debian"
    is_control_plane    = true
  }
#  pve_control_plane_b = {
#    vm_name             = "control-plane-b"
#    proxmox_node        = "pve-b"
#    cloud_init_template = "debian-12-cloud-init"
#    max_vcpus           = 4
#    vcpus               = 4
#    sockets             = 1
#    memory              = 6144 # 6 GB
#    cloud_init_storage  = "local-lvm"
#    disks               = {
#      "disk0" = {
#        storage = "local-lvm"
#        size    = 100 # 100 GB
#        format  = "raw"
#      }
#    }
#    net_configs         = {
#      "local" = {
#        id = 0
#        bridge = "vmbr0"
#      }
#      "kubenet" = {
#        id = 1
#        bridge = "kubenet"
#      }
#    }
#    ipconfig0           = "ip=dhcp"
#    ipconfig1           = "ip=dhcp"
#    vm_user             = "debian"
#    is_control_plane    = true
#  }
  pve_worker_a_1 = {
    vm_name             = "worker-a-1"
    proxmox_node        = "pve-a"
    cloud_init_template = "debian-12-cloud-init"
    max_vcpus           = 6
    vcpus               = 6
    sockets             = 1
    memory              = 26624 # 26 GB
    cloud_init_storage  = "local-lvm"
    disks               = {
      "disk0" = {
        storage = "local-lvm"
        size    = 250 # 100 GB
        format  = "raw"
      }
    }
    net_configs         = {
      "local" = {
        id = 0
        bridge = "vmbr0"
      }
      "kubenet" = {
        id = 1
        bridge = "kubenet"
      }
    }
    ipconfig0           = "ip=dhcp"
    ipconfig1           = "ip=10.1.1.11/24"
    vm_user             = "debian"
    is_control_plane    = false
  }
  pve_worker_a_2 = {
    vm_name             = "worker-a-2"
    proxmox_node        = "pve-a"
    cloud_init_template = "debian-12-cloud-init"
    max_vcpus           = 6
    vcpus               = 6
    sockets             = 1
    memory              = 26624 # 26 GB
    cloud_init_storage  = "local-lvm"
    disks               = {
      "disk0" = {
        storage = "local-lvm"
        size    = 250 # 100 GB
        format  = "raw"
      }
    }
    net_configs         = {
      "local" = {
        id = 0
        bridge = "vmbr0"
      }
      "kubenet" = {
        id = 1
        bridge = "kubenet"
      }
    }
    ipconfig0           = "ip=dhcp"
    ipconfig1           = "ip=10.1.1.12/24"
    vm_user             = "debian"
    is_control_plane    = false
  }
  pve_worker_b_1 = {
    vm_name             = "worker-b-1"
    proxmox_node        = "pve-b"
    cloud_init_template = "debian-12-cloud-init"
    max_vcpus           = 6
    vcpus               = 6
    sockets             = 1
    memory              = 26624 # 26 GB
    cloud_init_storage  = "local-lvm"
    disks               = {
      "disk0" = {
        storage = "local-lvm"
        size    = 250 # 100 GB
        format  = "raw"
      }
    }
    net_configs         = {
      "local" = {
        id = 0
        bridge = "vmbr0"
      }
      "kubenet" = {
        id = 1
        bridge = "kubenet"
      }
    }
    ipconfig0           = "ip=dhcp"
    ipconfig1           = "ip=10.1.1.13/24"
    vm_user             = "debian"
    is_control_plane    = false
  }
  pve_worker_b_2 = {
    vm_name             = "worker-b-2"
    proxmox_node        = "pve-b"
    cloud_init_template = "debian-12-cloud-init"
    max_vcpus           = 6
    vcpus               = 6
    sockets             = 1
    memory              = 26624 # 26 GB
    cloud_init_storage  = "local-lvm"
    disks               = {
      "disk0" = {
        storage = "local-lvm"
        size    = 250 # 100 GB
        format  = "raw"
      }
    }
    net_configs         = {
      "local" = {
        id = 0
        bridge = "vmbr0"
      }
      "kubenet" = {
        id = 1
        bridge = "kubenet"
      }
    }
    ipconfig0           = "ip=dhcp"
    ipconfig1           = "ip=10.1.1.14/24"
    vm_user             = "debian"
    is_control_plane    = false
  }
}
