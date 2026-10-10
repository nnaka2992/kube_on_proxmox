terraform {
  # ephemeral resource と write-only 引数のため 1.11 以上が必要
  required_version = ">=1.11"
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "= 0.11.0"
    }
  }
}
