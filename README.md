# Kube on Proxmox
My Home Kubernetes on Proxmox IaC using terraform to create VMs on Proxmox.

## Setup
This repository uses asdf compatible dev tool manager.

To install asdf or mise, follow the instructions below.

- [mise Quickstart](https://github.com/jdx/mise?tab=readme-ov-file#quickstart)
- [asdf Getting Started](https://asdf-vm.com/guide/getting-started.html)

### Install Dev tools
```bash
mise install
```
or 
```bash
asdf install
```

### Installed Dev tools
- terraform
- terraform-docs

## Enable Proxmox API
To enable Proxmox API, follow the instructions below.

``` bash
pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.Use"
pveum user add terraform-prov@pve --password <password>
pveum aclmod / -user terraform-prov@pve -role TerraformProv
```

For more informations, read the following link.
- [Docs overview | Telmate/proxmox | Terraform | Terraform Registry](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)

## Provisioning VMs
To provision VMs on Proxmox, follow the instructions below.

``` bash
cd terraform/proxmox
vim ./env/prod/variables.tfvars # Edit variables for your environment
terraform init
PM_USER='terraform-prov@pve' PM_PASS='<password>' terraform apply -var-files=./env/prod/variables.tfvars
```

