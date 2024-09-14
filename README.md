1) terraform plan -out plan.out -var-file="environment/dev.tfvars"
2) terraform apply -auto-approve "plan.out"
3) terraform destroy -auto-approve -var-file="environment/dev.tfvars"

All of this projects use root user credentials, consider IAM role.