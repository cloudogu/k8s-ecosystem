# Automatic security updates in the CES

There are [multiple options](https://help.ubuntu.com/community/AutomaticSecurityUpdates) to activate automatic security updates in Ubuntu. The most common one is using the "unattended-upgrades" package. This package automatically installs apt package updates as soon as they become available.
The "unattended-upgrades" package is activated in the CES by default.

To validate that automatic updates are activated, run the command `apt-config dump APT::Periodic::Unattended-Upgrade`.
The output should be: `APT::Periodic::Unattended-Upgrade "1";`

To disable unattended-upgrades, the package can be removed via `sudo apt remove unattended-upgrades` or you could follow this guide: https://linuxhint.com/enable-disable-unattended-upgrades-ubuntu/