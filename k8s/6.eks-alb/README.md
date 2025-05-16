## Build eks

terraform init
terraform apply -auto-approve
aws eks update-kubeconfig --name eks-cluster --region ap-southeast-1 --profile personal

## The complete flow

Client → ELB → Target Group → EKS Worker Node - EC2 instances (echoserver NodePort 30329) → Kubernetes Routing → Pod → Container

- The client establishes a connection with the ELB on the configured listener port (typically 80 for HTTP or 443 for HTTPS)
- The ELB checks the request against its listener rules to determine which target group should receive the traffic
- The target group forwards the request to the selected worker node
- from the NodePort to the appropriate cluster IP and port for the targeted Kubernetes Service
- Service to pod through endpoints

## Delete everything

helm uninstall aws-load-balancer-controller
terraform destroy -auto-approve
