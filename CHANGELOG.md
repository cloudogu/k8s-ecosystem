# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v5.2.0] - 2025-03-21
### Added
- [#112] Add Helm timeout to terraform setup

## [v5.1.0] - 2025-03-05

### Added
- [#104] Terraform module to create a cluster in plusserver pske

## [v5.0.0] - 2025-02-17

- **Breaking:** remove `google_gke_http_cron` terraform module

### Added
- [#105] Terraform module to create Keycloak-Clients for CES delegated authentication
- [#105] Example for using the new `keycloak-client-module` with a CES in GKE
- [#107] add `google_gke_scaling_scheduler` terraform module
- [#107] add support for labels in `gke_cluster` module
- [#107] set 1.31 as default k8s version in terraform `gke_cluster`
- [#107] activate cost_control in terraform `gke_cluster`

### Changed
- [#105] Extend Terraform CES module to configure CAS delegated authentication
- [#107] simplify `ces_google_gke` example
- [#107] use new `google_gke_scaling_scheduler` in `ces_google_gke` example
- [#107] update providers in `ces_google_gke` example
- [#107] remove default bucket configuration in `ces_google_gke` example

### Removed
- [#107] **Breaking:** remove `google_gke_http_cron` terraform module
  - use the new `google_gke_scaling_scheduler` module

## [v4.1.2] - 2024-12-19
### Added
- [#102] Add networkpolicy for dev docker registry.

## [v4.1.1] - 2024-11-18
### Changed
- [#100] update k8s-ces-setup in terraform to 3.0.4

## [v4.1.0] - 2024-11-15
### Added
- [#98] added possibilty to modify components in terraform setup

## [v4.0.0] - 2024-10-29
### Changed
- **Breaking**: Updated k8s-ces-setup configuration in vagrant environment and terraform module to support the new structure of the container registry secret. #96
For terraform variable declaration see `container_registry_secrets` in [variables.tf](terraform/ces-module/variables.tf).
- Update default setup helm chart version to 3.0.0 in terraform module `ces-module`.

## [v3.1.0] - 2024-09-19
### Changed
- Replace terraform kubernetes generic manifests resources with explicit corresponding resources (e.g. daemonsets) because they need the kubeconfig already in plan phase and prevent a single `terraform apply` #87
- Changed dogu variable in terraform ces-module. All dogus have to be defined. With this change one can change the versions of the necessary dogus like `ldap`.
- Split terraform google gke example into "bucket" and "ces-cluster" to avoid deleting the bucket all the time. #78
- Add maintenance window to terraform gke module #92
- set 1.30 as default k8s version in terraform gke module #92
- reduce default node disk size in terraform gke module #92
- add parameters for preemtible and spot VMs in terraform gke module #92
- (breaking) set `preemtible = false` as default for nodes in terraform gke module #92
- Relicense to AGPL-3.0-only

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
