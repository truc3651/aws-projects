Certificates based authentication:

Kubernetes doesn't have a concept of users or groups. Identities in Kubernetes could be a user ID, user email, group ID. To identify user or group, Kubenertes uses cert, which was signed by the Kubernetes CA. When you create a cluster, you assign a CA cert. If you want to add Bob as admin, you create a cert with common name is Bob, then signed it with the CA cert.

The CA cert placed in the /etc/kubernetes/pki folder by default.

Generate cert for Bob:

- openssl genrsa -out bob.key 2048
- openssl req -new -key bob.key -out bob.csr -subj "/CN=Bob/O=Engineering" (CN stands for common name, represents the identity of the cert holder, O stands for organization, represents org or group that user belongs to.)

Make certificate signing request (CSR):

- cat bob.csr | base64 | tr -d '\n' | pbcopy
- kubectl apply -f bob-csr.yaml
- kubectl certificate approve bob-csr
- kubectl get csr bob-csr -o jsonpath='{.status.certificate}' | base64 -d > bob.crt

Add Bob to kubeconfig:

- k config set-credentials bob --client-certificate=bob.crt --client-key=bob.key --embed-certs=true
- k config get-contexts
- k config set-context kind-bob --cluster=kind-kind --namespace=default --user=bob
- k config use-context kind-bob
- k config view
