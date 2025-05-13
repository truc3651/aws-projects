## Cluster Autoscaler

In a typical simple setup:

- 1 cluster has 1 node group, which is backed by 1 AutoScaling Group
- All worker nodes have the same instance type
- Cluster Autoscaler simply scales this single ASG up or down

More complex clusters often use multiple ASGs:

- Different instance types for different workloads (compute-optimized vs memory-optimized)
- Running across multiple AZ for high availability
- Using spot instances alongside on-demand instances

Scale up process:

- Autoscaler detects unschedulable pods, it calls aws api to increase the 'desired capacity' of selected ASG
- New ec2 instances scheduled on new nodes

Scale down process:

- Autoscaler identifies underutilized nodes, it cordons the drains the node, moving pods to other nodes
- Once empty, it calls aws api to detach the node from the ASG and terminates it
- ASG decreases the 'desired capacity'

The Cluster Autoscaler has built-in safeguards to prevent it from terminating the node where it's running, because it's in kube-system namespace

In demo practice, you can see: 1 pod is located in node, but the other one is pending, because we use podAntiAffinity, it makes pods separate on different nodes. Kubernetes needs time to scale nodes

Paste IAM role ARN to service account: kubernetes/service-account.yaml

- aws eks update-kubeconfig --name eks-cluster --region ap-southeast-1 --profile personal
- k apply -f kubernetes/cluster-hpa/service-account.yaml
- k apply -f kubernetes/cluster-hpa/deployment.yaml
- k apply -f kubernetes/cluster-hpa/workload.yaml

## Pod autoscaler

helm repo add bitnami https://charts.bitnami.com/bitnami
helm install metrics bitnami/metrics-server --namespace kube-system --values kubernetes/pod-vpa/values.yaml

VPA modes:

- Off: provides recommendations, but doesn't apply any changes to your pods. These recommendations are stored in the VPA object's status field. When to use: during initial VPA deployment, you want to observe recommendations first, or you need careful change management
- Initial: only applies at pod creation time, but never modifies pods are running. When to use: for gradual resource adjustments during natural pod lifecycle events, for stateful apps where pod recreation might cause data loss
- Auto: automatically evicts pods to apply new resource recommneds, causing them to be recreated with updated resources. When to use: for stateless app that can handle pod restarts, want full automated resource optimize
- Recreate: causes all pods to be restarted at once when recommnendations change significantly. When to use: applications that need to scale together due to interdependencies

Install vpa server:

- git clone https://github.com/kubernetes/autoscaler.git
- ./vertical-pod-autoscaler/hack/vpa-up.sh
- k apply -f kubernetes/pod-vpa/vpa.yaml
- k apply -f kubernetes/pod-vpa/workload.yaml
- watch -n 1 -t kubectl top pods
