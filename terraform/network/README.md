# terraform/network

Proxmox のネットワークレイヤを管理するルートモジュール。

## 構成

- `proxmox_sdn_zone_simple` / `proxmox_sdn_vnet` / `proxmox_sdn_subnet`: SDN Simple ゾーン一式 (zonea/zoneb/zonec)。DHCP レンジ・ゲートウェイは CIDR から導出
- `proxmox_sdn_applier`: SDN 変更の適用確定 (zone/vnet/subnet の変更で自動的に再適用)
- `proxmox_virtual_environment_firewall_rules`: クラスタファイアウォールのルールリスト全体
- `terraform_data.host` + `data.external.host_drift`: PVE ホストの FRR/OSPF・dnsmasq 前提条件・ip_forward を SSH で構成。plan 時に実設定とのドリフトを検査し、ドリフトがあれば apply で収束する

`sdn_supernet` (10.0.0.0/8) はここが唯一の定義元。OSPF の prefix-list・ファイアウォールルール・
ゲスト側ルートの宛先 (talos が remote state 経由で参照) のすべてがこの変数から導出される。

## 認証

- **API**: `mise.local.toml` の `PROXMOX_VE_USERNAME` / `PROXMOX_VE_PASSWORD` を環境変数として読み込む。
- **SSH**: `mise.local.toml` の `TF_VAR_ssh_password` によるパスワード認証で各 PVE ホストに
  root 接続する (FRR/dnsmasq の構成と plan 時のドリフト検査に使用)。

## 既存環境の取り込み (初回のみ)

`imports.tf` の import ブロックが既存の zone/vnet/subnet とクラスタ FW ルールを取り込む。

```sh
terraform init
terraform plan -var-file=env/prod/variables.tfvars
```

**plan の確認観点:**

- zone/vnet/subnet/FW ルールが import になっていること (replace や destroy が出ないこと)
- `terraform_data.host` の 3 ノード作成以外に差分がないこと
  (プッシュは冪等で、内容が同じなら FRR の reload は走らない)

問題なければ `terraform apply -var-file=env/prod/variables.tfvars`。
取り込み後にもう一度 plan を実行し no changes になることを確認する。

## ドリフト検査と assume_hosts_unchanged

- plan のたびに各 PVE ホストへ SSH し、frr.conf のハッシュ・ospfd 有効・dnsmasq 無効・
  ip_forward を検査する。ドリフトがあれば plan に `terraform_data.host` の replace が出て、
  apply で修復される (修復後の次の plan に無害な replace がもう 1 回出る仕様)。
- ホストに SSH 到達できない場合、plan は**意図的に失敗する**。ホストを触る必要がない変更
  (SDN/FW など API のみ) を適用したい場合に限り、ユーザーの判断で検査をスキップする:

```sh
terraform apply -var-file=env/prod/variables.tfvars -var assume_hosts_unchanged=true
```

このとき plan には「ドリフト検査はスキップされています」という check 警告が常時出る。

## 注意

- サブネットの CIDR 変更は稼働中のノードの IP・DHCP リースと整合しない。クラスタ再構築を
  伴う操作として計画すること。
- FW ルールの末尾 2 つは無効化済み。不要になったら削除してよい (削除は plan に明示される)。
- クラスタ FW の**オプション** (enable とポリシー) は Terraform 管理外。実機には enable: 1 のみが
  保存されており、ポリシーは PVE デフォルト (input DROP / output ACCEPT / forward ACCEPT) で
  動いている。誤って FW を無効化しても Terraform は検知しないことに注意。
- 将来 Proxmox SDN Fabrics (PVE 9) へ移行する場合、frr.conf が SDN 管理になるため
  本モジュールの FRR 管理と衝突する。移行時は `terraform_data.host` の FRR 部分を先に撤去すること。

## リファレンス

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >=1.11 |
| external | >= 2.3.0 |
| proxmox | >= 0.84.0, < 1.0.0 |

## Providers

| Name | Version |
|------|---------|
| external | >= 2.3.0 |
| proxmox | >= 0.84.0, < 1.0.0 |
| terraform | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [proxmox_sdn_applier.main](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/sdn_applier) | resource |
| [proxmox_sdn_subnet.main](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/sdn_subnet) | resource |
| [proxmox_sdn_vnet.main](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/sdn_vnet) | resource |
| [proxmox_sdn_zone_simple.main](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/sdn_zone_simple) | resource |
| [proxmox_virtual_environment_firewall_rules.main](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_firewall_rules) | resource |
| [terraform_data.host](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [external_external.host_drift](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| proxmox\_uri | Proxmox VE API のエンドポイント (例: https://192.168.2.253:8006) | `string` | n/a | yes |
| pve\_nodes | PVE ノード名 → underlay (vmbr0) 側 IP アドレス | `map(string)` | n/a | yes |
| sdn\_supernet | SDN 全体を包含するスーパーネット。OSPF への広告・ファイアウォール・ゲスト側ルートの宛先の定義元。 | `string` | n/a | yes |
| ssh\_password | PVE ホストへの SSH パスワード。環境変数 TF\_VAR\_ssh\_password 経由で設定する | `string` | n/a | yes |
| underlay\_cidr | underlay ネットワークの CIDR (OSPF の network 文) | `string` | n/a | yes |
| zones | SDN Simple ゾーンの定義。ゾーン名 → 配置ノード・VNet 名 (= ゲストから見たブリッジ名)・サブネット CIDR。ゲートウェイは CIDR の先頭アドレス、DHCP レンジは 2〜254 番ホストを使う。 | <pre>map(object({<br/>    node = string<br/>    vnet = string<br/>    cidr = string<br/>  }))</pre> | n/a | yes |
| assume\_hosts\_unchanged | ホスト (FRR/dnsmasq) 設定に変更が不要であると表明し、plan 時の SSH ドリフト検査をスキップする。PVE ホストに到達できないが SDN/FW など API のみの変更を適用したい場合に true。 | `bool` | `false` | no |
| ospf\_area | OSPF エリア | `string` | `"0"` | no |
| ssh\_user | PVE ホストへの SSH ユーザー | `string` | `"root"` | no |
| underlay\_bridge | underlay 側のブリッジ名。OSPF の隣接を張るインターフェイス。 | `string` | `"vmbr0"` | no |

## Outputs

| Name | Description |
|------|-------------|
| node\_vnets | PVE ノード名 → そのノードにローカルな VNet 名 (VM の kubenet 側ブリッジの導出に使う) |
| pve\_node\_ips | PVE ノード名 → underlay 側 IP アドレス |
| sdn\_supernet | SDN 全体のスーパーネット (ゲスト側ルートの宛先) |
| vnet\_cidrs | VNet 名 (= ゲストから見たブリッジ名) → サブネット CIDR |
| vnet\_gateways | VNet 名 → ゲートウェイアドレス |
<!-- END_TF_DOCS -->
