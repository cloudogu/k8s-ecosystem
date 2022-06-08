## Creation of a Kubernetes CES image
## Requirements
- `git` installed
- `packer` installed (see [packer.io](https://www.packer.io/))
- `VirtualBox`, `QEMU` and/or `VMware Workstation` installed

## 1. Clone the k8s-ecosystem repository
- `git clone https://github.com/cloudogu/k8s-ecosystem.git`

## 2. Start the build process with packer
- `cd <k8s-ecosystem-path>/image/`
- `packer build -var "timestamp=$(date +%Y%m%d)" k8s-prod.json`

## 3. Wait
- The image building process takes about 15 minutes, depending on your hardware and internet connection.

## 4. Finish
- The image can be found in `<ecosystem path>/image/output-*` and as tar archive in `<ecosystem path>/image/build`.
  - The default user is `ces-admin` with the password `ces-admin`. This should be changed as soon as possible!
  - Establishing an SSH connection is described in the document [SSH authentication on Cloudogu EcoSystem](../operations/ssh_authentication_en.md).
