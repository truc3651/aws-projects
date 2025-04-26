Install custom resource definitions (CRDs):

- kubectl create -f https://download.elastic.co/downloads/eck/2.16.1/crds.yaml
- kubectl apply -f https://download.elastic.co/downloads/eck/2.16.1/operator.yaml

Start elasticsearch:

- k apply -f elasticsearch.yml

Tell Kind to do port forwarding:

- k port-forward svc/quickstart-es-http 9200
- PASSWORD=$(kubectl get secret quickstart-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
- curl -u "elastic:$PASSWORD" -k "https://quickstart-es-http:9200"

Create filbeat creds to connect to elasticsearch:

- kubectl create secret generic filebeat-es-credentials \
  --from-literal=username=elastic \
  --from-literal=password=$PASSWORD \
  --namespace default

Start sending logs to elasticsearch:

- k apply -f log-generator.yml
- k apply -f filebeat.yml

Check filebeat receive logs:

- k exec -it quickstart-beat-filebeat-wr96v -- find /var/log/containers -name "_app_.log"
- k exec -it quickstart-beat-filebeat-wr96v -- cat /var/log/containers/kubernetes-app-\*.log

Retrieve logs with elasticsearch API:

- GET https://localhost:9200/.ds-filebeat-8.17.3-2025.04.05-000001/\_search with basic auth

FAQs:

- filebeat needs permission to read metadata of other resources (pod's namespace, label). Token is gerated and refresh automatically by k8s. kube-root-ca.crt is default config in every namspace, filebeat reference to it and get only ca.crt. downwardAPI is used to let pod know about itself (namespace, pod name, labels).
- volume varlogcontainers contains symlinks to actual logs.
- volume varlogpods is where actual logs are stored.
