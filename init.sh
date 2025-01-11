#!/usr/bin/env bash

function activate_proxmox_api {
    declare -r PASSWORD=$1
    pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.Use"
    pveum user add terraform-prov@pve --password "${PASSWORD}"
    pveum aclmod / -user terraform-prov@pve -role TerraformProv
}

function install_packages {
    echo "Installing packages."
    apt update
    apt install -y dnsmasq frr-pythontools libguestfs-tools
    # disable default instance
    systemctl disable --now dnsmasq
    echo "Successfully installed."
}

function main {
    if [ $# -ne 1 ]; then
        echo "Usage: $0 <password>"
        exit 1
    fi

    declare -r PASSWORD="$1"

    pvesm set local --content images,rootdir,vztmpl,backup,iso,snippets

    # activate proxmox api if not already activated
    if ! pveum user list | grep -q terraform-prov@pve; then
        activate_proxmox_api "${PASSWORD}"
    fi

    # install_dnsmasq if not already installed
    if [ "$(dpkg -l dnsmasq | grep 'ii')" == "" ] ||\
        [ "$(dpkg -l frr-pythontools | grep 'ii')" == "" ] ||\
        [ "$(dpkg -l libguestfs-tools | grep 'ii')" == "" ]; then
        install_packages
    fi
}

main "$@"
