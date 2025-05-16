## In order to Kubernetes talk to webhook, we need to have a certificate.

Generate CA certificate:

```
openssl genrsa -out tls/ca.key 2048
openssl req -x509 -new -nodes -key tls/ca.key -sha256 -days 7300 -out tls/ca.crt -subj "/C=AU/ST=Example/L=Melbourne/O=Example/OU=CA" -addext "subjectAltName=DNS:cluster.local"
```

Generate webhook certificate:

```
openssl genrsa -out tls/webhook.key 2048

openssl req -new -key tls/webhook.key -out tls/webhook.csr -subj "/C=AU/ST=Example/L=Melbourne/O=Example/OU=Webhook" -addext "subjectAltName=DNS:webhook,DNS:webhook.webhook.svc.cluster.local,DNS:webhook.webhook.svc,DNS:localhost,IP:127.0.0.1"

openssl x509 -req -in tls/webhook.csr -CA tls/ca.crt -CAkey tls/ca.key -CAcreateserial -out tls/webhook.crt -days 7300 -sha256 -extfile <(printf "\nsubjectAltName=DNS:webhook,DNS:webhook.webhook.svc.cluster.local,DNS:webhook.webhook.svc,DNS:localhost,IP:127.0.0.1\nbasicConstraints=critical,CA:FALSE\nkeyUsage=critical,digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth,clientAuth")
```

### Paste webhook crt into secret:

```
cat tls/webhook.crt | base64 | tr -d '\n' | pbcopy
cat tls/webhook.key | base64 | tr -d '\n' | pbcopy
```

### Paste ca crt into webhook template:

```
cat tls/ca.crt | base64 | tr -d '\n' | pbcopy

k apply -f webhook-template.yaml
```

## Build webhook server:

```
docker build -t webhook .
```

## Load image into kind cluster

```
kind load docker-image webhook
```

## Test out webhook server:

```
k apply -f curl.yaml
curl -H "Content-Type: application/json" http://webhook/pods

```

```
k apply -f demo-pod.yaml

k get po --show-labels=true -n default -w
```
