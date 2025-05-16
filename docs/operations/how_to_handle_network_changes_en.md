# Apply network changes to the Kubernetes Cloudogu EcoSystem.

Resolving network parts (external IP address, FQDN) is challenging in K8s EcoSystem VMs. This document describes what to
look for when IP address or FQDN change.

## Adjust external IP address

The external IP address is given to the `k3s` systemd service at startup by reading
the [node configuration file](configuring_main_and_worker_nodes_en.md). This is the only way `k3s` can provide an
external IP address to its nodes to allow connectivity to K8s' `LoadBalancer` services.

**Caution!**
Basically an IP address change involves some downtime, because the `k3s` systemd service has to be restarted!

After successful change it is advisable to start a new browser session in Cloudogu EcoSystem and call any dogu.

### 1. Manual adjustment

If restarting the VM while it is running does not seem necessary/possible, the same operation can be performed using
this command:

```bash
sudo systemctl restart k3s-conf
```

## Adjust FQDN in SSL certificates

The FQDN is a key component of the Cloudogu EcoSystem. If the FQDN changes, it is mandatory to adjust the FQDN in the
local registry and the associated SSL certificates.

The configuration of the FQDN in the CES can be changed as follows:

```bash
kubectl get configmap global-config -n ecosystem -o yaml | \
yq eval '.data["config.yaml"] |= (from_yaml | .fqdn = "your.new.fqdn" | to_yaml)' - | \
kubectl apply -f -
```

If necessary, own DNS or `/etc/hosts` entries must also be adjusted to the new FQDN.

How the SSL certificates are updated depends on the quality of the SSL certificates, i.e. whether they are
self-generated or from an external certificate issuer.

### Self-generated SSL certificates

If a self-generated certificate is used (`global-config` -> `certificate/type` : `selfsigned`), the `k8s-service-discovery` generates a new certificate as soon as the FQDN is adjusted.
The `k8s-service-discovery` writes the self-generated certificate to the `ecosystem-certificate` secret.
This secret is reconciled by `k8s-service-discovery` and the certificate is written to the `global-config`.
1. restart all Dogus.

### Certificates from external issuers

Replace certificates and all intermediate certificates in `ecosystem-certificate` Secret
1. delete the secret `k delete secret ecosystem-certificate -n ecosystem`.
2. create the secret with a new certificate
```
k create secret generic ecosystem-certificate \
--from-literal=tls.crt="YOUR CERTIFICATES HERE’ \
--from-literal=tls.key="YOUR CERTIFICATE KEY’
```

3. restart all Dogus.

Translated with DeepL.com (free version)
