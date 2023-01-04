# -*- mode: ruby -*-
# vi: set ft=ruby :

worker_count = (ENV["K8S_WORKERS"] || "1").to_i
vm_memory = (ENV["K8S_VM_MEMORY"] || "4096").to_i
vm_cpus = (ENV["K8S_VM_CPUS"] || "2").to_i
vm_image = ENV["K8S_VM_IMAGE"] || "bento/ubuntu-20.04"
main_k3s_ip_address = "192.168.56.2"
main_k3s_port = 6443
fqdn = "k3ces.local"
docker_registry_namespace = "ecosystem"
install_setup = true
dogu_registry_username = ""
dogu_registry_password = ""
dogu_registry_url = ""
image_registry_username = ""
image_registry_password = ""
image_registry_email = ""
basebox_version="v1.2.0"
basebox_checksum = "3236bbca1270be4460e5e68af9587a4cf7b1d701a38755c985d882658823b236"
basebox_checksum_type = "sha256"
basebox_url="https://storage.googleapis.com/cloudogu-ecosystem/basebox-mn/"+basebox_version+"/basebox-mn-"+basebox_version+".box"
basebox_name = "basebox-mn-"+basebox_version

# Load custom configurations from .vagrant.rb file, if existent
if File.file?(".vagrant.rb")
  eval File.read(".vagrant.rb")
end

Vagrant.configure("2") do |config|
  config.vm.define "main", primary: true do |main|
    main.vm.hostname = "ces-main"

    main.vm.box = basebox_name
    main.vm.box_url = basebox_url
    main.vm.box_download_checksum = basebox_checksum
    main.vm.box_download_checksum_type = basebox_checksum_type

    main.vm.synced_folder "nodeconfig/", "/etc/ces/nodeconfig"

    # Create a private network, which allows host-only access to the machine
    # using a specific IP.
    main.vm.network "private_network", ip: main_k3s_ip_address

    # Kubernetes API Access
    main.vm.network "forwarded_port", guest: 6443, host: main_k3s_port

    # Define the resources for the virtualbox
    main.vm.provider "virtualbox" do |vb|
      vb.memory = vm_memory
      vb.cpus = vm_cpus
      vb.name = "k3s-main-" + Time.now.to_f.to_s
    end

    main.trigger.before :provision do |trigger|
      if dogu_registry_url == "" || dogu_registry_username == "" || dogu_registry_password == "" ||
        image_registry_email == "" || image_registry_username == "" || image_registry_password == ""
        trigger.info = 'One of the required credentials (dogu- or image registry) is missing!'
        trigger.abort = true
      end
    end

    main.vm.provision "Wait for k3s-conf service to finish",
                      type: "shell",
                      path: "image/scripts/dev/waitForK3sConfService.sh"

    main.vm.provision "Setup main node", type: "shell",
                      path: "image/scripts/dev/mainSetup.sh",
                      args: [
                        dogu_registry_username,
                        dogu_registry_password,
                        dogu_registry_url,
                        image_registry_username,
                        image_registry_password,
                        image_registry_email,
                      ]

    main.vm.provision "Install local Docker registry", type: "shell",
                      path: "image/scripts/dev/docker-registry/main_only_registry.sh",
                      args: [fqdn, docker_registry_namespace]

    main.vm.provision "Run local Docker registry script for all nodes", type: "shell",
                      path: "image/scripts/dev/docker-registry/all_node_registry.sh",
                      args: [fqdn, main_k3s_ip_address]

    if install_setup
      main.vm.provision "Install ces-setup", type: "shell",
                      path: "image/scripts/kubernetes/installLatestK8sCesSetup.sh",
                      args: [docker_registry_namespace]
    end
  end

  (0..(worker_count - 1)).each do |i|
    config.vm.define "worker-#{i}" do |worker|
      worker.vm.hostname = "ces-worker-#{i}"

      worker.vm.box = basebox_name
      worker.vm.box_url = basebox_url
      worker.vm.box_download_checksum = basebox_checksum
      worker.vm.box_download_checksum_type = basebox_checksum_type

      worker.vm.synced_folder "nodeconfig/", "/etc/ces/nodeconfig"

      # Kubernetes API Access
      worker_port = 6444 + i.to_i
      worker.vm.network "forwarded_port", guest: 6443, host: worker_port

      # Create a private network, which allows host-only access to the machine
      # using a specific IP.
      worker_ip_octet = 3 + i.to_i
      worker.vm.network "private_network", ip: "192.168.56.#{worker_ip_octet}"

      # Define the resources for the virtualbox
      worker.vm.provider "virtualbox" do |vb|
        vb.memory = vm_memory
        vb.cpus = vm_cpus
        vb.name = "k3s-worker-#{i}-" + Time.now.to_f.to_s
      end

      worker.vm.provision "Wait for k3s-conf service to finish",
                      type: "shell",
                      path: "image/scripts/dev/waitForK3sConfService.sh"

      worker.vm.provision "Run local Docker registry script for all nodes", type: "shell",
                          path: "image/scripts/dev/docker-registry/all_node_registry.sh",
                          args: [fqdn, "192.168.56.#{worker_ip_octet}"]
     end
   end

  # Use "up" rather than "provision" here because the latter simply does not work.
  config.trigger.after :up do |trigger|
    trigger.info = "Adjusting local kubeconfig..."
    trigger.run = { path: "image/scripts/dev/host/local_kubeconfig.sh", args: [fqdn, main_k3s_ip_address] }
  end
end
