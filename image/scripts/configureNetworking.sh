#!/bin/bash
# This file is responsible to perform configuration for dhcp client and the networking interface.
set -o errexit
set -o nounset
set -o pipefail

# Removing leftover leases and persistent rules.
removeDHCPLeases() {
  echo "**** Removing leftover leases and persistent rules..."
  if [ -d /var/lib/dhcp/ ]; then
    echo "cleaning up dhcp leases"
    rm -f /var/lib/dhcp/*
  fi
}

# Make sure Udev doesn't block our network interface
cleanUpUDev() {
  echo "**** Cleaning up udev rules..."
  if [ -f /etc/udev/rules.d/70-persistent-net.rules ]; then
    rm -f /etc/udev/rules.d/70-persistent-net.rules
    mkdir /etc/udev/rules.d/70-persistent-net.rules
  fi

  if [ -d /dev/.udev/ ]; then
    rm -rf /dev/.udev/
  fi

  if [ -f /lib/udev/rules.d/75-persistent-net-generator.rules ]; then
    rm -f /lib/udev/rules.d/75-persistent-net-generator.rules
  fi
}

# Adding a 2 sec delay to the interface up, to make the dhclient happy
addPreSleepToInterface() {
  echo "**** Adding a 2 sec delay to the interface up..."
  echo "pre-up sleep 2" >>/etc/network/interfaces
}

echo "**** Executing configureNetworking.sh..."
removeDHCPLeases
cleanUpUDev
addPreSleepToInterface
echo "**** Finished configureNetworking.sh"
