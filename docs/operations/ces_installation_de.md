# Installation des Cloudogu EcoSystem

Nachdem das CES-Image wie in der entsprechenden [Anleitung](../development/image_build_de.md) beschrieben
erstellt wurde, kann das CES nun auf die folgende Art und Weise gestartet und administriert werden:

- Importieren des CES-Images im Hypervisor
    - Dabei sollten die Hardware-Einstellungen je nach Einsatzzweck ggf. erhöht werden
- Starten der virtuellen Maschine
- Einrichtung einer SSH-Verbindung wie in [SSH-Authentifizierung am Cloudogu EcoSystem](ssh_authentication_de.md)
  beschrieben
- Auslesen der Cluster-Konfiguration
    - Die Konfiguration steht als yaml-Datei in der VM unter `/etc/rancher/k3s/k3s.yaml` bereit
- Nutzen der Cluster-Konfiguration auf dem Host
    - Speichern der Cluster-Konfiguration auf dem Host, bspw. als `~/.kube/k3s.yaml`
    - Kubeconfig setzen, bspw. via `export KUBECONFIG=~/.kube/k3s.yaml`
    - Testen der Konfiguration, bspw. via `kubectl get all --all-namespaces`
- Installation beginnen
    - Der Installationsprozess ist hier beschrieben:
      https://github.com/cloudogu/k8s-ces-setup/blob/develop/docs/operations/installation_guide_de.md
