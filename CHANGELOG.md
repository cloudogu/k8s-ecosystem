# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Changed
- Use k8s-ces-setup helm chart #40
- Use `cloudogu/k8s-longhorn` instead of the official release #18
- Add the dev registry configuration to the node config so that it will always apply to `/etc/rancher/k3s/registries.yaml` #17
- update installation manual #37
- Install longhorn as a component and remove it from the base image #52

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

### Fixed
- Added missing KUBECONFIG export to setup
- Gracefully shutdown k3s on vagrant halt/reload
