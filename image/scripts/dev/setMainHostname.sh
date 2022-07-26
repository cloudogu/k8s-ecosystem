#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

echo "Setting hostname to ces-main..."
hostnamectl set-hostname ces-main

echo "Rebooting..."
reboot