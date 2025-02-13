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

1. [SSL-Vorlage] erstellen (https://github.com/cloudogu/ces-commons/blob/develop/deb/etc/ces/ssl.conf.tpl)
2. Zertifikat und Schlüssel generieren (
   siehe [`ces-commons`](https://github.com/cloudogu/ces-commons/blob/develop/deb/usr/local/bin/ssl.sh))
3. Zertifikate und alle Zwischenzertifikate in `global-config` Configmap austauschen
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
      ```
4. Starten Sie alle Dogus neu.

### Zertifikate von externen Herausgebern

1. Ersetzen Sie Zertifikate und alle Zwischenzertifikate in `global-config` Configmap
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
   ```
2. Starten Sie alle Dogus neu.
