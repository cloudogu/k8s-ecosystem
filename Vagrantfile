# -*- mode: ruby -*-
# vi: set ft=ruby :

worker_count = (ENV["K8S_WORKERS"] || "1").to_i
vm_memory = (ENV["K8S_VM_MEMORY"] || "2048").to_i
vm_cpus = (ENV["K8S_VM_CPUS"] || "2").to_i
vm_image = ENV["K8S_VM_IMAGE"] || "bento/ubuntu-20.04"
main_k3s_ip_address = "192.168.56.2"
main_k3s_port = 6443
k3s_server_token = ENV["K3S_TOKEN"] || "MySecretToken1!"
fqdn = "k3s.local"
docker_registry_namespace = "ecosystem"
dogu_registry_username = ""
dogu_registry_password = ""
dogu_registry_url = ""
image_registry_username = ""
image_registry_password = ""
image_registry_email = ""

# Load custom configurations from .vagrant.rb file, if existent
if File.file?(".vagrant.rb")
  eval File.read(".vagrant.rb")
end

Vagrant.configure("2") do |config|
  # requires plugin vagrant-disksize
  #config.disksize.size = '80GB'

  config.vm.define "main", primary: true do |main|
    main.vm.hostname = "ces-main"

    main.vm.box = "testk8sMain"

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

    # main.vm.provision "Install local Docker registry", type: "shell",
    #                   path: "docker-registry/main_only_registry.sh",
    #                   args: [fqdn, docker_registry_namespace]

    # main.vm.provision "Run local Docker registry script for all nodes", type: "shell",
    #                   path: "docker-registry/all_node_registry.sh",
    #                   args: [fqdn]

    # main.vm.provision "Install ces-setup", type: "shell",
    #                   path: "ces-setup-installation.sh"

  end

  (0..(worker_count - 1)).each do |i|
    config.vm.define "worker-#{i}" do |worker|
      worker.vm.hostname = "ces-worker-#{i}"

      worker.vm.box = "testk8sWorker"

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

      # Run some setup script to install K3s on he VM
      worker.vm.provision "Install k3s", type: "shell",
                          path: "image/scripts/dev/k3s-worker.sh", args: [
          "192.168.56.#{worker_ip_octet}",
          main_k3s_ip_address,
          main_k3s_port,
          k3s_server_token
        ]

  #     worker.vm.provision "Install dependencies", type: "shell",
  #                         path: "dependencies.sh"

  #     worker.vm.provision "Run local Docker registry script for all nodes", type: "shell",
  #                         path: "docker-registry/all_node_registry.sh",
  #                         args: [fqdn]

     end
   end

  # # Use "up" rather than "provision" here because the latter simply does not work.
  # config.trigger.after :up do |trigger|
  #   trigger.info = "Run ./setup.sh locally to adjust local kubeconfig..."
  #   trigger.run = { path: "./setup.sh", args: [fqdn, docker_registry_namespace] }
  # end
end
