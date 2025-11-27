#!/bin/bash
# ============================================
# Kubernetes Deployment Script
# Auto deploy login system to K8s cluster
# ============================================

set -e  # Exit on error

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first"
    exit 1
fi

# Project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
K8S_DIR="$PROJECT_ROOT/k8s"

print_info "Starting deployment of login system to Kubernetes..."
print_info "Project root: $PROJECT_ROOT"

# ============================================
# Step 1: Create Namespace
# ============================================
print_info "Step 1: Creating namespace..."
kubectl apply -f "$K8S_DIR/namespace.yaml"

# Wait for namespace creation
sleep 2

# ============================================
# Step 2: Deploy PostgreSQL
# ============================================
print_info "Step 2: Deploying PostgreSQL database..."

print_info "  2.1 Creating Secret..."
kubectl apply -f "$K8S_DIR/postgres/postgres-secret.yaml"

print_info "  2.2 Creating ConfigMap..."
kubectl apply -f "$K8S_DIR/postgres/postgres-configmap.yaml"

print_info "  2.3 Creating PersistentVolume..."
kubectl apply -f "$K8S_DIR/postgres/postgres-pv.yaml"

print_info "  2.4 Creating PersistentVolumeClaim..."
kubectl apply -f "$K8S_DIR/postgres/postgres-pvc.yaml"

print_info "  2.5 Creating Deployment..."
kubectl apply -f "$K8S_DIR/postgres/postgres-deployment.yaml"

print_info "  2.6 Creating Service..."
kubectl apply -f "$K8S_DIR/postgres/postgres-service.yaml"

# Wait for PostgreSQL to be ready
print_info "  Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n login-system --timeout=120s || true

# ============================================
# Step 3: Deploy Backend
# ============================================
print_info "Step 3: Deploying Django backend..."

print_info "  3.1 Creating Secret..."
kubectl apply -f "$K8S_DIR/backend/backend-secret.yaml"

print_info "  3.2 Creating ConfigMap..."
kubectl apply -f "$K8S_DIR/backend/backend-configmap.yaml"

print_info "  3.3 Creating Deployment..."
kubectl apply -f "$K8S_DIR/backend/backend-deployment.yaml"

print_info "  3.4 Creating Service..."
kubectl apply -f "$K8S_DIR/backend/backend-service.yaml"

# Wait for Backend to be ready
print_info "  Waiting for Backend to be ready..."
kubectl wait --for=condition=ready pod -l app=backend -n login-system --timeout=120s || true

# ============================================
# Step 4: Deploy Frontend
# ============================================
print_info "Step 4: Deploying Vue3 frontend..."

print_info "  4.1 Creating ConfigMap..."
kubectl apply -f "$K8S_DIR/frontend/frontend-configmap.yaml"

print_info "  4.2 Creating Deployment..."
kubectl apply -f "$K8S_DIR/frontend/frontend-deployment.yaml"

print_info "  4.3 Creating Service..."
kubectl apply -f "$K8S_DIR/frontend/frontend-service.yaml"

# Wait for Frontend to be ready
print_info "  Waiting for Frontend to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend -n login-system --timeout=120s || true

# ============================================
# Step 5: Deploy Ingress (Optional)
# ============================================
read -p "Deploy Ingress? (Ingress Controller required) [y/N]: " deploy_ingress
if [[ "$deploy_ingress" =~ ^[Yy]$ ]]; then
    print_info "Step 5: Deploying Ingress..."
    kubectl apply -f "$K8S_DIR/ingress.yaml"
else
    print_warn "Skipping Ingress deployment"
fi

# ============================================
# Deployment Complete
# ============================================
print_info "============================================"
print_info "Deployment Complete!"
print_info "============================================"

# Show deployment status
print_info "\nView deployment status:"
kubectl get all -n login-system

# Get access information
print_info "\nAccess information:"
NODE_PORT=$(kubectl get service frontend-service -n login-system -o jsonpath='{.spec.ports[0].nodePort}')
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

print_info "  Frontend (NodePort): http://$NODE_IP:$NODE_PORT"
print_info "  Or use port-forward:"
print_info "    kubectl port-forward service/frontend-service 8080:80 -n login-system"
print_info "    Then visit: http://localhost:8080"

print_info "\nView Pod status:"
print_info "  kubectl get pods -n login-system"

print_info "\nView logs:"
print_info "  Backend:  kubectl logs -f deployment/backend-deployment -n login-system"
print_info "  Frontend: kubectl logs -f deployment/frontend-deployment -n login-system"
print_info "  Database: kubectl logs -f deployment/postgres-deployment -n login-system"

print_info "\nIf Ingress is deployed, configure hosts file:"
print_info "  echo \"$NODE_IP login.local www.login.local api.login.local\" | sudo tee -a /etc/hosts"
print_info "  Then visit: http://login.local"

print_info "\n🎉 Deployment successful!"
