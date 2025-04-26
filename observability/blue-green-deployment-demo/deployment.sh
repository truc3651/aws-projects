#!/bin/bash

deploy_blue() {
    echo "Deploying Blue version..."  
    helm upgrade \
    --install app app \
    --values ./app/values.yaml \
    --set image=nginx:1.19 \
    --set color=blue

    echo "Waiting for Blue deployment to be ready"
    kubectl rollout status deployment/app-deployment-blue
}

deploy_green() {
    echo "Deploying Green version..."
    helm upgrade \
    --install app app \
    --values ./app/values.yaml \
    --set image=nginx:1.20 \
    --set color=green
}

switch_traffic_blue_to_green() {
    echo "Switching traffic from Blue to Green..."

    kubectl patch service app-service -p '{"spec":{"selector":{"color":"green"}}}'
    kubectl scale deploy app-deployment-blue --replicas=0

    echo "Waiting for Green deployment to be ready"
    kubectl rollout status deployment/app-deployment-green

    echo "Traffic switched to Green deployment"
}

deploy_new_blue() {
    echo "Deploying Blue version..."
    
    helm upgrade \
    --install app app \
    --values ./app/values.yaml \
    --set image=nginx:1.21 \
    --set color=blue
}

switch_traffic_green_to_blue() {
    echo "Switching traffic from Green to Blue..."

    kubectl patch service app-service -p '{"spec":{"selector":{"color":"blue"}}}'
    kubectl scale deploy app-deployment-green --replicas=0

    echo "Waiting for Blue deployment to be ready"
    kubectl rollout status deployment/app-deployment-blue

    echo "Traffic switched to Blue deployment"
}

rollback() {
    echo "Rolling back to Green deployment..."

    kubectl scale deployment app-deployment-green --replicas=1
    kubectl patch service app-service -p '{"spec":{"selector":{"color":"green"}}}'
    kubectl scale deploy app-deployment-blue --replicas=0

    echo "Waiting for Green deployment to be ready"
    kubectl rollout status deployment/app-deployment-green

    echo "Rollback complete"
}

show_status() {
    echo -e "\nDeployments:"
    kubectl get deployments

    echo -e "\nPods:"
    kubectl get pods

    echo -e "\nServices:"
    kubectl get services
}

case "$1" in
    "init")
        deploy_blue
        show_status
        ;;
    "deploy-green")
        deploy_green
        switch_traffic_blue_to_green
        show_status
        ;;
    "deploy-new-blue")
        deploy_new_blue
        switch_traffic_green_to_blue
        show_status
        ;;
    "rollback")
        rollback
        show_status
        ;;
    "status")
        show_status
        ;;
    *)
        echo "Usage: $0 {init|deploy-green|rollback|status}"
        exit 1
        ;;
esac