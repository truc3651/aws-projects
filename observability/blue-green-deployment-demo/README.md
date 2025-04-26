Install kind and helm
- brew install helm kind

Create new Kubernetes cluster
- kind create cluster --name helm

Execute permission
- chmod +x ./deployment.sh

First time deploy app (blue version)
- ./deployment.sh init

Deploy new version of app (green version)
- ./deployment.sh deploy-green

Deploy new version of app (the new blue version)
- ./deployment.sh deploy-new-blue

Rollback to previous version
- ./deployment.sh rollback

View resources
- ./deployment.sh status