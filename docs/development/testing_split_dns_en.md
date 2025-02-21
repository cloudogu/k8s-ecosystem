# Testing split DNS environment

The split DNS environment is when your k8s-CES uses its internal address for dogu communication, but is reachable from the outside via an external IP address or domain.

To test this scenario, the "split_dns" folder has been prepared for the following procedure:

- Add entry "192.168.56.1 splittest.local" to your /etc/hosts file
- Install k8s-CES with an adapted setup.json ("splittest.local" beeing the fqdn and domain)
- Make sure to create the files split_dns/certs/fullchain.pem and split_dns/certs/privkey.pem:
  - Get fullchain.pem from the cluster
    - `kubectl get secret ecosystem-certificate -n ecosystem -o json | jq -r '.data."tls.crt"' | base64 --decode`
  - Get privkey.pem from the cluster:
    - `kubectl get secret ecosystem-certificate -n ecosystem -o json | jq -r '.data."tls.key"' | base64 --decode`
- Run the nginx reverse proxy for this test via `docker-compose up` inside the split_dns folder
- Now you should be able to use the k8s-CES via the "splittest.local" FQDN
    - There may be some 500 error pages if you connect too early
    - There should be no log output for the nginx reverse proxy on inter-Dogu communication
