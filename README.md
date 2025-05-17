# 🚀 Kubernetes Deployment Automation with KEDA (Bash CLI Tool)

This repository provides a modular Bash CLI script to automate operations on a bare Kubernetes cluster. It supports connecting to a cluster, installing Helm, Metrics Server, and KEDA, deploying event-driven workloads, and checking deployment health.

## 📂 Project Structure

```
.
├── k8s_deploy_tool.sh           # Main Bash script
├── config/
│   └── app_config.env           # Environment variables for deployment
└── deployments/
    ├── deployment.yaml          # Deployment template
    ├── service.yaml             # Service template
    └── scaledobject.yaml        # KEDA ScaledObject template
```

---

## 📋 Features

- ✅ Install required CLI tools: `kubectl`, `helm`, `jq`, and `metrics-server`
- 🔌 Connect to any kubeconfig-authenticated Kubernetes cluster
- 📦 Install [KEDA](https://keda.sh) for event-driven autoscaling using Helm
- 🚀 Deploy Kubernetes workloads with CPU/memory/event-driven autoscaling
- 📊 Retrieve deployment and pod health status including CPU/Memory metrics

---

# ⚙️ Prerequisites

- Linux environment (Debian-based assumed)
- Kubernetes cluster access (via kubeconfig)
- Internet connection for downloading tools and Helm charts

---

## 🛠 Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/k8s-keda-cli-tool.git
cd k8s-keda-cli-tool
chmod +x k8s_deploy_tool.sh
```

### 2. Configure Your Deployment

Edit the file `config/app_config.env` to specify your app configuration:

```env
APP_NAME=myapp
IMAGE=nginx:latest
NAMESPACE=default
PORT=80
CPU_REQUEST=100m
MEMORY_REQUEST=128Mi
CPU_LIMIT=500m
MEMORY_LIMIT=256Mi
```

---

## 🚦 Usage

### 🔍 1. Check and Connect to Cluster

```bash
./k8s_deploy_tool.sh connect
```

Verifies cluster connection, lists nodes, installs required tools.

---

### 📦 2. Install KEDA on the Cluster

```bash
./k8s_deploy_tool.sh install-keda
```

Installs KEDA operator in the `keda` namespace using Helm.

---

### 🚀 3. Deploy Your Application

```bash
./k8s_deploy_tool.sh deploy
```

Creates:
- Deployment
- Service
- KEDA ScaledObject (based on CPU by default)

---

### 📊 4. Check Health of a Deployment

```bash
./k8s_deploy_tool.sh health myapp default
```

Displays:
- Deployment and pod status
- CPU/Memory usage (if metrics server is enabled)

---

## 📦 Metrics Server Installation

This script automatically installs [Metrics Server](https://github.com/kubernetes-sigs/metrics-server), which is required for monitoring CPU and memory usage via `kubectl top`.

For local clusters like `minikube` or `kind`, the script also adds the `--kubelet-insecure-tls` flag to allow insecure TLS connections to kubelets.
