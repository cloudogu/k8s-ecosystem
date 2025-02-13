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

1. create [SSL template](https://github.com/cloudogu/ces-commons/blob/develop/deb/etc/ces/ssl.conf.tpl)
2. generate certificate and key (
   see [`ces-commons`](https://github.com/cloudogu/ces-commons/blob/develop/deb/usr/local/bin/ssl.sh))
3. exchange certificates and all intermediate certificates in `global-config` configmap
   1.
   ```
   kubectl get configmap global-config -n ecosystem -o yaml | \
   yq eval '.data["config.yaml"] |= (from_yaml | .certificate["server.crt"] = "IHRE ZERTIFIKATE HIER" | to_yaml)' - | \
   kubectl apply -f -
   ```
   2.
   ```
   kubectl get configmap global-config -n ecosystem -o yaml | \
   yq eval '.data["config.yaml"] |= (from_yaml | .certificate["server.key"] = "IHR ZERTIFIKATSSCHLÜSSEL" | to_yaml)' - | \
   kubectl apply -f -
   ```4. restart all dogus

### Certificates from external issuers

1. replace certificates and all intermediate certificates in `global-config` configmap
   1.
   ```
   kubectl get configmap global-config -n ecosystem -o yaml | \
   yq eval '.data["config.yaml"] |= (from_yaml | .certificate["server.crt"] = "IHRE ZERTIFIKATE HIER" | to_yaml)' - | \
   kubectl apply -f -
   ```
   2.
   ```
   kubectl get configmap global-config -n ecosystem -o yaml | \
   yq eval '.data["config.yaml"] |= (from_yaml | .certificate["server.key"] = "IHR ZERTIFIKATSSCHLÜSSEL" | to_yaml)' - | \
   kubectl apply -f -
   ```2. restart all dogus
