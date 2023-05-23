# CES-Multinode auf Plusserver (PSKE)

## Hinweise
- `kubeconfig` kann hier: https://dashboard.prod.gardener.get-cloud.io/namespace/<your-garden>/shoots/ heruntergeladen werden.
- Beispiel Verwendung der config: `export KUBECONFIG=${KUBECONFIG}:~/.kube/kubeconfig-<your-garden-context>.yaml`

## Storage-Provisioner

- Daten werden ohne extra Storage-Provisioner repliziert.
- Hibernate funktioniert **ohne** Longhorn. Daten bleiben mit neuen Nodes erhalten. 
- **Achtung**: Mit Longhorn gehen alle Daten verloren, wenn man den Cluster auf 0 Nodes skaliert.

### Longhorn

- Man muss beachten, dass nur eine Storage-class default ist.
- 2 CPU könnten schon zu wenig für Longhorn sein, wenn zum Beispiel der Google-Metrics-Server auf einem Node läuft

## Load-Balancer

- Löscht man den `ecosystem`-Namespace und führt erneut ein Setup aus, kann es durchaus vorkommen, dass die LoadBalancer neue
IPs zuweisen. In diesem Fall ist die erneute Ausführung des Skripts: `syncFQDN.sh` notwendig.

## Scheduling

- Das `kubelet` oder `gardenlet` hat für das Schudling zwei Strategien: `balanced` (dafault) und `bin-packing`.
- Weil Dogus noch keine Ressourcen Request und Limits haben, scheint `balanced` nicht zu 100 % eine ausgewogene Verteilung durchzuführen.
- Während des Setups kann es vorkommen, dass deswegen Pod evicted werden und diese auf anderen Nodes neu starten.
- Evicted Pods können gelöscht werden.

## Sonar

- `vm.max_map_count`-Problem tritt **nicht** auf