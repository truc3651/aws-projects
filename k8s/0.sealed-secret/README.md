How sealed secret works?
Kubernetes secrets only base64 encoded, this means you can't safely store them in Git repo.
Sealed secrets architecture:

- Sealed secret controller: a kubernetes controller running in your cluster
- kubeseal cli: command line tool to encrypt secrets

The system works thru public/private key pair:

- The controller generates and stores a private key within the cluster
- kubeseal cli communicates with the controller to obtain the corresponding public key
- your secrets are encrypted using this public key, creating sealedsecret resources
- the controller detects this new resource, it uses its private key to decrypt the data
- It creates a regular Kubernetes secret with the decrypted data
- Your application can use secret normally
- So don't commit the secret file to repo

k apply -f namespace.yaml
k apply -f deployment.yaml

brew install kubeseal
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.23.1/controller.yaml -n kube-system

kubeseal --controller-namespace=kube-system --fetch-cert > cert.pem
kubeseal --controller-namespace=kube-system < secrets.yaml --cert=cert.pem -o yaml > sealed-secrets.yaml
k apply -f sealed-secrets.yaml

k exec -it sealed-secrets -- ls /etc/credentials
k exec -it sealed-secrets -- cat /etc/credentials/username
