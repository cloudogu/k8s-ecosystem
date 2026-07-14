# Testen einer Split-DNS-Umgebung

Eine Split-DNS-Umgebung liegt vor, wenn Ihr k8s-CES für die Kommunikation mit Dogu seine interne Adresse verwendet, von außen jedoch über eine externe IP-Adresse oder Domain erreichbar ist.

Um dieses Szenario zu testen, wurde der Ordner „split_dns“ für die folgende Vorgehensweise vorbereitet:

- Fügen Sie den Eintrag „192.168.56.1 splittest.local“ in Ihre Datei /etc/hosts ein
- Installieren Sie k8s-CES mit einer angepassten setup.json (wobei „splittest.local“ der FQDN und die Domain ist)
- Stellen Sie sicher, dass die Dateien split_dns/certs/fullchain.pem und split_dns/certs/privkey.pem erstellt werden:
    - Beziehen Sie die Datei fullchain.pem aus dem Cluster
        - `kubectl get secret ecosystem-certificate -n ecosystem -o json | jq -r '.data."tls.crt"' | base64 --decode`
    - Beziehen Sie die Datei privkey.pem aus dem cluster:
        - `kubectl get secret ecosystem-certificate -n ecosystem -o json | jq -r '.data."tls.key"' | base64 --decode`
- Starten Sie den Nginx-Reverse-Proxy für diesen Test mit dem Befehl `docker-compose up` im Ordner „split_dns“.
- Nun sollten Sie in der Lage sein, den k8s-CES über den FQDN „splittest.local“ zu nutzen.
    - Es kann zu 500-Fehler-Seiten kommen, wenn Sie die Verbindung zu früh herstellen.
    - Bei der Kommunikation zwischen den Dogu-Instanzen sollte keine Protokollausgabe für den Nginx-Reverse-Proxy vorliegen.