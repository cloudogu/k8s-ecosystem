packer {
  required_plugins {
    virtualbox = {
      source  = "github.com/hashicorp/virtualbox"
      version = "~> 1"
    }
    vmware = {
      source  = "github.com/hashicorp/vmware"
      version = "~> 1"
    }
  }
}

variable "ces_namespace" {
  type    = string
  default = "ecosystem"
}

variable "cpus" {
  type    = number
  default = 4
}

variable "disk_size" {
  type    = number
  default = 100000
}

variable "fqdn" {
  type    = string
  default = "k3ces.localdomain"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:8762f7e74e4d64d72fceb5f70682e6b069932deedb4949c6975d0f0fe0a91be3"
}

variable "iso_url" {
  type    = string
  default = "https://releases.ubuntu.com/noble/ubuntu-24.04-live-server-amd64.iso"
}

variable "main_k3s_port" {
  type    = number
  default = 6443
}

variable "memory" {
  type    = number
  default = 8192
}

variable "password" {
  type    = string
  default = "ces-admin"
}

variable "timestamp" {
  type = string
}

variable "username" {
  type    = string
  default = "ces-admin"
}

variable "virtualbox-version-lower-7" {
  type = bool
  description = "This flag indicates if the local vitualbox installation is older than version 7 to build the modifyvm option list because some options are not available with virtualbox < 7"
  default = false
}

locals {
  vm_name = "CloudoguEcoSystem-${var.timestamp}"
  common_vboxmanage = [["modifyvm", "${local.vm_name}", "--memory", "${var.memory}"], ["modifyvm", "${local.vm_name}", "--cpus", "${var.cpus}"], ["modifyvm", "${local.vm_name}", "--vram", "10"]]
  vboxmanage = var.virtualbox-version-lower-7 ? local.common_vboxmanage : concat(local.common_vboxmanage, [["modifyvm", local.vm_name, "--nat-localhostreachable1", "on"]])
}

source "virtualbox-iso" "ecosystem-virtualbox" {
  boot_command           = [
    "c<wait>",
    "set gfxpayload=keep<enter><wait>",
    "linux /casper/vmlinuz <wait>",
    "autoinstall fsck.mode=skip noprompt <wait>",
    "ds=\"nocloud-net;s=http://{{.HTTPIP}}:{{.HTTPPort}}/\"<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]
  boot_wait              = "5s"
  disk_size              = var.disk_size
  format                 = "ova"
  guest_os_type          = "ubuntu-64"
  hard_drive_interface   = "sata"
  headless               = false
  http_directory         = "http"
  iso_checksum           = var.iso_checksum
  iso_url                = var.iso_url
  shutdown_command       = "echo ${var.username} | sudo -S -E shutdown -P now"
  ssh_handshake_attempts = "10000"
  ssh_password           = var.password
  ssh_timeout            = "20m"
  ssh_username           = var.username
  vboxmanage             = local.vboxmanage
  vm_name                = local.vm_name
}

source "vmware-iso" "ecosystem-vmware" {
  boot_command           = [
    "c<wait>",
    "set gfxpayload=keep<enter><wait>",
    "linux /casper/vmlinuz <wait>",
    "autoinstall fsck.mode=skip noprompt <wait>",
    "ds=\"nocloud;s=http://{{.HTTPIP}}:{{.HTTPPort}}/\"<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]
  boot_wait              = "5s"
  cpus                   = var.cpus
  disk_size              = var.disk_size
  disk_type_id           = "1"
  guest_os_type          = "ubuntu-64"
  headless               = false
  http_directory         = "http"
  iso_checksum           = var.iso_checksum
  iso_urls               = [var.iso_url]
  memory                 = var.memory
  shutdown_command       = "echo ${var.username} | sudo -S -E shutdown -P now"
  ssh_handshake_attempts = "10000"
  ssh_password           = var.password
  ssh_timeout            = "27m"
  ssh_username           = var.username
  tools_upload_flavor    = "linux"
  version                = "14"
  vm_name                = local.vm_name
}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  sources = ["source.virtualbox-iso.ecosystem-virtualbox", "source.vmware-iso.ecosystem-vmware"]

  provisioner "file" {
    destination = "/home/${var.username}/resources"
    source      = "../../resources"
  }

  provisioner "shell" {
    environment_vars  = ["HOME_DIR=/home/${var.username}", "CES_NAMESPACE=${var.ces_namespace}", "USERNAME=${var.username}"]
    execute_command   = "echo ${var.password} | {{ .Vars }} sudo -S -E /bin/bash -eux '{{ .Path }}'"
    expect_disconnect = false
    scripts           = ["../scripts/startInstallation.sh", "../scripts/installDependencies.sh", "../scripts/installGuestAdditions.sh", "../scripts/configureGrub.sh", "../scripts/configureNetworking.sh", "../scripts/configureSSHDaemon.sh", "../scripts/setupFail2Ban.sh", "../scripts/installK9s.sh", "../scripts/installHelm.sh", "../scripts/kubernetes/prepareK3sInstallation.sh", "../scripts/kubernetes/installCustomServiceFiles.sh", "../scripts/optimizeImageSize.sh"]
  }

  post-processor "checksum" {
    checksum_types = ["sha256"]
    output         = "build/SHA256SUMS"
  }
  post-processor "compress" {
    compression_level = 6
    output            = "build/${local.vm_name}.tar.gz"
  }
}
