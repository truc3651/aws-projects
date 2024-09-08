1) terraform plan -out plan.out -var-file="environment/dev.tfvars"  -auto-approve
2) terraform apply "plan.out"
3) terraform destroy -auto-approve
