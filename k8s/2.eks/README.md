export AWS_PROFILE=personal

aws eks update-kubeconfig --name eks-cluster --region ap-southeast-1 --profile personal
k apply -f kubernetes/cluster-role.yaml

Check permissions

- k get no
- k get po

Create accessKey, secretKey for user developer manually via console
Then create a profile for developer in ~/.aws/credentials
Check permissions for developer

- aws eks update-kubeconfig --name eks-cluster --region ap-southeast-1 --profile developer
- k get po
- k delete po
