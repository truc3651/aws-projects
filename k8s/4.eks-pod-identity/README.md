terraform init
terraform apply -auto-approve

aws eks update-kubeconfig --name eks-cluster --region ap-southeast-1 --profile personal
k apply -f kubernetes/service-account.yaml
k annotate serviceaccount aws-reader eks.amazonaws.com/role-arn=<IAM-role-arn>
k apply -f kubernetes/deployment.yaml
k exec -it <pod-aws-cli> -- /bin/bash
aws s3 ls
aws ec2 describe-instances: session is not authorized to perform ec2:DescribeInstances

terraform destroy -auto-approve
