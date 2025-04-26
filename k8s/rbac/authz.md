Kubernetes RBAC works in relation to identity, roles, and role bindings

- Identity: represents the entity requesting access
  - User
  - Service account: identity for processes running inside pod
  - Group: a collection of users or service accounts
- Roles: a set of permissions within a specific namespace
  - Role contains:
    - Resources: pods, services, configmaps
    - Verbs: get, list, create, update, delete
    - API group: which api group contains the resources
- Role binding: connects identities to roles

Assign role to Bob:

- k apply -f role.yaml
- k apply -f rolebinding.yaml

Service account for application:

- k apply -f serviceaccount.yaml
- k apply -f pod.yaml

Test application not have permission:

- k exec -it nginx sh
- API_SERVER=https://kubernetes.default.svc
- SERVICE_ACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
- NAMESPACE=$(cat ${SERVICE_ACCOUNT}/namespace)
- CA_CRT=${SERVICE_ACCOUNT}/ca.crt
- TOKEN=$(cat ${SERVICE_ACCOUNT}/token)
- curl -v --cacert ${CA_CRT} --header "Authorization: Bearer ${TOKEN}" -X GET ${API_SERVER}/api/v1/namespaces/${NAMESPACE}/pods
- You will see 403 Forbidden

Assign role to service account:

- k apply -f rolebinding-serviceaccount.yaml
- Re-test application call to api server
