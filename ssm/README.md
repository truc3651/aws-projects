1. Install the AWS Session Manager Plugin

2. Build the infra

```bash
  terraform init
  terraform plan
  terraform apply -auto-approve
```

3. Run tunnel script:

```bash
  python3 -m venv venv
  source venv/bin/activate
  pip install boto3
  chmod +x tunnel.py
  AWS_PROFILE=personal python3 ./tunnel.py
```
