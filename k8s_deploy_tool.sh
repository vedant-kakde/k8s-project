#!/bin/bash

set -euo pipefail

###########################
# CONFIGURATION
###########################

CONFIG_FILE="config/app_config.env"

###########################
# TOOL INSTALLATION
###########################

function install_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "[INFO] Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    else
        echo "[INFO] kubectl already installed."
    fi
}

function install_helm() {
    if ! command -v helm &> /dev/null; then
        echo "[INFO] Installing helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    else
        echo "[INFO] helm already installed."
    fi
}

function install_jq() {
    if ! command -v jq &> /dev/null; then
        echo "[INFO] Installing jq..."
        sudo apt-get update && sudo apt-get install -y jq
    else
        echo "[INFO] jq already installed."
    fi
}

function install_metrics_server() {
    if ! kubectl get deployment metrics-server -n kube-system &>/dev/null; then
        echo "[INFO] Installing metrics-server..."
        kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

        echo "[INFO] Patching metrics-server deployment to allow insecure TLS (for local clusters)..."
        kubectl patch deployment metrics-server -n kube-system \
          --type=json \
          -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

        echo "[INFO] Waiting for metrics-server to be ready..."
        kubectl rollout status deployment metrics-server -n kube-system
    else
        echo "[INFO] metrics-server is already installed."
    fi
}

function check_prerequisites() {
    echo "[INFO] Checking prerequisites..."
    install_kubectl
    install_helm
    install_jq
    install_metrics_server
    echo "[INFO] All required tools and components are installed."
}

###########################
# CLUSTER CONNECTION
###########################

function connect_cluster() {
    echo "[INFO] Verifying connection to Kubernetes cluster..."
    kubectl version --short
    kubectl get nodes
}

###########################
# KEDA INSTALLATION
###########################

function install_keda() {
    echo "[INFO] Installing KEDA using Helm..."
    helm repo add kedacore https://kedacore.github.io/charts
    helm repo update
    helm install keda kedacore/keda --namespace keda --create-namespace

    echo "[INFO] Waiting for KEDA operator to be ready..."
    kubectl rollout status deployment/keda-operator -n keda
}

###########################
# DEPLOYMENT CREATION
###########################

function create_resources() {
    echo "[INFO] Creating Kubernetes resources from templates..."

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "[ERROR] Config file not found at $CONFIG_FILE"
        exit 1
    fi

    source "$CONFIG_FILE"
    export $(cut -d= -f1 "$CONFIG_FILE")

    envsubst < deployments/deployment.yaml | kubectl apply -f -
    envsubst < deployments/service.yaml | kubectl apply -f -
    envsubst < deployments/scaledobject.yaml | kubectl apply -f -

    echo "[INFO] Resources created in namespace: $NAMESPACE"
    echo "[INFO] Deployment: $APP_NAME"
}

###########################
# HEALTH STATUS
###########################

function get_health_status() {
    local deploy_name=$1
    local namespace=$2

    echo "[INFO] Fetching health status for deployment '$deploy_name' in namespace '$namespace'..."

    kubectl get deployment "$deploy_name" -n "$namespace"
    kubectl get pods -l app="$deploy_name" -n "$namespace"
    kubectl describe deployment "$deploy_name" -n "$namespace"

    echo "[INFO] CPU and Memory usage:"
    kubectl top pods -n "$namespace" || echo "[WARN] Metrics server may not be running."
}

###########################
# USAGE
###########################

function usage() {
    echo "Usage: $0 {connect|install-keda|deploy|health <deployment-name> <namespace>}"
    exit 1
}

###########################
# MAIN
###########################

case "${1:-}" in
    connect)
        check_prerequisites
        connect_cluster
        ;;
    install-keda)
        check_prerequisites
        install_keda
        ;;
    deploy)
        check_prerequisites
        create_resources
        ;;
    health)
        check_prerequisites
        get_health_status "${2:-}" "${3:-}"
        ;;
    *)
        usage
        ;;
esac
