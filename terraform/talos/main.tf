# クラスタの秘密鍵一式。
# Terraform では生成せず、talosctl gen secrets で生成したファイルを読み込む。
locals {
  secrets = yamldecode(file("${path.root}/${var.secrets_file}"))

  # talosctl gen secrets の出力をプロバイダの machine_secrets 形式に変換する
  machine_secrets = {
    cluster    = local.secrets.cluster
    trustdinfo = local.secrets.trustdinfo
    secrets = {
      bootstrap_token             = local.secrets.secrets.bootstraptoken
      secretbox_encryption_secret = local.secrets.secrets.secretboxencryptionsecret
    }
    certs = {
      etcd = {
        cert = local.secrets.certs.etcd.crt
        key  = local.secrets.certs.etcd.key
      }
      k8s = {
        cert = local.secrets.certs.k8s.crt
        key  = local.secrets.certs.k8s.key
      }
      k8s_aggregator = {
        cert = local.secrets.certs.k8saggregator.crt
        key  = local.secrets.certs.k8saggregator.key
      }
      k8s_serviceaccount = {
        key = local.secrets.certs.k8sserviceaccount.key
      }
      os = {
        cert = local.secrets.certs.os.crt
        key  = local.secrets.certs.os.key
      }
    }
  }
}

# Talos API のクライアント認証情報 (旧 talosconfig)
ephemeral "talos_client_configuration" "main" {
  cluster_name    = var.cluster_name
  machine_secrets = local.machine_secrets
}

data "terraform_remote_state" "vms" {
  backend = "local"
  config = {
    path = "${path.root}/../vms/terraform.tfstate"
  }
}

data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "${path.root}/../network/terraform.tfstate"
  }
}

locals {
  node_ips             = data.terraform_remote_state.vms.outputs.vm_ipv4_addresses
  node_kubenet_macs    = data.terraform_remote_state.vms.outputs.vm_kubenet_macaddrs
  node_kubenet_bridges = data.terraform_remote_state.vms.outputs.vm_kubenet_bridges
  vnet_cidrs           = data.terraform_remote_state.network.outputs.vnet_cidrs
  sdn_supernet         = data.terraform_remote_state.network.outputs.sdn_supernet

  nodes = keys(local.node_kubenet_macs)

  node_machine_types = {
    for name in local.nodes :
    name => startswith(name, "control-plane") ? "controlplane" : "worker"
  }

  node_kubenet_subnets = {
    for name in local.nodes :
    name => local.vnet_cidrs[local.node_kubenet_bridges[name]]
  }

  kubelet_subnets = sort(distinct(values(local.vnet_cidrs)))

  controlplane_ips = [
    for name in sort(local.nodes) : local.node_ips[name]
    if local.node_machine_types[name] == "controlplane"
  ]
  bootstrap_ip = local.controlplane_ips[0]

  # Kubernetes API のエンドポイント。先頭のコントロールプレーンの IP を参照する。
  cluster_endpoint = "https://${local.bootstrap_ip}:6443"

  # ServiceAccount トークンの issuer。Talos の既定はエンドポイント (IP なので
  # 変わりうる) のため、自分のドメインの名前に移す。外の DNS には登録しない:
  # 鍵を取りに来るのはクラスタ内の Substrate だけで、mykube の hostAliases で
  # kubernetes Service に向けている。Google の Workload Identity Federation は
  # 公開鍵をアップロードして使う。
  sa_issuer = "https://kube.nnaka2992.dev"
  # kube-apiserver は先頭の issuer でトークンを発行し、すべてを受け付ける。
  # 移行の 1 段目: 発行は今のまま、新しい issuer も受け付ける。
  sa_issuers = [local.cluster_endpoint, local.sa_issuer]
}

# 共通パッチ
locals {
  # Agent Substrate の podCertificate / clusterTrustBundle projected volume に必要。v1.36 では既定で無効
  feature_gates = join(",", [
    "ClusterTrustBundle=true",
    "ClusterTrustBundleProjection=true",
    "PodCertificateRequest=true",
  ])

  # 全ノード共通: kubelet が InternalIP として kubenet 側のアドレスを選ぶようにする
  common_patch = yamlencode({
    machine = {
      kubelet = {
        extraArgs = {
          feature-gates = local.feature_gates
        }
        nodeIP = {
          validSubnets = local.kubelet_subnets
        }
      }
    }
  })

  # コントロールプレーンのみ: etcd のピア通信を kubenet 側に限定する
  controlplane_patch = yamlencode({
    cluster = {
      apiServer = {
        # issuer の名前で API サーバに届くように (Substrate の OIDC discovery)
        certSANs = ["kube.nnaka2992.dev"]
        extraArgs = {
          feature-gates  = local.feature_gates
          runtime-config = "certificates.k8s.io/v1beta1=true"
          # 値を並べると同じフラグが順に繰り返される (Talos 1.13)。既定値は置き換わる。
          service-account-issuer = local.sa_issuers
          # 既定はエンドポイント。issuer を変えても既存トークンの宛先は同じに保つ
          api-audiences = local.cluster_endpoint
        }
      }
      controllerManager = {
        extraArgs = {
          feature-gates = local.feature_gates
        }
      }
      scheduler = {
        extraArgs = {
          feature-gates = local.feature_gates
        }
      }
      etcd = {
        advertisedSubnets = local.kubelet_subnets
      }
    }
  })

  # ワーカーのみ: kubelet はコンテナ内で動くため、local-path-provisioner の
  # ホストパスを伝搬させないと subPath 解決時に空ディレクトリを作ってしまう
  worker_patch = yamlencode({
    machine = {
      sysctls = {
        "user.max_user_namespaces" = "11255"
      }
      kubelet = {
        extraMounts = [
          {
            destination = "/var/local-path-provisioner"
            type        = "bind"
            source      = "/var/local-path-provisioner"
            options     = ["bind", "rshared", "rw"]
          }
        ]
      }
    }
  })
}

# ノードごとのマシン設定の生成 (旧 talosctl gen config + 各パッチ)。
ephemeral "talos_machine_configuration" "main" {
  for_each = toset(local.nodes)

  cluster_name       = var.cluster_name
  cluster_endpoint   = local.cluster_endpoint
  machine_type       = local.node_machine_types[each.key]
  machine_secrets    = local.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
  docs               = false
  examples           = false

  config_patches = concat(
    [
      local.common_patch,
      # ホスト名の設定。Talos 1.13 の生成設定にはデフォルトで
      yamlencode({
        apiVersion = "v1alpha1"
        kind       = "HostnameConfig"
        "$patch"   = "delete"
      }),
      yamlencode({
        apiVersion = "v1alpha1"
        kind       = "HostnameConfig"
        hostname   = each.key
      }),
      # ノード個別: インストール先、kubenet のルート設定
      yamlencode({
        machine = {
          install = {
            disk  = var.install_disk
            image = var.install_image[local.node_machine_types[each.key]]
            wipe  = false
          }
          network = {
            interfaces = [
              {
                # kubenet 側の NIC。名前ではなく MAC アドレスで特定する
                deviceSelector = {
                  hardwareAddr = local.node_kubenet_macs[each.key]
                }
                dhcp = true
                routes = [
                  {
                    network = local.sdn_supernet
                    gateway = cidrhost(local.node_kubenet_subnets[each.key], 1)
                  }
                ]
              }
            ]
          }
        }
      }),
      # tailscale の設定 (旧 apply_tailscale.sh)
      yamlencode({
        apiVersion = "v1alpha1"
        kind       = "ExtensionServiceConfig"
        name       = "tailscale"
        environment = [
          "TS_AUTHKEY=${var.ts_authkey}",
          "TS_ROUTES=${local.node_kubenet_subnets[each.key]}",
          "TS_EXTRA_ARGS=--accept-routes",
        ]
      }),
    ],
    local.node_machine_types[each.key] == "controlplane" ? [local.controlplane_patch] : [local.worker_patch],
  )
}

# 各ノードへのマシン設定の適用 (旧 talosctl apply-config)。
resource "talos_machine_configuration_apply" "main" {
  for_each = toset(local.nodes)

  client_configuration_wo        = ephemeral.talos_client_configuration.main.client_configuration
  machine_configuration_input_wo = ephemeral.talos_machine_configuration.main[each.key].machine_configuration
  node                           = local.node_ips[each.key]
}

# etcd のブートストラップ (旧 talosctl bootstrap)
resource "talos_machine_bootstrap" "main" {
  depends_on = [talos_machine_configuration_apply.main]

  client_configuration_wo = ephemeral.talos_client_configuration.main.client_configuration
  node                    = local.bootstrap_ip

  lifecycle {
    # bootstrap は初回のみ実行される。ノード IP の変化で再実行しない。
    ignore_changes = [node, endpoint]
  }
}
