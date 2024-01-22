# -*- mode: ruby -*-
# vi: set ft=ruby :

worker_count = (ENV["K8S_WORKERS"] || "1").to_i
vm_memory = (ENV["K8S_VM_MEMORY"] || "4096").to_i
vm_cpus = (ENV["K8S_VM_CPUS"] || "2").to_i
vm_image = ENV["K8S_VM_IMAGE"] || "bento/ubuntu-20.04"
main_k3s_ip_address = "192.168.56.2"
main_k3s_port = 6443
worker_k3s_network_prefix = "192.168.56"
fqdn = "k3ces.local"
kube_ctx_name= "k3ces.local"
ces_namespace = "ecosystem"
helm_repository_namespace = "k8s"
install_setup = true
dogu_registry_username = ""
dogu_registry_password = ""
dogu_registry_url = ""
dogu_registry_urlschema = "default"
image_registry_url = ""
image_registry_username = ""
image_registry_password = ""
image_registry_email = ""
helm_registry_host = ""
helm_registry_schema = ""
helm_registry_plain_http = ""
helm_registry_username = ""
helm_registry_password = ""
basebox_version = "v2.1.0"
basebox_checksum = "6a4a05be10cca0d1cc852720514cd27c6020e6e4ae83211780779d2180899d53"
basebox_checksum_type = "sha256"
basebox_url = "https://storage.googleapis.com/cloudogu-ecosystem/basebox-mn/" + basebox_version + "/basebox-mn-" + basebox_version + ".box"
basebox_name = "basebox-mn-" + basebox_version

# type of ssl certificate
# - selfsigned: the ces-setup will create a selfsigned certificate
# - mkcert: local mkcert installation will be used to create a certificate
certificate_type = "selfsigned"

# Load gpg encrypted custom configurations from .vagrant.rb.asc file.
# To encrypt an existing .vgarant.rb file run the following command:
# gpg --encrypt --armor --default-recipient-self .vagrant.rb
if File.file?(".vagrant.rb.asc")
  decrypted = `gpg --decrypt .vagrant.rb.asc`
  eval decrypted
end

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
        image_registry_url == "" || image_registry_email == "" || image_registry_username == "" ||
        image_registry_password == "" || helm_registry_host == "" || helm_registry_username == "" ||
        helm_registry_password == "" || helm_registry_schema == "" || helm_registry_plain_http == ""
        trigger.info = 'At least one of the required credentials (dogu-, helm or image registry) is missing!'
        trigger.abort = true
      end
    end

    # configure ssl certificate
    main.trigger.before :up do |trigger|
      if certificate_type == "mkcert"
        # check if mkcert is installed
        if `which mkcert`.empty?
          print "mkcert not found. Please install mkcert and run 'mkcert -install' to install the root certificate.\n\n"
          print "https://github.com/FiloSottile/mkcert\n"
          exit 1
        end

        # create certificates
        if ! File.file?(".vagrant/certs/k3ces.local.crt") || !File.file?(".vagrant/certs/k3ces.local.key")
          `mkdir -p .vagrant/certs`
          `mkcert -cert-file .vagrant/certs/k3ces.local.crt -key-file .vagrant/certs/k3ces.local.key #{fqdn} #{main_k3s_ip_address}`
        end

        # create a copy of the setup.json file and replace the certificate settings
        require 'json'
        setup = JSON.parse(File.read("image/scripts/dev/setup.json"))
        setup["naming"]["certificateType"] = "external"
        setup["naming"]["certificate"] = File.read(".vagrant/certs/k3ces.local.crt")
        setup["naming"]["certificateKey"] = File.read(".vagrant/certs/k3ces.local.key")
        File.write("image/scripts/dev/.setup.json", JSON.pretty_generate(setup))
      else
        # remove geneated .setup.json file, if an old version exists
        if File.file?("image/scripts/dev/.setup.json")
          File.delete("image/scripts/dev/.setup.json")
        end
      end
    end

    main.vm.provision "Wait for k3s-conf service to finish",
                      type: "shell",
                      path: "image/scripts/dev/waitForK3sConfService.sh"

    main.vm.provision "Setup main node", type: "shell",
                      path: "image/scripts/dev/mainSetup.sh"

    main.vm.provision "Install local Docker registry", type: "shell",
                      path: "image/scripts/dev/docker-registry/main_only_registry.sh",
                      args: create_args_string([fqdn, ces_namespace, image_registry_url, image_registry_username, image_registry_password, "/vagrant/image/scripts/dev/docker-registry/docker-registry.yaml"])

    main.vm.provision "Run local Docker registry script for all nodes", type: "shell",
                      path: "image/scripts/dev/docker-registry/all_node_registry.sh",
                      args: create_args_string([fqdn, main_k3s_ip_address])

    main.trigger.before [:halt, :reload] do |trigger|
      trigger.info = "Shutting down k3s..."
      trigger.run_remote = {inline: "/usr/local/bin/k3s-killall.sh"}
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

      worker.vm.network "private_network", ip: "#{worker_k3s_network_prefix}.#{worker_ip_octet}"

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
                          args: create_args_string([fqdn, "#{worker_k3s_network_prefix}.#{worker_ip_octet}"])

      worker.trigger.before [:halt, :reload] do |trigger|
        trigger.info = "Shutting down k3s..."
        trigger.run_remote = {inline: "/usr/local/bin/k3s-killall.sh"}
      end
    end
  end

  # Use "up" rather than "provision" here because the latter simply does not work.
  config.trigger.after :up do |trigger|
    trigger.info = "Adjusting local kubeconfig..."
    trigger.only_on = "main"
    trigger.run = { path: "image/scripts/dev/host/local_kubeconfig.sh",
                    args: create_args_string([fqdn, main_k3s_ip_address, main_k3s_port, kube_ctx_name]) }
  end

  if install_setup
    config.trigger.after :up do |trigger|
      if worker_count > 0
        trigger.only_on = "worker-#{worker_count - 1}"
      else
        trigger.only_on = "main"
      end
      trigger.info = "Install ces-setup"
      trigger.run = { path: "image/scripts/dev/installLatestK8sCesSetup.sh",
                      args: create_args_string([ces_namespace,
                                                helm_repository_namespace,
                                                dogu_registry_username,
                                                dogu_registry_password,
                                                dogu_registry_url,
                                                dogu_registry_urlschema,image_registry_username,
                                                image_registry_password,
                                                image_registry_url,
                                                helm_registry_username,
                                                helm_registry_password,
                                                helm_registry_host,
                                                helm_registry_schema,
                                                helm_registry_plain_http,
                                                kube_ctx_name]) }
    end
  end
end

##### functions #####

# Quote everything in single quotes to escape for shell and escape single quotes with '\''
# (close quoting, add escaped quote and open quoting again,
# see https://stackoverflow.com/questions/15783701/which-characters-need-to-be-escaped-when-using-bash)
def quote_and_escape(text)
  # unless text.is_a?(String)
  #   text = text.to_s
  # end
  "'#{text.to_s.gsub(/'/, "'\\\\''")}'"
end

# This function quotes every single element of the array in single quotes and escapes single quotes inside the element.
# Afterwards the array elements are joined to a string separated by a space and returned.
#
# The intended use of this function is to escape the arguments provided for a shell script in vm.provision. Since
# providing the arguments in an array ignores the quoting, they have to be provided by string.
def create_args_string(arr)
  arr.map{ |elem| quote_and_escape(elem) }.join(" ")
end