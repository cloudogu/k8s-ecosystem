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
   - To build only for a specific hypervisor, the `--only=` parameter can be used
   - Example: `packer build -var "timestamp=$(date +%Y%m%d)" --only=ecosystem-virtualbox k8s-prod.json`

## 3. Wait

- The image building process takes about 15 minutes, depending on your hardware and internet connection.

## 4. Finish

- The image can be found in `<ecosystem path>/image/output-*` and as tar archive in `<ecosystem path>/image/build`.
   - The default user is `ces-admin` with the password `ces-admin`. This should be changed as soon as possible!
   - Establishing an SSH connection is described in the
     document [SSH authentication on Cloudogu EcoSystem](../operations/ssh_authentication_en.md).

## 5. Test the built image in Vagrant

You can now test the previously built image. Vagrant needs to know know the image in order to use it, so it needs to be imported with a name (e.g. `testbox`).

```bash
vagrant box import --name testbox build/ecosystem-basebox.box
```

To finish the test preparation, the `Vagrantfile` must be locally modified in three sections::

1. the definition section at the start
   - comment out the URL and checksums elements
   - change the box name to the name of the local build (here `testbox`)
2. the provisioning part for main nodes
   - comment out the URL and checksums elements
3. the provisioning part for worker nodes
   - comment out the URL and checksums elements

```ruby
# ...
# basebox_checksum = "9f031617c1f21a172d01b6fc273c4ef95b539a5e35359773eaebdcabdff2d00f"
# basebox_checksum_type = "sha256"
# basebox_url = "https://storage.googleapis.com/cloudogu-ecosystem/basebox-mn/" + basebox_version + "/basebox-mn-" + basebox_version + ".box"
basebox_name = "testbox"

# ...
Vagrant.configure("2") do |config|
  config.vm.define "main", primary: true do |main|
    main.vm.box = basebox_name

    # main.vm.box_url = basebox_url
    # main.vm.box_download_checksum = basebox_checksum
    # main.vm.box_download_checksum_type = basebox_checksum_type
    # ...
  end
end
#...
(0..(worker_count - 1)).each do |i|
  config.vm.define "worker-#{i}" do |worker|
    worker.vm.hostname = "ces-worker-#{i}"

    worker.vm.box = basebox_name
    # worker.vm.box_url = basebox_url
    # worker.vm.box_download_checksum = basebox_checksum
    # worker.vm.box_download_checksum_type = basebox_checksum_type
    # ...
  end
end
#...
```

The built image can now be started up as usual:

```bash
vagrant up
```
