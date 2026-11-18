cluster_name       = "my-cluster"
talos_version      = "v1.13.9"
kubernetes_version = "1.36.3"

install_image = {
  # qemu-guest-agent + tailscale
  controlplane = "factory.talos.dev/installer/7d4c31cbd96db9f90c874990697c523482b2bae27fb4631d5583dcd9c281b1ff:v1.13.9"
  # 上記 + kata-containers
  worker = "factory.talos.dev/installer/a3f29a65dfd32b73c76f14eef96ef7588cf08c7d737d24fae9b8216d1ffa5c3d:v1.13.9"
}
