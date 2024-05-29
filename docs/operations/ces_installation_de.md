# Setup eines Cloudogu EcoSystem in Kubernetes

Dieses Dokument beschreibt im Detail, wie das Cloudogu EcoSystem in einem Kubernetes Cluster installiert wird.
Trivialerweise wird für die Installation ein Kubernetes Cluster benötigt.

Falls es keine Option ist, einen Cluster bei einem externen Cloud-Provider zu betreiben, bietet Cloudogu ein OVF an,
welches für die Verwendung von Main- **und** Worker-Nodes verwendet wird. Darin wird die Kubernetes-Implementierung
 [`k3s`](https://docs.k3s.io/) mit [`longhorn`](https://longhorn.io/docs/) als Storage-Provisioner verwendet. Bei externen Cloud-Anbietern kann `longhorn` ebenfalls
als Storage-Provisioner verwendet werden. Empfohlen werden allerdings die internen Provisioner der Cloud-Provider.

Dieses Dokument zeigt, welche Komponenten installiert und konfiguriert werden müssen. Dabei wird zwischen dem Setup eines
Kubernetes-Cluster und dem des eigentlichen Cloudogu EcoSystems innerhalb des Clusters unterschieden.
Daraufhin werden stichpunktartig Voraussetzungen gelistet, um eine Installation vorzubereiten.
Danach folgt die eigentliche Installationsanleitung mit Hinweisen für verschiedene Betriebsumgebungen wie z. B. Google oder Microsoft.

## 1. Was ist zu installieren/konfigurieren?

### Kubernetes Cluster Setup mit Cloudogu K3s-Image

Diese Option ist geeignet, wenn externe Cloud-Provider keine Option darstellt. Ansonsten kann ab Abschnitt 2. weiter gearbeitet werden.

- `k3sConfig.json`
  - Eine Konfiguration, die Informationen über alle Nodes des Clusters enthält. Sie wird von einem Service ausgelesen, der `k3s` konfiguriert.
  - Diese Datei enthält:
    - Token als gemeinsames Geheimnis zur gegenseitigen Node-Anmeldung im Cluster,
    - IP-Adressen der verwendeten Maschinen und
    - Registry-Konfigurationen
  - Das File muss in **jeden** Node gemounted werden.
- `authorized_keys`
  - Zum Debuggen kann es nützlich sein, SSH-Zugriff auf jeden Node zu erlangen. Hierbei muss in jedem Node eine Liste von akzeptierten Keys gemounted werden.

### Cloudogu EcoSystem Setup

- Namespace: `ecosystem`
- Helm-Chart `k8s-ces-setup` mit Konfiguration von `values.yaml`:
  - Secret: `k8s-dogu-operator-docker-registry` - enthält Credentials zur verwendeten Image-Registry.
  - Secret: `k8s-dogu-operator-dogu-registry` - enthält Credentials zur verwendeten Dogu-Registry.
  - Secret: `component-operator-helm-registry` - enthält Credentials zur verwendeten Helm-Registry für CES-Komponenten.
  - Configmap: `component-operator-helm-repository` - enthält URL zur verwendeten Helm-Registry für CES-Komponenten.
  - Configmap: `k8s-ces-setup-config` - enthält Konfiguration für das Setup unter anderem Versionen von CES Komponenten z. B. Dogu-Operator, die installiert werden sollen.
  - Configmap: `k8s-ces-setup-json` - enthält Konfiguration für das Setup unter anderem FQDN oder Dogu-Versionen.

## 2. Vorbereitung

### Welche Informationen werden benötigt

- Docker-Registry-Credentials
  - URL: registry.cloudogu.com
  - Username
  - Password
- Dogu-Registry-Credentials
  - URL: https://dogu.cloudogu.com/api/v2/dogus
  - Username
  - Password
- Helm-Registry-Credentials
  - URL: https://registry.cloudogu.com
  - Username
  - Password

## 3. Installationsanleitung

Soll das Cloudogu EcoSystem auf einem schon bestehenden Cluster installiert werden, kann mit [Cloudogu EcoSystem Installation](#cloudogu-ecosystem-installation) fortgefahren werden.

### Cluster Setup mit K3s Image

Für die Bereitstellung des OVF kontaktieren Sie bitte hello@cloudogu.com.

#### Nodes Anlegen

- Alle Nodes des zukünftigen Clusters aus dem gelieferten Image erzeugen, aber noch nicht starten.

#### k3sConfig.json installieren

- Zu jedem Node muss ein vollständiger Eintrag im `nodes` Bereich vorhanden sein.
- Die Docker-Registry (Harbor) muss im `docker-registry-configuration` Bereich konfiguriert sein.
  - `k3s-token` muss neu gewählt werden.
  - IPs und Interfaces der Knoten müssen entsprechend angepasst werden.
- Die `k3sConfig.json` muss in jeden Node in `/etc/ces/nodeconfig/k3sConfig.json` gemounted werden.

Beispiel für einen Cluster aus einem Main-Node und drei Worker-Nodes:

```json
{
   "ces-namespace":"ecosystem",
   "k3s-token":"SuPeR_secure123!TOKEN-Changeme",
   "nodes":[
      {
         "name":"ces-main",
         "isMainNode":true,
         "node-ip":"192.168.2.101",
         "node-external-ip":"192.168.2.101",
         "flannel-iface":"eth0"
      },
      {
         "name":"ces-worker-0",
         "node-ip":"192.168.2.96",
         "node-external-ip":"192.168.2.96",
         "flannel-iface":"eth0"
      },
      {
         "name":"ces-worker-1",
         "node-ip":"192.168.2.91",
         "node-external-ip":"192.168.2.91",
         "flannel-iface":"eth0"
      },
      {
         "name":"ces-worker-2",
         "node-ip":"192.168.2.102",
         "node-external-ip":"192.168.2.102",
         "flannel-iface":"eth0",
         "node-labels": ["foo=bar", "foo/bar.io=muh"],
         "node-taints": ["key1=value1:NoExecute"]
      }
   ]
}
```

> Info: Die verwendeten Node-Labels und -Taints sind optional und können pro Node konfiguriert werden.
> Weitere Hinweise zur Verwendung sind [hier für Labels](https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes/) und [hier für Taints](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) zu finden.

Wenn eine abgeschottete Umgebung verwendet wird, bei der Docker- und Dogu-Registry gespiegelt sind,
muss hier ein Mirror für die Docker-Registry konfiguriert werden.

Beispiel für die Registry-Einrichtung für gespiegelte Images:

```json
{
   "ces-namespace":"ecosystem",
   "k3s-token":"SuPeR_secure123!TOKEN-Changeme",
   "nodes":[
     ...
   ],
   "docker-registry-configuration":{
      "mirrors":{
         "docker.io":{
            "endpoint":[
               "https://<registry-url>"
            ]
         }
      },
      "configs":{
         "<registry-url>":{
            "auth":{
               "username":"user1",
               "password":"password1"
            }
         }
      }
   }
}
```

- Eine ausführliche Dokumentation zur `k3sConfig.json` ist [hier](https://github.com/cloudogu/k8s-ecosystem/blob/develop/docs/operations/configuring_main_and_worker_nodes_de.md) zu finden.

#### SSH-Pub-Key(s) mounten

- Alle Public Keys, die in den Nodes für den SSH-Zugang zum Einsatz kommen sollen, in eine Datei `authorized_keys` schreiben.
- Jeden Node des Clusters so anpassen, dass beim Start die `authorized_keys`-Datei nach `/etc/ces/authorized_keys` gemountet wird.
- Weitere Informationen sind [hier](https://github.com/cloudogu/k8s-ecosystem/blob/develop/docs/operations/ssh_authentication_de.md) zu finden.

Beispiel:

```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDY0nVMmCeczF8jLAwnw3PNGMMAlqskpw8lfJuZeTIrAklIIeVqXmaHaCDbC+Z+/WYtp/5A9H8V6MDz7pMyrTCnm8g6nKZ0J/kH+kP8iT9f1d2V78AG1P3v6R19UeT8h3926bB/IJGmnzo53gnfdV+YhSEwsIGFI3ikzjc0GOZBAvhCLPo6WXAbcvM5+qVTFUjkQwi6lQBjtS/cIZJrcB9J9bLNJbait5itaXLyLy52Igt8dQbzB5hnvlBwUuFHnt0agXF0yxb+VVRzF0BVZ0rE0MKwCiG/mwbspIDOhuMj5DwtRiSC0LtNCn9V46cuDy1lrsUvO2g1mo3ptbhEAxv+UAStbDKkgSvKDfK3Q0AdLE6+AgZ/EehcRQvo10W5lY6JOm5PcHstFQLy4g660IiOrxrSN5HCZmRzeU49vT4o3tYxXsxSebxvumOmmnHlZUczZbRbEiSJ5L7RLRhQpJ4adkGuPWEyXXYsQtlgOlmBUZnEm9N8oaNIlknW5lUV4ZyRMAL7VdMgvwZDaqWgl1JZpp9Np3WKWizzuOOZm6jlZW3Sbsyr8Lw3SZXYSCU03gx+YZFGk+1zmwvtCp86i7gzH6lpami8mAHfEWVqaZoHWBlCU35gqaUscvWEJ7KMtQNCdHV8tMEE5IFSfigXgQjfsiqj6v+detsN+uN31PepxQ== SSHuser123
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCJi7dJnW9zB3m5iakfUwmntYLahA82WqYKM3f9VQhbpwI93zBD2SPrvH02TtEVgGvyW3oR7RMVbAOf0YEe5F6GM3qxL8r1uhitrOqblDCAz8xyVz1GfWy3v+5hMXyN3/yFpTmm8QK1V9xdIKdMcxGn5CdEpMHSODs1X7CIxs2fZ2Kw4kzCOY064+wfwGpnaJhbABpNnEudLAHkphZWSB0wF0kVrcU4GJaDH8Hr9fbkc/rPChGQ9DvFNHUGdvWTSL3tDkmfSk+EdzHU1rwZxHAhGVz2SlwLGWs7zS9YrpbF7xyuOT7GhR9ZRH4Ef1fPxHjztTIbu74mC+PdPf/Odm/ john.doe@example.net
```

#### Nodes hochfahren

- Beginnend mit dem Main-Node alle Nodes hochfahren.
- Die Installationsroutinen, die den Kubernetes-Cluster initialisieren, lassen sich via `journalctl -f -u k3s-conf.service` verfolgen.
- Ob alle Nodes im Cluster verfügbar sind, lässt sich via `kubectl get nodes` erkennen.
- Ob alle Pods erfolgreich gestartet wurden, lässt sich mit `kubectl get pods` erkennen.
  - Alternativ kann das grafische Tool `k9s` verwendet werden. Allgemeine Information zur grafischen Kubernetesverwaltung im Terminal k9s gibt es hier: [https://k9scli.io/](https://k9scli.io/)

#### Kubeconfig setzen

Damit für weitere Schritte auf dem Host gearbeitet werden kann, ist es sinnvoll die Cluster-Konfigurationen zu kopieren:
- Die Konfiguration steht als yaml-Datei in der VM unter `/etc/rancher/k3s/k3s.yaml` bereit
- Nutzen der Cluster-Konfiguration auf dem Host
  - Speichern der Cluster-Konfiguration auf dem Host, bsp. als `~/.kube/k3s.yaml`
  - Konfiguration setzen, bsp. via `export KUBECONFIG=~/.kube/k3s.yaml`
  - Testen der Konfiguration, bsp. via `kubectl get all --all-namespaces`

Mit dieser Kubeconfig lässt sich auch von anderen Maschinen auf den Cluster zugreifen.

### Cloudogu EcoSystem Installation

### Erstellung des Namespaces

`kubectl create namespace ecosystem`

### Konfiguration von Helm-Values

Das Cloudogu EcoSystem wird mit dem Package-Manager [`helm`](https://helm.sh/) installiert. Für die Installation
müssen benötigte Credentials mit einem `values.yaml` File konfiguriert werden.

Minimales Beispiel:

```yaml
docker_registry_secret:
  url: https://registry.cloudogu.com
  username:
  password:

dogu_registry_secret:
  url: https://dogu.cloudogu.com/api/v2/dogus
  username:
  password:

helm_registry_secret:
  url: https://registry.cloudogu.com
  username:
  password:

# Example test setup.json
#setup_json:
#  {
#    "naming": {
#      "fqdn": "",
#      "domain": "k3ces.local",
#      "certificateType": "selfsigned",
#      "relayHost": "yourrelayhost.com",
#      "useInternalIp": false,
#      "internalIp": ""
#      "completed": true,
#    },
#    "dogus": {
#      "defaultDogu": "cas",
#      "install": [
#        "official/ldap",
#        "official/postfix",
#        "k8s/nginx-static",
#        "k8s/nginx-ingress",
#        "official/cas"
#      ],
#      "completed": true
#    },
#    "admin": {
#      "username": "admin",
#      "mail": "admin@admin.admin",
#      "password": "adminpw",
#      "adminGroup": "cesAdmin",
#      "adminMember": true,
#      "sendWelcomeMail": false,
#      "completed": true
#    },
#    "userBackend": {
#      "dsType": "embedded",
#      "server": "",
#      "attributeID": "uid",
#      "attributeGivenName": "",
#      "attributeSurname": "",
#      "attributeFullname": "cn",
#      "attributeMail": "mail",
#      "attributeGroup": "memberOf",
#      "baseDN": "",
#      "searchFilter": "(objectClass=person)",
#      "connectionDN": "",
#      "password": "",
#      "host": "ldap",
#      "port": "389",
#      "loginID": "",
#      "loginPassword": "",
#      "encryption": "",
#      "groupBaseDN": "",
#      "groupSearchFilter": "",
#      "groupAttributeName": "",
#      "groupAttributeDescription": "",
#      "groupAttributeMember": "",
#      "completed": true
#    }
#  }
```

> Für weitere Konfigurationen wie z.B. Versionen der Operatoren siehe [values.yaml](https://github.com/cloudogu/k8s-ces-setup/blob/develop/k8s/helm/values.yaml).

### Installation

- `helm registry login registry.cloudogu.com --username yourusername --password yourpassword`
- `helm upgrade -i -f values.yaml k8s-ces-setup oci://registry.cloudogu.com/k8s/k8s-ces-setup `

Das Setup startet automatisch, wenn in jeder Sektion der `setup.json` `completed: true` ist.
Ansonsten kann das Setup manuell gestartet werden:

- `kubectl port-forward service/k8s-ces-setup 30080:8080`
- `curl -I --request POST --url http://localhost:30080/api/v1/setup`

> Information: Falls der Setup Prozess abbricht, weil ein invalider Wert in der `setup.json` angegeben wurde, muss nach Korrektur der `setup.json` die Configmap `k8s-setup-config` gelöscht werden.
> Danach kann das Setup wieder gestartet werden.

Das Cloudogu EcoSystem kann mit folgenden Befehlen **komplett** aus dem Cluster gelöscht werden (die angelegten Registry-Credentials bleiben hiervon unberührt):

- Dogus löschen
```bash
kubectl delete dogus -l app=ces -n ecosystem
```

- Components löschen
```bash
kubectl delete components -l app=ces -n ecosystem
```

- Restliche Ressourcen löschen
```bash
kubectl patch cm tcp-services -p '{"metadata":{"finalizers":null}}' --type=merge -n ecosystem || true \
&& kubectl patch cm udp-services -p '{"metadata":{"finalizers":null}}' --type=merge -n ecosystem || true \
&& kubectl delete statefulsets,deploy,secrets,cm,svc,sa,rolebindings,roles,clusterrolebindings,clusterroles,cronjob,pvc,pv --ignore-not-found -l app=ces -n ecosystem
```

### Upgrades

Das obige Beispiel installiert ein minimales Cloudogu EcoSystem.
Für das Hinzufügen von weiteren Dogus und Komponenten wird der Blueprint-Mechanismus verwendet.
Blueprints beschreiben das komplette Cloudogu EcoSystem (Dogus, Komponente und Konfigurationen) und werden von dem Blueprint-Operator verarbeitet.
Dieser ist in dem minimalen Beispiel enthalten.

Die [Dokumentation](https://github.com/cloudogu/k8s-blueprint-operator/blob/develop/docs/operations/blueprintV2_format_de.md) beschreibt die Konfiguration und Anwendung von Blueprints.

## 4. Hinweise für verschiedene Infrastrukturen und Cloud-Provider

### Verwendung von gespiegelten Registrys

Werden gespiegelte Registrys verwendet, ist es durchaus möglich, dass sich alle Docker-Images in einem
Unterprojekt in der Registry befinden (hier z. B. `organization`).

Beispielstruktur:
```
example.com/
├── organization <-
│   ├── k8s
│   │   ╰── k8s-dogu-operator
│   │       ╰── 0.1.0
│   ├── official
│   │   ╰── cas
│   │       ╰── 0.1.0
│   ├── premium
│   ╰── other namespace
```

In diesem Fall muss ein Rewrite für die Container-Konfiguration von `k3s` erstellt werden, damit Images
wie `example.com/longhorn/manager` von `example.com/organization/longhorn/manager` bezogen werden können.

Beispiel `k3sConfig.json`:

```json
{
   "docker-registry-configuration":{
      "mirrors":{
         "docker.io":{
            "endpoint":[
               "https://example.com"
            ],
            "rewrite":{
               "^(.*)$": "organization/$1"
            }
         }
      }
   }
}
```

### Gespiegelte Registrys verwenden selbstsignierte Zertifikate mit K3s

Selbstsignierte Zertifikate müssen `k3s` auf den jeweiligen Nodes und den Operatoren bekannt gemacht werden.

#### Selbstsignierte Zertifikate in k3s ablegen

Beispiel `k3sConfig.json`:

```json
{
  "ces-namespace":"ecosystem",
  "k3s-token":"SuPeR_secure123!TOKEN-Changeme",
  "nodes":[
    ...
  ],
  "docker-registry-configuration":{
    "mirrors":{
      "docker.io":{
        "endpoint":[
          "https://<registry-url>"
        ]
      }
    },
    "configs":{
      "<registry-url>":{
        "auth":{
          ...
        },
        "tls": {
          "ca_file": "/etc/ssl/certs/your.pem"
        }
      }
    }
  }
}
```

Nach einer Neuanlage der Zertifikate müssen die Dienste `k3s` (auf dem Main-Nodes) bzw. `k3s-agent` neugestartet werden:

```bash
# ssh in die jeweilige Maschine
sudo systemctl restart k3s
sudo systemctl restart k3s-agent
```

#### Selbstsignierte Zertifikate im Cluster-state ablegen

```bash
kubectl --namespace ecosystem create secret generic docker-registry-cert --from-file=docker-registry-cert.pem=<cert_name>.pem
kubectl --namespace ecosystem create secret generic dogu-registry-cert --from-file=dogu-registry-cert.pem=<cert_name>.pem
```

- Weitere Informationen sind [hier](https://github.com/cloudogu/k8s-dogu-operator/blob/develop/docs/operations/using_self_signed_certs_de.md) zu finden.


### Hinweise für verschiedene Cloud-Provider

Da sich die Umgebungen der Cloud-Provider unterscheiden können, ist es möglich, dass zusätzliche Konfigurationen
für den Betrieb des CES notwendig sind. In den folgenden Links sind Hinweise für den Betrieb bei Google, Microsoft und Plusserver zu finden:

- [Google](cloud-provider_installation_google_cloud_de.md)
- [Microsoft](cloud-provider_installation_azure_aks_de.md)
- [Plusserver](cloud-provider_installation_plusserver_de.md)

### Hinweise zur Speicherplatz-Nutzung

Um ein stabiles System zu gewährleisten und Speicherplatz optimal zu nutzen, ist es zu empfehlen folgende Aspekte zu beachten:

#### Verwendung von Data-Disks

##### Longhorn

In der Default-Konfiguration wird Longhorn den verwendeten Speicher auf den Disks der Kubernetes-Nodes nutzen.
Die Nutzdaten der PVCs sollten auf separaten Disks gespeichert werden.
Diese müssen unter `/var/lib/longhorn` eingehangen werden.

Longhorn belegt außerdem aus Sicherheitsgründen nicht den gesamten verfügbaren Speicherplatz.
Bei der Verwendung einer separaten Disk kann dieses Verhalten konfiguriert werden, um den Platz optimal zu nutzen.

Beispiel-Konfiguration in einem Blueprint:
```json
{
  "name": "k8s/k8s-longhorn",
  "version": "1.5.1-4",
  "targetState": "present",
  "deployConfig": {
    "overwriteConfig": {
      "longhorn": {
        "defaultSettings": {
          "StorageMinimalAvailablePercentage": 10
        }
      }
    }
  }
}
```

##### Storage-Provisioner von externen Cloud-Anbietern

Bei externen Cloud-Providern wird für jedes PersistentVolume automatisch eine Disk erstellt (siehe z.B. [Google](https://cloud.google.com/kubernetes-engine/docs/concepts/persistent-volumes) oder [Azure](https://learn.microsoft.com/de-de/azure/aks/azure-csi-disk-storage-provision)).

#### Garbage-Collection von Container-Images

Die `k3sConfig.json` bietet die Möglichkeit die Garbage-Collection von nicht mehr benötigten Images zu konfigurieren.
Dieser Prozess wird normalerweise **immer** ab einer Speicherauslastung von 85 % getriggert.
Dabei wird versucht so viele alte Images zu löschen, bis eine Auslastung von 80 % erreicht ist.

Beispiel `k3sConfig.json`: 
```json
{
  "ces-namespace": "ecosystem",
  "k3s-token": "SuPeR_secure123!TOKEN",
  "image-gc-low-threshold": 20,
  "image-gc-high-threshold": 50,
  "nodes": [
    {
      "name": "ces-main",
      "isMainNode": true,
      "node-ip": "192.168.56.2",
      "node-external-ip": "192.168.56.2",
      "flannel-iface": "enp0s8"
    },
    {
      "name": "ces-worker-0",
      "node-ip": "192.168.56.3",
      "node-external-ip": "192.168.56.3",
      "flannel-iface": "enp0s8"
    },
    {
      "name": "ces-worker-1",
      "node-ip": "192.168.56.4",
      "node-external-ip": "192.168.56.4",
      "flannel-iface": "enp0s8"
    },
    {
      "name": "ces-worker-2",
      "node-ip": "192.168.56.5",
      "node-external-ip": "192.168.56.5",
      "flannel-iface": "enp0s8"
    }
  ],
  "docker-registry-configuration": {
    "mirrors": {
      "k3ces.local:30099": {
        "endpoint": [
          "http://k3ces.local:30099"
        ]
      }
    },
    "configs": {
      "k3ces.local:30099": {
        "tls": {
          "insecure_skip_verify": false
        }
      }
    }
  }
}
```

Mit dieser Konfiguration wird die Garbage-Collection immer ab 50 % gestartet.
Möglicherweise werden alte Images bis zu einer Auslastung von 20 % gelöscht.
