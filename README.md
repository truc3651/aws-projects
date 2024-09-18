1) export AWS_PROFILE=default
2) terraform plan -out plan.out -var-file="environment/dev.tfvars"
3) terraform apply -auto-approve "plan.out"
4) terraform destroy -auto-approve -var-file="environment/dev.tfvars"

All of this projects use root user credentials, consider IAM role.