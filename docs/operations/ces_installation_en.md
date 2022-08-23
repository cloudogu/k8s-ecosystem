# Installation of the Cloudogu EcoSystem

After the CES image has been created as described in the corresponding [instructions](../development/image_build_en.md)
the CES can now be started and administered in the following way:

- Import the CES image in the hypervisor
    - If necessary the hardware settings should be increased depending upon intended use
- Start the virtual machine
- Establishing an SSH connection as described
  in [SSH authentication on the Cloudogu EcoSystem](ssh_authentication_en.md)
- Extracting the cluster configuration
    - The configuration is available as a yaml file inside the VM at `/etc/rancher/k3s/k3s.yaml`.
- Using the cluster configuration on the host
    - Save the cluster configuration on the host, e.g. as `~/.kube/k3s.yaml`.
    - Set Kubeconfig, e.g. via `export KUBECONFIG=~/.kube/k3s.yaml`.
    - Test the configuration, e.g. via `kubectl get all --all-namespaces`.
- Start installation
    - The installation process is described here:
      https://github.com/cloudogu/k8s-ces-setup/blob/develop/docs/operations/installation_guide_en.md
