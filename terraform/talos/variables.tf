variable "cluster_name" {
  description = "Talos クラスタ名"
  type        = string
}

variable "talos_version" {
  description = "マシン設定の生成に使う Talos バージョン (例: v1.13.9)"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes バージョン (例: 1.36.3)"
  type        = string
}

variable "install_disk" {
  description = "Talos をインストールするディスク"
  type        = string
  default     = "/dev/sda"
}

variable "install_image" {
  description = "インストールに使うイメージ。システム拡張 (qemu-guest-agent, tailscale) を含む factory イメージを指定すること。"
  type        = string
}

variable "ts_authkey" {
  description = "tailscale の認証キー。環境変数 TF_VAR_ts_authkey 経由で設定する"
  type        = string
  ephemeral   = true
  sensitive   = true
}

variable "secrets_file" {
  description = "talosctl gen secrets で生成した secrets ファイルへのパス (ルートモジュールからの相対パス)"
  type        = string
  default     = "secrets.yaml"
}
