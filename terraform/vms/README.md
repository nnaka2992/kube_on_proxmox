# terraform/vms

Talos ノード VM を管理するルートモジュール。

## 構成

- `proxmox_virtual_environment_vm`: Talos ノード 8 台 (ISO ブート、ディスク 100G、NIC 2 枚)
- ロールとタグは VM 名から、kubenet 側ブリッジは配置ノードから導出
  (`terraform/network` の `node_vnets` を remote state で参照)
- **MAC アドレスは宣言しない**: Proxmox が生成した値を import で取り込み、outputs
  (`vm_kubenet_macaddrs`) 経由で talos 側の `deviceSelector` に流す

## 認証

`mise.local.toml` の `PROXMOX_VE_USERNAME` / `PROXMOX_VE_PASSWORD` を環境変数として読み込む。

## 既存 VM の取り込み (初回のみ)

**前提**: `terraform/network` が apply 済みであること (`node_vnets` output を参照するため)。

```sh
terraform init
terraform plan -var-file=env/prod/variables.tfvars
```

**plan の確認観点:**

- 8 台すべてが import になっていること
- **update / replace / destroy が 1 件も出ないこと**。特に `network_device` の変更が
  出ていないか注意 — MAC が変わるとノードの DHCP リースと talos の deviceSelector が
  壊れる。差分が出た場合は apply せず、宣言と実機の食い違いを突き合わせること

問題なければ apply し、もう一度 plan で no changes を確認する。

## 注意

- `cores` / `memory` の変更は hotplug 可能な範囲なら稼働中に反映される。それ以外
  (ディスク縮小など) は破壊的操作なので plan をよく確認すること。
- VM を作り直すと MAC と IP が変わる。`terraform/vms` → `terraform/talos` の順に
  apply すれば新しい値が自動で伝播する。

## リファレンス

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >=1.11 |
| proxmox | >= 0.84.0, < 1.0.0 |

## Providers

| Name | Version |
|------|---------|
| proxmox | >= 0.84.0, < 1.0.0 |
| terraform | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [proxmox_virtual_environment_vm.main](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm) | resource |
| [terraform_remote_state.network](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| proxmox\_uri | Proxmox VE API のエンドポイント (例: https://192.168.2.253:8006) | `string` | n/a | yes |
| talos\_iso | Talos の ISO イメージ (例: local:iso/talos-1.13.9-amd64.iso) | `string` | n/a | yes |
| vms | Talos ノード VM の定義。キーが VM 名 (= Talos のホスト名)。ロールは名前から、kubenet 側ブリッジは配置ノードから導出する。 | <pre>map(object({<br/>    node   = string # 配置する PVE ノード<br/>    vm_id  = number<br/>    cores  = number<br/>    memory = number # MiB<br/>  }))</pre> | n/a | yes |
| disk\_datastore | VM ディスクのデータストア | `string` | `"local-lvm"` | no |
| disk\_size | VM ディスクのサイズ (GB) | `number` | `100` | no |

## Outputs

| Name | Description |
|------|-------------|
| vm\_ipv4\_addresses | VM 名 → qemu-guest-agent が報告する vmbr0 側 IPv4 アドレス |
| vm\_kubenet\_bridges | VM 名 → kubenet 側ブリッジ (= VNet) 名 |
| vm\_kubenet\_macaddrs | VM 名 → kubenet 側 NIC の MAC アドレス (talos の deviceSelector 用に小文字化) |
<!-- END_TF_DOCS -->
