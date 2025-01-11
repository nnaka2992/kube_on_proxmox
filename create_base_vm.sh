#!/usr/bin/env bash

function main {
    # check number of arguments
    if [ $# -ne 4 ]; then
        echo "Usage: $0 <CLOUD_INIT_IMAGE_URL> <IMAGE_NAME> <VM_ID> <TAILSCALE_AUTH_KEY>"
        exit 1
    fi

    declare -r CLOUD_INIT_IMAGE_URL=$1
    declare -r IMAGE_NAME=$2
    declare -r VM_ID=$3
    declare -r TAILSCALE_AUTH_KEY=$4

    declare -r CLOUD_INIT_IMAGE_NAME=$(basename "${CLOUD_INIT_IMAGE_URL}")
    declare -r CLOUD_INIT_BASE_IMAGE_DIR="$HOME/cloud-init-images"

    # Create the cloud-init image
    create_base_image "${CLOUD_INIT_IMAGE_URL}" "${CLOUD_INIT_IMAGE_NAME}" "${CLOUD_INIT_BASE_IMAGE_DIR}"

    # Create the cloud-init template
    create_template "${CLOUD_INIT_BASE_IMAGE_DIR}/${CLOUD_INIT_IMAGE_NAME}" "${IMAGE_NAME}" "${VM_ID}"

    # Create the cloud-init custom file
    create_cicustom_file "${TAILSCALE_AUTH_KEY}"
}

function create_base_image {
    declare -r CLOUD_INIT_IMAGE_URL="$1"
    declare -r CLOUD_INIT_IMAGE_NAME="$2"
    declare -r CLOUD_INIT_BASE_IMAGE_DIR="$3"

    # Create a directory to store the cloud-init images
    if [ ! -d "${CLOUD_INIT_BASE_IMAGE_DIR}" ]; then
        mkdir -p "${CLOUD_INIT_BASE_IMAGE_DIR}"
    fi
 
    # Download the cloud-init image if it does not exist
    if [ ! -f "${CLOUD_INIT_BASE_IMAGE_DIR}/${CLOUD_INIT_IMAGE_NAME}" ]; then
        wget -P "${CLOUD_INIT_BASE_IMAGE_DIR}" "${CLOUD_INIT_IMAGE_URL}"
    fi

    virt-customize -a "${CLOUD_INIT_BASE_IMAGE_DIR}/${CLOUD_INIT_IMAGE_NAME}" --install qemu-guest-agent
    virt-customize -a "${CLOUD_INIT_BASE_IMAGE_DIR}/${CLOUD_INIT_IMAGE_NAME}" --run-command "echo -n > /etc/machine-id"

}
function create_template {
    declare -r CLOUD_INIT_IMAGE_PATH="$1"
    declare -r IMAGE_NAME="$2"
    declare -r VMID="$3"
    declare -r STORAGE="local-lvm"

    echo "create_template Parameters: ====================="
    echo "CLOUD_INIT_IMAGE_PATH: ${CLOUD_INIT_IMAGE_PATH}"
    echo "IMAGE_NAME: ${IMAGE_NAME}"
    echo "VMID: ${VMID}"
    echo "STORAGE: ${STORAGE}"
    echo "================================================="

    qm create "${VMID}" \
        --memory 2048 \
        --net0 virtio,bridge=vmbr0 \
        --scsihw virtio-scsi-pci
    qm set "${VMID}" \
        --name "${IMAGE_NAME}-cloud-init"
    qm set "${VMID}" \
        --scsi0 local-lvm:0,import-from="${CLOUD_INIT_IMAGE_PATH}"
    qm set "${VMID}" \
        --ide2 local-lvm:cloudinit
    qm set "${VMID}" \
        --boot order=scsi0
    qm set "${VMID}" \
        --serial0 socket \
        --vga serial0
    qm set "${VMID}" \
        --agent enabled=1,fstrim_cloned_disks=1
    qm template "${VMID}"
}

function create_cicustom_file {
    declare -r TAILSCALE_AUTH_KEY=$1

    if [ ! -d /var/lib/vz/snippets ]; then
        mkdir -p /var/lib/vz/snippets
    fi

    cat <<EOF > /var/lib/vz/snippets/cloudinit.yaml
#cloud-config
# The above header must generally appear on the first line of a cloud config
# file, but all other lines that begin with a # are optional comments.

runcmd:
  # One-command install, from https://tailscale.com/download/
  - ['sh', '-c', 'curl -fsSL https://tailscale.com/install.sh | sh']
  # Set sysctl settings for IP forwarding (useful when configuring an exit node)
  - ['sh', '-c', "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && sudo sysctl -p /etc/sysctl.d/99-tailscale.conf" ]
  # Generate an auth key from your Admin console
  # https://login.tailscale.com/admin/settings/keys
  # and replace the placeholder below
  - ['tailscale', 'up', '--auth-key=${TAILSCALE_AUTH_KEY}']
  # Comunicate with local network
  - ['tailscale', 'set', '--accept-routes']
EOF
}

main "$@"
  
