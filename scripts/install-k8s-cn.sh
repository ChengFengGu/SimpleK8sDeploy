#!/bin/bash
# ============================================
# K8s Installation Script - Using China Mirrors
# Optimized for mainland China network environment
# ============================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_step "K8s Environment Installation (Using China Mirrors)"

# ============================================
# Step 0: Check Docker
# ============================================
print_step "Step 0: Check Environment"

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first"
    exit 1
fi

print_info "✅ Docker installed: $(docker --version)"

# ============================================
# Step 1: Check Minikube
# ============================================
print_step "Step 1: Check Minikube"

if command -v minikube &> /dev/null; then
    print_info "✅ Minikube installed: $(minikube version --short)"
else
    print_error "Minikube is not installed. Please install Minikube first"
    print_info "Installation command:"
    print_info "  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
    print_info "  sudo install minikube-linux-amd64 /usr/local/bin/minikube"
    exit 1
fi

if command -v kubectl &> /dev/null; then
    print_info "✅ kubectl installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
    print_warn "kubectl not installed, will be configured by minikube automatically"
fi

# ============================================
# Step 2: Clean up old environment
# ============================================
print_step "Step 2: Clean up old environment"

print_info "Stopping and deleting old Minikube cluster..."
minikube delete --all || true
rm -rf ~/.minikube ~/.kube
print_info "✅ Cleanup completed"

# ============================================
# Step 3: Start Minikube (Using China Mirrors)
# ============================================
print_step "Step 3: Start Minikube Cluster"

print_info "Starting Minikube with Aliyun mirror..."
print_info "Minikube version: $(minikube version --short)"

# ============================================
# Step 3.1: Pre-pull kicbase image (from Aliyun)
# ============================================
print_info "Pulling kicbase image from Aliyun..."
KICBASE_VERSION="v0.0.48"

# Pull image from Aliyun
if docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kicbase:${KICBASE_VERSION}; then
    print_info "✅ Base image downloaded"
    
    # Retag image for minikube to use local image
    print_info "Retagging image..."
    docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kicbase:${KICBASE_VERSION} \
        gcr.io/k8s-minikube/kicbase:${KICBASE_VERSION}
    docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kicbase:${KICBASE_VERSION} \
        kicbase/stable:${KICBASE_VERSION}
    print_info "✅ Image tagging completed"
else
    print_warn "Failed to pull from Aliyun, will try official source (may be slow)"
fi

# ============================================
# Step 3.2: Start Minikube Cluster
# ============================================
print_info "Starting Minikube cluster..."
print_info "This may take 5-10 minutes, please be patient..."

# Hybrid mirror strategy:
# 1. Container images: Use Aliyun registry (fast)
# 2. Binaries: Download from Google official via proxy
# 
# Issue: --image-repository affects both container images and binaries
# Solution: Download everything from Google official via proxy
print_info "Configuring download strategy: Download from Google official via proxy..."

# Export environment variables for minikube to use proxy
export HTTP_PROXY=http://172.19.160.1:8093
export HTTPS_PROXY=http://172.19.160.1:8093  
export NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,registry.cn-hangzhou.aliyuncs.com

# Don't use --image-repository, let everything download from official source via proxy
# This ensures getting the latest version and avoids Aliyun mirror sync delays
minikube start \
    --driver=docker \
    --cpus=2 \
    --memory=4096 \
    --disk-size=20g \
    --force \
    --base-image=gcr.io/k8s-minikube/kicbase:${KICBASE_VERSION}

# Clean up proxy environment variables
unset HTTP_PROXY HTTPS_PROXY NO_PROXY

print_info "✅ Minikube started successfully"

# ============================================
# Step 4: Configure kubectl
# ============================================
print_step "Step 4: Configure kubectl"

kubectl config use-context minikube
print_info "✅ kubectl configured"

# Verify cluster
print_info "Verifying cluster status..."
kubectl cluster-info
kubectl get nodes

# ============================================
# Step 5: Install Nginx Ingress Controller
# ============================================
print_step "Step 5: Install Nginx Ingress Controller"

print_info "Enabling Ingress addon..."
minikube addons enable ingress

print_info "Waiting for Ingress Controller to be ready (max 120 seconds)..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

print_info "✅ Ingress Controller installed"

# ============================================
# Step 6: Install Metrics Server
# ============================================
print_step "Step 6: Install Metrics Server"

print_info "Enabling Metrics Server addon..."
minikube addons enable metrics-server

print_info "✅ Metrics Server installed"

# ============================================
# Step 7: Configure Docker Environment (Optional)
# ============================================
print_step "Step 7: Configure Docker Environment"

print_info "Configure Docker to use Minikube's Docker daemon..."
print_info "Run the following command to use Minikube's Docker:"
print_info "  eval \$(minikube docker-env)"

# ============================================
# Verify Installation
# ============================================
print_step "Verify Installation"

print_info "Cluster information:"
kubectl cluster-info

print_info "\nNode status:"
kubectl get nodes -o wide

print_info "\nIngress Controller:"
kubectl get pods -n ingress-nginx

print_info "\nMinikube addons:"
minikube addons list | grep enabled

print_info "\nMinikube IP:"
MINIKUBE_IP=$(minikube ip)
echo $MINIKUBE_IP

# ============================================
# Completion
# ============================================
print_step "Installation Complete!"

print_info "\n✅ K8s cluster is ready!"
print_info "\nCommon commands:"
echo "  minikube status        # Check cluster status"
echo "  minikube dashboard     # Open dashboard"
echo "  minikube stop          # Stop cluster"
echo "  minikube start         # Start cluster"
echo "  minikube delete        # Delete cluster"
echo "  kubectl get nodes      # List nodes"
echo "  eval \$(minikube docker-env)  # Use Minikube's Docker"

print_info "\nNext steps:"
print_info "  1. Configure Docker environment: eval \$(minikube docker-env)"
print_info "  2. Build Docker images"
print_info "  3. Run deployment script: ./scripts/deploy.sh"

print_info "\n🎉 Ready to deploy applications!"
