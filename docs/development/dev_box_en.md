# Dev Box

This document contains the necessary information to start the development basebox locally with Vagrant.
Instructions for building the image for the development basebox can be found [here](./building_basebox_en.md).

### Preconditions

#### Applications

The following applications must be installed:

- [kubectl](https://kubernetes.io/de/docs/tasks/tools/install-kubectl/) - Command line tool for managing the Kubernetes cluster
- [Helm](https://helm.sh/docs/intro/quickstart/) - package manager for Kubernetes

The following applications are recommended for easier handling:

- [kubectx + kubens](https://github.com/ahmetb/kubectx) - Easier switching between Kubernetes contexts and namespaces
- [k9s](https://k9scli.io/topics/install/) - UI (in the terminal) for easier management of the cluster

#### File system

- If necessary, the folder `~/.kube` must be created
- Add the following entry to `/etc/hosts`: `192.168.56.2 k3ces.local`
- Set environment variable: `export KUBECONFIG=~/.kube/config:~/.kube/k3ces.local`
- add the following entry to `/etc/docker/daemon.json`: `{ "insecure-registries": ["k3ces.local:30099"] }`
  (required to push custom images to the Helm registry during development)

### Configuration

The configuration for the dev box is done via a `.vagrant.rb` file. There is a template file `.vagrant.rb.template`,
which can serve as a good starting point. The `.vagrant.rb` file is read in from the `Vagrantfile` and can
overwrite the configuration values from the `Vagrantfile`.

**To ensure that special characters are treated literally by the Vagrantfile or subsequent shell scripts, please provide 
the information quoted in single quotes ('). Double quotes (") and backslashes (\) lead to problems and must not be 
used! Any single quotes within your information must be escaped with a backslash (\\'). [See here for an explanation.](https://en.wikibooks.org/wiki/Ruby_Programming/Strings#Single_quotes)**

The following configuration values can be specified (among others):

| value                    | description                                                 |
|--------------------------|-------------------------------------------------------------|
| dogu_registry_url        | The URL of the dogu registry                                |
| dogu_registry_username   | The username to login to the dogu registry                  |
| dogu_registry_password   | The password to login to the dogu Registry                  |
| image_registry_url       | The URL of the image registry                               |
| image_registry_username  | The username to login to the image registry                 |
| image_registry_password  | The password to login to the image registry                 |
| image_registry_email     | The e-mail address of the image registry user               |
| helm_registry_host       | The host of the helm registry                               |
| helm_registry_schema     | The schema of the helm registry                             |
| helm_registry_plain_http | Is the helm registry accessed via HTTP or HTTPS?            |
| helm_registry_username   | The username to login to the helm registry                  |
| helm_registry_password   | The password to login to the helm registry                  |
| vm_memory                | The VMs memory                                              |
| vm_cpus                  | The number of CPUs in the VMs                               |
| worker_count             | The number of worker nodes of the cluster                   |
| main_k3s_ip_address      | The IP address of the main node of the cluster              |
| certificate_type         | `selfsigned` or `mkcert`; see [certificates](#certificates) |

#### Encryption of the configuration

Since the configuration contains sensitive data, it should not be stored in plain text.
Therefore it is possible to encrypt the data with `gpg` and the Yubi key and store it this way.
If encrypted configuration data is present, it will be decrypted from the `vagrantfile` with `gpg` and the Yubi key.

To encrypt the configuration in the `.vagrant.rb` file, the following command must be executed:

```shell
gpg --encrypt --armor --default-recipient-self .vagrant.rb

```

The encrypted file is named `.vagrant.rb.asc`.

Then the unencrypted `.vagrant.rb` file can be deleted.

The following command can be used to decrypt it:

```shell
gpg --decrypt .vagrant.rb.asc > .vagrant.rb
```

> **Note:** If changes are made to the `.vagrant.rb`, it must be re-encrypted and then deleted!

### Certificates

In the DEV box the CES setup creates a self-signed SSL certificate by default to secure the HTTPS connections.
This has the disadvantage that browsers do not trust this certificate and exceptions have to be set up in the browser
for this.
To avoid this, a certificate can be used for development when creating the dev box, which can be created with the
tool [mkcert](https://github.com/FiloSottile/mkcert).
This certificate is trusted locally on the development computer.

After `mkcert`[installed](https://github.com/FiloSottile/mkcert#installation) is installed, it must be initialized once
with the following command:

```shell
mkcert -install
```

Then in the [configuration](#configuration) the value for `certificate_type` can be set to `mkcert`.
If no certificate exists yet, the `vagrantfile` then creates a new certificate with `mkcert` which is used by the CES.