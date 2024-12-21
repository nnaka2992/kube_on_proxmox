<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.10.3 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | =3.0.1-rc6 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | =3.0.1-rc6 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [proxmox_vm_qemu.main](https://registry.terraform.io/providers/Telmate/proxmox/3.0.1-rc6/docs/resources/vm_qemu) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cores"></a> [cores](#input\_cores) | vCPUs 数： 2 以上の値を指定してください。 | `number` | n/a | yes |
| <a name="input_is_control_plane"></a> [is\_control\_plane](#input\_is\_control\_plane) | コントロールプレーンであれば true、ワーカーであれば false を指定してください。 | `bool` | n/a | yes |
| <a name="input_memory"></a> [memory](#input\_memory) | メモリ (MB)： 2048 以上の値を指定してください。 | `number` | n/a | yes |
| <a name="input_proxmox_node"></a> [proxmox\_node](#input\_proxmox\_node) | VM をホストする Proxmox ノード名 | `string` | n/a | yes |
| <a name="input_vm_name"></a> [vm\_name](#input\_vm\_name) | コントロールプレーンをホストする VM 名 | `string` | n/a | yes |
| <a name="input_vmid"></a> [vmid](#input\_vmid) | VM ID | `number` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->