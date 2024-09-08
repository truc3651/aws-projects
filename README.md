terraform plan -out plan.out -var-file="environment/dev.tfvars"
terraform apply "plan.out"

Nếu bạn thấy ủa sao câu lệnh apply cũng chạy plan, thì ta chạy câu lệnh plan trước làm quái gì cho mệt vậy? Thì thật ra những câu lệnh trên được thiết kế cho quá trình CI/CD. Ta có thể chạy câu lệnh plan trước, với -out option, để review resource, sau đó ta sẽ chạy câu lệnh apply với kết quả của plan trước đó, như sau:


