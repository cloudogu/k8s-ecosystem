# Netzwerkänderungen auf das Kubernetes Cloudogu EcoSystem anwenden.

Das Auflösen von Netzwerkteilen (externe IP-Adresse, FQDN) ist in K8s EcoSystem-VMs eine Herausforderung. Dieses
Dokument beschreibt, worauf Sie zu beachten ist, wenn sich IP-Adresse oder FQDN ändern.

## Externe IP-Adresse anpassen

Die externe IP-Adresse wird dem systemd-Dienst "k3s" beim Starten durch Lesen der
die [Knotenkonfigurationsdatei](configuring_main_and_worker_nodes_de.md). Dies ist die einzige Möglichkeit, wie `k3s`
eine externe IP-Adresse für seine Knoten bereitstellen, um eine Verbindung zu den `LoadBalancer`-Diensten von K8 zu
ermöglichen.

**Vorsicht!**
Grundsätzlich ist eine IP-Adressänderung mit einer gewissen Ausfallzeit verbunden, da der `k3s` systemd-Dienst neu
gestartet werden muss!

Nach erfolgreicher Änderung ist es ratsam, eine neue Browsersitzung im Cloudogu EcoSystem zu starten und einen
beliebigen dogu aufzurufen.

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
kubectl exec -it etcd-client -- etcdctl set /config/_global/fqdn your.new.fqdn
```

Gegebenenfalls müssen auch die eigenen DNS- oder `/etc/hosts`-Einträge an den neuen FQDN angepasst werden.

Wie die SSL-Zertifikate aktualisiert werden, hängt von der Qualität der SSL-Zertifikate ab -- d.h. ob sie selbst
generiert oder von einem externen Zertifikatsaussteller stammen.

### Selbst erstellte SSL-Zertifikate

1. [SSL-Vorlage] erstellen (https://github.com/cloudogu/ces-commons/blob/develop/deb/etc/ces/ssl.conf.tpl)
2. Zertifikat und Schlüssel generieren (
   vergleiche [`ces-commons`](https://github.com/cloudogu/ces-commons/blob/develop/deb/usr/local/bin/ssl.sh))
3. Zertifikate und alle Zwischenzertifikate in `etcd` austauschen
    1. kubectl exec -it etcd-client -- etcdctl set /config/_global/certificate/server.crt "IHRE ZERTIFIKATE HIER"`.
    2. kubectl exec -it etcd-client -- etcdctl set /config/_global/certificate/server.key "IHR ZERTIFIKATSSCHLÜSSEL"`
4. Starten Sie alle Hunde neu.

### Zertifikate von externen Herausgebern

1. Ersetzen Sie Zertifikate und alle Zwischenzertifikate in `etcd
    1. kubectl exec -it etcd-client -- etcdctl set /config/_global/certificate/server.crt "IHRE ZERTIFIKATE HIER"`
    2. kubectl exec -it etcd-client -- etcdctl set /config/_global/certificate/server.key "IHR ZERTIFIKATSCHLÜSSEL"`
2. Starten Sie alle Dogus neu.
