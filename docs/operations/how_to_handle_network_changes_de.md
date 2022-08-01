# Netzwerkänderungen auf das Kubernetes Cloudogu EcoSystem anwenden

Die Auflösung von Netzwerkteilen (externe IP-Adresse, FQDN) stellt im K8s-EcoSystem-VMs eine Herausforderung dar.
Dieses Dokument beschreibt, worauf geachtet werden sollte, wenn sich IP-Adresse oder FQDN ändern.

## Externe IP-Adresse anpassen

Die externe IP-Adresse wird dem `k3s`-systemd-Dienst beim Start mitgegeben. Nur so kann `k3s` eine externe IP-Adresse
seinen Knoten mitgeben, sodass eine Konnektivität bzgl. von K8s `LoadBalancer`-Services ermöglicht werden kann.

**Vorsicht:**
Grundsätzlich ist eine IP-Adressen-Änderung mit einer gewissen Downtime verbunden, da der `k3s`-systemd-Dienst neu
gestartet werden muss!

Nach erfolgreicher Änderung ist es ratsam, eine neue Browsersitzung im Cloudogu EcoSystem zu starten und ein beliebiges
Dogu aufzurufen.

### 1. Automatische Anpassung bei VM-Neustart (VERALTET)

Um die Anpassung zu vereinfachen, existiert ein eigener Dienst `k3s-ipchanged`. Dieser Dienst sorgt dafür, dass bei
jedem VM-Neustart die externe IP-Adresse eines Netzwerkinterfaces bezogen. Damit wird der `k3s`-Dienst angereichert und
neu gestartet.

### 2. Manuelle Anpassung

Sollte ein Neustart der VM im laufenden Betrieb nicht nötig/möglich erscheinen, so lässt sich der gleiche Vorgang
mittels dieses Kommandos durchführen:

```bash
sudo /usr/sbin/k3s-ipchanged.sh
```

## FQDN in SSL-Zertifikaten anpassen

Die FQDN ist ein zentraler Bestandteil des Cloudogu EcoSystems. Wenn die FQDN sich ändert, muss zwingend die FQDN in der
lokalen Registry und die dazugehörigen SSL-Zertifikate angepasst werden.

Die Konfiguration der FQDN im CES lässt sich wie folgt ändern:

```bash
kubectl exec -it etcd-client -- etcdctl set /config/_global/fqdn your.new.fqdn
```

Ggf. müssen eigene DNS- oder `/etc/hosts`-Einträge ebenfalls auf die neue FQDN angeglichen werden.

Wie die SSL-Zertifikate aktualisiert werden, hängt von der Qualität der SSL-Zertifikate ab -- also ob diese selbst
erzeugt wurden oder von einem externen Zertifikatsaussteller.

### Selbst erzeugte SSL-Zertifikate

1. [SSL-Template](https://github.com/cloudogu/ces-commons/blob/develop/deb/etc/ces/ssl.conf.tpl) herstellen
2. Zertifikat und Key erzeugen (
   vergleiche [`ces-commons`](https://github.com/cloudogu/ces-commons/blob/develop/deb/usr/local/bin/ssl.sh))
3. Zertifikate sowie alle Intermediate Zertifikate im `etcd` austauschen
    1. `kubectl exec -it etcd-client -- etcdctl set /config/_global/certificate/server.crt "YOUR CERTIFICATES HERE"`
    2. `kubectl exec -it etcd-client -- etcdctl set /config/_global/certificate/server.key "YOUR CERTIFICATE KEY"`
4. Alle Dogus neu starten

### Zertifikate von externen Ausstellern

1. Zertifikate sowie alle Intermediate Zertifikate im `etcd` austauschen
    1. `kubectl exec -it etcd-client -- etcdctl set /config/_global/certificate/server.crt "YOUR CERTIFICATES HERE"`
    2. `kubectl exec -it etcd-client -- etcdctl set /config/_global/certificate/server.key "YOUR CERTIFICATE KEY"`
2. Alle Dogus neu starten
