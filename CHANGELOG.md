# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v3.0.0] - 2024-06-26

First release. Based on the already released baseboxes it is called 3.0.0.
The features below have been added over a long period of time and may be out of date.

### Changed
- Add dogu_registry_urlschema - important: you need to change your `.vagrant.rb`
- Use k8s-ces-setup helm chart #40
- Use `cloudogu/k8s-longhorn` instead of the official release #18
- Add the dev registry configuration to the node config so that it will always apply to `/etc/rancher/k3s/registries.yaml` #17
- update installation manual #37
- Install longhorn as a component and remove it from the base image #52
- Upgrade k3s to 1.28.3 #56
- Passwords (Docker-, Dogu- & Helmregistry) has to be encoded in Base64 (see [here](docs/development/dev_box_en.md) and [here](terraform/ces-module/README.md)) #64
- Disk space related optimizations for development (f.e. fewer longhorn replicas) #71
- Add options to add node labels and taints on cluster setup #73
- Set new garbage collection defaults for `image-gc-low-threshold` and `image-gc-high-threshold`
- Terraform Azure Module - Variables and sensitive data can now be passed from an extra file.
- Upgrade Ubuntu to 24.04 #81

### Added
- Packer templates for CES production images
- Packer templates for CES development images
- Node configuration file; #7
- k3s offline/airgap installation; #7
- Enable unattended-upgrades
- Configuration for private registries; #9
- Install k9s; #11
- Add env var `KUBECONFIG` to sudoers thereby k9s can be used with `sudo` to edit resources; #21
- Describe the CES label policy; #24
- Restart chrony during k3s installation if it has replaced systemd-timesyncd
- Add proxy registry to simplify the development process of k8s components; #49
- Add support for mkcert-generated certificates
- make garbage collection configurable via `image-gc-low-threshold` and `image-gc-high-threshold`,

### Fixed
- Added missing KUBECONFIG export to setup
- Gracefully shutdown k3s on vagrant halt/reload; #54
- CES-Terraform-Module:
  - Remove check if setup is applied because it needs a running cluster; #77
