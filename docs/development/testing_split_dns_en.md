# Testing split DNS environment

The split DNS environment is when your k8s-CES uses its internal address for dogu communication, but is reachable from the outside via an external IP address or domain.

To test this scenario, the "split_dns" folder has been prepared for the following procedure:

- Add entry "192.168.56.1 splittest.local" to your /etc/hosts file
- Install k8s-CES with the provided setup.json ("splittest.local" beeing the fqdn)
- Make sure to create the files split_dns/certs/fullchain.pem and split_dns/certs/privkey.pem:
  - Get fullchain.pem from the cluster
    - kubectl get secret ecosystem-certificate -n ecosystem -o jsonpath='{.data}'|jq -r .[]|head -n1|base64 --decode
  - Get privkey.pem from the etcd in the cluster:
    - Switch to etcd-client-Pod shell
    - `etcdctl get /config/_global/certificate/server.key`
- Run the nginx reverse proxy for this test via `docker-compose up` inside the split_dns folder
- Now you should be able to use the k8s-CES via the "splittest.local" FQDN
    - There should be no log output for the nginx reverse proxy on inter-Dogu communication
