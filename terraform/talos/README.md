# terraform/talos

Talos クラスタのマシン設定・ブートストラップを Terraform で管理するルートモジュール。

## 構成

- `ephemeral.talos_client_configuration`: Talos API のクライアント認証情報を `secrets.yaml` から生成
- `ephemeral.talos_machine_configuration`: ノードごとのマシン設定を生成。tailscale の
  ExtensionServiceConfig も含む
- `talos_machine_configuration_apply`: 各ノードへ設定を適用
- `talos_machine_bootstrap`: 先頭のコントロールプレーンで etcd をブートストラップ

## 入力の導出

tfvars に書くのはクラスタ自体の設計判断のみ (クラスタ名・バージョン・インストールイメージ)。
環境依存の値はすべて他ルートの state から導出する:

| 値 | 定義元 |
|---|---|
| ノード一覧・ロール | `terraform/vms` の VM 名 (`control-plane-*` / `worker-*`) |
| ノード IP (Talos API 接続先) | `terraform/vms` (qemu-guest-agent が報告する vmbr0 側アドレス) |
| kubenet NIC (`deviceSelector`) | `terraform/vms` の MAC アドレス |
| ノードごとのサブネット・ゲートウェイ | kubenet ブリッジ名 → `terraform/network` の VNet CIDR |
| kubelet validSubnets / etcd advertisedSubnets | `terraform/network` の全 VNet CIDR |
| ゲスト側ルートの宛先 | `terraform/network` の `sdn_supernet` |
| Kubernetes API エンドポイント | 先頭のコントロールプレーンの IP |

## 秘密情報

- `secrets.yaml`: クラスタの秘密鍵一式。talosctl で生成した唯一のファイル管理 (Git 管理外)。
  失うとクラスタを管理できなくなるためバックアップすること。
- tailscale の認証キー: `mise.local.toml` の `TF_VAR_ts_authkey` を環境変数として読み込む。
  ephemeral variable のため tfstate には残らない。
  参加済みノードはディスク上の tailscale state で再認証されるため、期限切れキーでも
  再適用は壊れない (新規ノードの参加時のみ有効なキーが必要)。

マシン設定・クライアント認証情報は ephemeral resource + write-only 引数のため、
**秘密情報は `terraform.tfstate` に一切残らない** (Terraform 1.11+ / プロバイダ 0.11+)。

## クラスタ作成手順

```sh
# 1. クラスタの秘密鍵一式を生成 (初回のみ。Git 管理外)
cd terraform/talos
talosctl gen secrets -o secrets.yaml

# 2. ネットワークと VM を作成
cd ../network && terraform apply -var-file=env/prod/variables.tfvars
cd ../vms && terraform apply -var-file=env/prod/variables.tfvars

# 3. マシン設定の適用とブートストラップ
cd ../talos
terraform init
terraform apply -var-file=env/prod/variables.tfvars

# 4. talosconfig / kubeconfig の取得 (talosctl CLI 用。どちらも Git 管理外)
#    エンドポイントは先頭のコントロールプレーンの IP を指定する
talosctl gen config my-cluster https://192.168.2.113:6443 \
    --with-secrets secrets.yaml --output-types talosconfig -o talosconfig
talosctl --talosconfig talosconfig config endpoint 192.168.2.113 192.168.2.109 192.168.2.111
talosctl --talosconfig talosconfig kubeconfig --nodes 192.168.2.113
```

## 注意

- ノードの IP が DHCP で変わった場合は `terraform/vms` を apply (refresh) してから
  本モジュールを apply する。tfvars の修正は不要。先頭のコントロールプレーンの IP が
  変わった場合はエンドポイントも変わるため全ノードの設定が再適用され、
  talosconfig / kubeconfig の再生成も必要になる。
- CLI 用の `talosconfig` は有効期限が切れても手順 4 のコマンドで `secrets.yaml` から再生成できる。

## リファレンス

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >=1.11 |
| talos | = 0.11.0 |

## Providers

| Name | Version |
|------|---------|
| talos | = 0.11.0 |
| terraform | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [talos_machine_bootstrap.main](https://registry.terraform.io/providers/siderolabs/talos/0.11.0/docs/resources/machine_bootstrap) | resource |
| [talos_machine_configuration_apply.main](https://registry.terraform.io/providers/siderolabs/talos/0.11.0/docs/resources/machine_configuration_apply) | resource |
| [terraform_remote_state.network](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.vms](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster\_name | Talos クラスタ名 | `string` | n/a | yes |
| install\_image | インストールに使うイメージ。システム拡張 (qemu-guest-agent, tailscale) を含む factory イメージを指定すること。 | `string` | n/a | yes |
| kubernetes\_version | Kubernetes バージョン (例: 1.36.3) | `string` | n/a | yes |
| talos\_version | マシン設定の生成に使う Talos バージョン (例: v1.13.9) | `string` | n/a | yes |
| ts\_authkey | tailscale の認証キー。環境変数 TF\_VAR\_ts\_authkey 経由で設定する | `string` | n/a | yes |
| install\_disk | Talos をインストールするディスク | `string` | `"/dev/sda"` | no |
| secrets\_file | talosctl gen secrets で生成した secrets ファイルへのパス (ルートモジュールからの相対パス) | `string` | `"secrets.yaml"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
