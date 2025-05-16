# Netzwerkänderungen auf das Kubernetes Cloudogu EcoSystem anwenden

Das Auflösen von Netzwerkteilen (externe IP-Adresse, FQDN) ist in K8s EcoSystem-VMs eine Herausforderung.
Dieses Dokument beschreibt, worauf zu achten ist, wenn sich IP-Adresse oder FQDN ändern.

## Externe IP-Adresse anpassen

Die externe IP-Adresse wird dem systemd-Dienst "k3s" beim Starten durch Lesen der
[Knotenkonfigurationsdatei](configuring_main_and_worker_nodes_de.md). Dies ist die einzige Möglichkeit, wie `k3s`
eine externe IP-Adresse für seine Knoten bereitstellen kann, um eine Verbindung zu den `LoadBalancer`-Diensten von K8s zu
ermöglichen.

**Vorsicht!**
Grundsätzlich ist eine IP-Adressänderung mit einer gewissen Ausfallzeit verbunden, da der `k3s` systemd-Dienst neu
gestartet werden muss!

Nach erfolgreicher Änderung ist es ratsam, eine neue Browsersitzung im Cloudogu EcoSystem zu starten und ein
beliebiges Dogu aufzurufen.

### 2. Manuelle Anpassung

Wenn ein Neustart der VM im laufenden Betrieb nicht notwendig/möglich erscheint, kann derselbe Vorgang mit folgendem
Befehl durchgeführt werden:

```bash
sudo systemctl restart k3s-conf
```

## Anpassen des FQDN in SSL-Zertifikaten

Der FQDN ist eine Schlüsselkomponente des Cloudogu EcoSystems. Wenn sich der FQDN ändert, ist es zwingend erforderlich,
den FQDN in der lokalen Registry und den zugehörigen SSL-Zertifikaten anzupassen.

Die Konfiguration des FQDN im CES kann wie folgt geändert werden:

```bash
kubectl get configmap global-config -n ecosystem -o yaml | \
yq eval '.data["config.yaml"] |= (from_yaml | .fqdn = "your.new.fqdn" | to_yaml)' - | \
kubectl apply -f -
```

Gegebenenfalls müssen auch die eigenen DNS- oder `/etc/hosts`-Einträge an den neuen FQDN angepasst werden.

Wie die SSL-Zertifikate aktualisiert werden, hängt von der Qualität der SSL-Zertifikate ab, d.h. ob sie selbst
generiert oder von einem externen Zertifikatsaussteller stammen.

### Selbst erstellte SSL-Zertifikate

Falls ein selbst erstelltes Zertifikat verwendet wird (`global-config` -> `certificate/type` : `selfsigned`), generiert die `k8s-service-discovery` ein neues Zertifikat, sobald der FQDN angepasst wird.
Die `k8s-service-discovery` schreibt das selbst generierte Zertifikat in das Secret `ecosystem-certificate`.
Dieses Secret wird von `k8s-service-discovery` reconciled und das Zertifikat in die `global-config` geschrieben.
Nach der Anpassung der FQDN und des Zertifikats müssen alle Dogus neu gestartet werden.

### Zertifikate von externen Herausgebern

Ersetzen Sie Zertifikate und alle Zwischenzertifikate in `ecosystem-certificate` Secret
1. Löschen des Secrets `k delete secret ecosystem-certificate -n ecosystem`
2. Erstellen des Secrets mit neuem Zertifikat
    ```bash
    kubectl create secret generic ecosystem-certificate \
    --from-literal=tls.crt="IHRE ZERTIFIKATE HIER" \
    --from-literal=tls.key="IHR ZERTIFIKATSSCHLÜSSEL"
    ```
3. Starten Sie alle Dogus neu.
