# Labels für Cloudogu EcoSystem-Ressourcen

Diese Richtlinie soll einen Überblick darüber geben, wann man während der Entwicklung von Komponenten, die CES-Kubernetes-Ressourcen erstellen, _programmatisch Labels_ auf CES-Komponenten anwenden sollte und wann nicht. Außerdem hilft diese Richtlinie dabei, einen Überblick darüber zu geben, welche Labels verwendet werden sollten. Natürlich ist jeder ermutigt, benutzerdefinierte Labels nach seinem Geschmack zu setzen, da Kubernetes-Labels ein generischer Weg sind, um für Benutzer sichtbare Semantik hinzuzufügen.

---

Labels sind Kubernetes-eigene Schlüssel-Wert-Paare, die an Kubernetes-Objekte angehängt werden, z. B. Deployments, Pods und so weiter. Sie haben nur für die Benutzer eine Bedeutung. Labels helfen Benutzern, Ressourcen zu identifizieren und zu organisieren, insbesondere mithilfe von Selektoren.

Jeder Label-Schlüssel muss für ein bestimmtes Objekt eindeutig sein. Wird für denselben Schlüssel ein anderer Label-Wert festgelegt, wird der Wert überschrieben.

Weitere Informationen über Labels und Selektoren finden Sie in der offiziellen [Kubernetes-Dokumentation] (https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/).

## Label-Richtlinie für CES-Komponenten

Die Label-Policy besteht im Wesentlichen aus zwei Regeln:

1. zum Labeln einer bestimmten Anwendung sowie
2. für die Kennzeichnung aller beweglichen Teile, nachdem die Maschine provisioniert wurde.

Außerdem gibt es zwei weitere reservierte Labels, die automatisch von `k8s-dogu-operator` erzeugt werden:
- `dogu.name: <dogu-name>` und
- `dogu.version: <dogu-version`

Diese Bezeichnungen **DÜRFEN NICHT** manuell gesetzt werden, da diese Bezeichnungen für die dogu-Upgrade-Prozedur entscheidend sind.

### 1. Labels, die die Anwendung identifizieren

**ALLE** Ressourcen einer CES-Komponente **MÜSSEN** ein Label erhalten, das die Auswahl der zugrunde liegenden Anwendung ermöglicht. Damit können alle Ressourcen identifiziert werden, die durch den Einsatz dieser Anwendung in diesen Cluster gelangt sind.

Das Format des Labels ist: `app.kubernetes.io/name: <component-name>`

Ein Beispiel ist das vollständige Löschen einer Komponente, um sie durch eine andere Version zu ersetzen, die möglicherweise weniger oder andere Ressourcen mitbringt. Ohne eine ordnungsgemäße Kennzeichnung würde unbenutze Ressourcen hinterlassen, deren Nutzungsstatus unklar sein könnte.

Diese Syntax ist den Helm-Anwendungskennzeichnungen entnommen.

Beispiel:

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  labels:
    app.kubernetes.io/name: your-ces-k8s-component-name
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  labels:
    app.kubernetes.io/name: your-ces-k8s-component-name
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: your-ces-k8s-component-name
```

### 2. Labels, die als abnehmbarer Teil des Cloudogu EcoSystems identifizieren

**Einige** Ressourcen einer CES-Komponente **MÜSSEN** ein Label erhalten, das alle gruppiert und die Auswahl der zugrundeliegenden Anwendung ermöglicht. Dies ermöglicht es, alle Ressourcen zu identifizieren, die mit offiziellen Mitteln des Cloudogu EcoSystems in diesen Cluster gelangt sind.

Das Format des Labels ist: `app: ces`

Das Hauptbeispiel ist das Löschen eines existierenden Namespaces von allen CES-Komponenten, um ein neues Setup durchzuführen, **ohne** den gesamten Cluster zu löschen oder wichtige Laufzeitinformationen zu entfernen (wie `setup.json`, Instanz-Credentials oder den Longhorn Storage Manager).

Das Label `app.kubernetes.io/name` steht im krassen Gegensatz zum Label `app: ces`, da letzteres nicht alle Ressourcen in einem CES-Cluster oder sogar Namespace kennzeichnen soll. Die Motivation ist einfach: Das Label `app: ces` soll dem Administrator die Möglichkeit geben, die notwendigen Ressourcen zu _löschen_, um ein neues Setup zu starten.

Die folgende Tabelle soll Ihnen eine Idee geben, welche Ressourcen das Label `app: ces` erhalten sollen:

| Ressourcenbeispiel | `app: ces`? | Grund |
|--------------------------------------------|-------------|-------------------------------------------------------------------------------------------------------------|
| Instance credentials secrets | nein        | Es wird mühsam sein, die ursprünglichen Instance credentials zu finden |
| Longhorn-Ressourcen | nein        | Longhorn ist Teil der Infrastruktur, das Löschen wird eine Neueinrichtung stark behindern |
| Vom Kunden hinzugefügte Ressourcen | nein        | Das `ces`-Label sollte niemals Ressourcen auswählen, die nicht unsere eigenen sind.                                          |
| Original K3s cluster admin RBAC | nein        | Out-of-the-Box Ressourcen zählen als Ressourcen, die nicht unsere eigenen sind.                                            |
| "k8s-dogu-operator"-Ressourcen | ja          | Der Operator sollte ohne Probleme entfernt und neu installiert werden können |
| Resources generated by `k8s-dogu-operator` | ja          | Alle Ressourcen, die vom CES während des Setups und der regulären Laufzeit generiert werden, sollten das Label |
| Ihre neue CES-Komponente 1 | abhängig    | Wenn die Komponente Teil der Infrastruktur ist, die während der Clusterbereitstellung installiert werden soll: Nein |
| Ihre neue CES-Komponente 2 | hängt ab    | Wenn die Komponente einfach neu installiert werden kann oder als Teil des Setups installiert werden kann: Ja |

Beispiel:

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  labels:
    app: ces
    app.kubernetes.io/name: your-other-k8s-component-name
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  labels:
    app: ces
    app.kubernetes.io/name: your-other-k8s-component-name
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: ces
    app.kubernetes.io/name: your-other-k8s-component-name
```

## Wie können Labels bei der Verwaltung des K8s-Ecosystems helfen?

In diesem Kapitel werden einige Beispiele beschrieben, damit Sie von den durch CES-Komponenten gesetzten Labels profitieren können. Die zugrundeliegende Idee ist es, alle Kubernetes-API-Ressourcen aufzuzählen und sie an einen `kubectl <action>`-Befehl für das angegebene Label und den Namespace weiterzuleiten.

### Alle Ressourcen auswählen

Wählt alle Ressourcen aus dem `ecosystem` Namespace aus, die vom K8s Ökosystem generiert werden:

```bash
kubectl api-resources --verbs=list -o name | sort | xargs -t -n 1 \
  kubectl get --ignore-not-found \
    -l app=ces -n ecosystem
```

### Alle CES-Ressourcen löschen

Löschen Sie alle Ressourcen aus dem Namespace "ecosystem". 
- die vom K8s Ökosystem generiert werden und 
- die keine kritische Infrastruktur bereitstellen

Ein erneuter Setup-Lauf sollte nach diesen beiden Aufrufen noch möglich sein.

```bash
# zuerst alle Dogus löschen, da der dogu-Operator diese Ressourcen verwalten sollte
kubectl delete dogu --ignore-not-found -l app=ces -n ecosystem
# alle anderen Ressourcen löschen
kubectl api-resources --verbs=list -o name | sort | xargs -t -n 1 \
  kubectl get --ignore-not-found \
    -l app=ces -n ecosystem
```

### Ressourcen von einer oder mehreren Komponenten löschen

Die Installation einer Komponente geht oft mit verschiedenen Ressourcentypen einher, wie Deployments, Configmaps und mehr. Das Löschen einer Komponente mit allen zugehörigen Ressourcen sollte mit einem Aufruf wie diesem möglich sein.

Dieses Beispiel löscht alle Ressourcen der Komponente, die sich als `app.kubernetes.io/name=k8s-ces-setup` identifiziert, aus dem Namespace `ecosystem`:

``bash
kubectl api-resources --verbs=list -o name | sort | xargs -t -n 1 \
kubectl delete --ignore-not-found \
-l app.kubernetes.io/name=k8s-ces-setup -n ecosystem
```

Mehrere Komponenten können mit [set-based label requirements](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#set-based-requirement) ausgewählt werden (die wie ein logisches `OR` funktionieren):

```bash
kubectl api-resources --verbs=list -o name | sort | xargs -t -n 1 \
  kubectl delete --ignore-not-found \
    -l 'app.kubernetes.io/name in (k8s-ces-setup, k8s-dogu-operator)' -n ecosystem
```

## Labels versus Annotationen

Labels bieten eine Möglichkeit, Ressourcen eine semantische Identität zu verleihen. Mit CLI-Tools wie `kubectl` können Ressourcen mit Labels effizient abgefragt werden.

Annotationen hingegen liefern nicht-identifizierende Informationen. Das Zielpublikum sind eher Clients wie Werkzeuge oder Bibliotheken, die diese Informationen oft nutzen, um die Art und Weise ihrer Ausführung zu ändern.

Im Allgemeinen können Labels beliebig viel verwendet werden, während Annotationen sparsam eingesetzt werden sollten. Labels sind das Mittel der Wahl, wenn es darum geht, Ressourcen für Menschen sichtbar zu markieren.
