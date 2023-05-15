#!/bin/bash
# This script is responsible to install the guest additions for the currently used builder, e.g., VMWare, VirtualBox,...
set -o errexit
set -o nounset
set -o pipefail

# Installs quest addition based on the provided builder.
installGuestAdditions() {
  case "${PACKER_BUILDER_TYPE}" in
  virtualbox-iso) installGuestAdditionsVirtualBox ;;
  vmware-iso) installGuestAdditionsVMWare ;;
  vsphere-iso) installGuestAdditionsVMWare ;;
  qemu) ;;

  *)
    echo "Unknown Packer Builder Type >>${PACKER_BUILDER_TYPE}<< selected."
    echo "Known are virtualbox-iso|vmware-iso|qemu."
    echo "Aborting..."
    exit 1
    ;;
  esac
}

# Installs quest additions for the VirtualBox hypervisor.
installGuestAdditionsVirtualBox() {
  echo "**** Installing guest additions for VirtualBox hypervisor..."
  DEBIAN_FRONTEND=noninteractive apt-get -y install \
    gcc make perl

  mkdir -p /mnt/virtualbox
  mount -o loop "${HOME_DIR}"/VBoxGuest*.iso /mnt/virtualbox
  # encapsulate execution because of false positve (https://github.com/dotless-de/vagrant-vbguest/issues/168)
  if sh /mnt/virtualbox/VBoxLinuxAdditions.run; then
    echo "VBoxLinuxAdditions.run was successful"
  fi

  # link to guest additions is already present
  #ln -s /opt/VBoxGuestAdditions-*/lib/VBoxGuestAdditions /usr/lib/VBoxGuestAdditions
  umount /mnt/virtualbox
  rm -rf "${HOME_DIR}"/VBoxGuest*.iso
}

# Installs quest additions for the VMWare hypervisor.
installGuestAdditionsVMWare() {
  echo "**** Installing guest additions for VMWare hypervisor..."
  DEBIAN_FRONTEND=noninteractive apt-get -y install \
    open-vm-tools
}

echo "**** Executing installGuestAdditions.sh..."
installGuestAdditions
echo "**** Finished installGuestAdditions.sh"
