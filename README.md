1) aws configure list-profiles
2) export AWS_PROFILE=
3) terraform plan -out plan.out -var-file="environment/dev.tfvars"
4) terraform apply -auto-approve "plan.out"
5) terraform destroy -auto-approve -var-file="environment/dev.tfvars"

All of this projects use root user credentials, consider IAM role.