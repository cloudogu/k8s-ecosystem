# Building the EcoSystem Development Base-Boxes

This document contains the necessary information to build the development base-boxes required to start a development
instance of the Cloudogu EcoSystem. Generally there are two base-boxes. One for the main node and another for a worker
node. The base-boxes contain shared tools and installations to reduce the effort for creating a new development instance
via Vagrant.

## Requirements
- `git` installed
- `packer` installed (see [packer.io](https://www.packer.io/))
- `VirtualBox` installed
- Understanding the [Structure of the Project Files](structure_of_the_files_en.md)

## Building the Main Node Basebox

**1. Clone the k8s-ecosystem repository**

```bash
git clone https://github.com/cloudogu/k8s-ecosystem.git
```

**2. Build image**

```bash
cd <k8s-ecosystem-path>/image/
packer build k8s-dev-main.json
```

**3. Wait**

The image building process takes about 15 minutes, depending on your hardware and internet connection. Packer should
create a resulting basebox named `ecosystem-basebox-main.box` in the `build` folder.

## Building the Worker Node Basebox

**1. Clone the k8s-ecosystem repository**

```bash
git clone https://github.com/cloudogu/k8s-ecosystem.git
```

**2. Build image**

```bash
cd <k8s-ecosystem-path>/image/
packer build k8s-dev-worker.json
```

**3. Wait**

The image building process takes about 15 minutes, depending on your hardware and internet connection. Packer should
create a resulting basebox named `ecosystem-basebox-worker.box` in the `build` folder.