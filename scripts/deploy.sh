#!/bin/bash
# ============================================
# Kubernetes 部署脚本
# 自动部署整个登录系统到 K8s 集群
# ============================================

set -e  # 遇到错误立即退出

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 打印函数
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 kubectl 是否安装
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl 未安装，请先安装 kubectl"
    exit 1
fi

# 项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
K8S_DIR="$PROJECT_ROOT/k8s"

print_info "开始部署登录系统到 Kubernetes..."
print_info "项目根目录: $PROJECT_ROOT"

# ============================================
# 步骤 1: 创建命名空间
# ============================================
print_info "步骤 1: 创建命名空间..."
kubectl apply -f "$K8S_DIR/namespace.yaml"

# 等待命名空间创建
sleep 2

# ============================================
# 步骤 2: 部署 PostgreSQL
# ============================================
print_info "步骤 2: 部署 PostgreSQL 数据库..."

print_info "  2.1 创建 Secret..."
kubectl apply -f "$K8S_DIR/postgres/postgres-secret.yaml"

print_info "  2.2 创建 ConfigMap..."
kubectl apply -f "$K8S_DIR/postgres/postgres-configmap.yaml"

print_info "  2.3 创建 PersistentVolume..."
kubectl apply -f "$K8S_DIR/postgres/postgres-pv.yaml"

print_info "  2.4 创建 PersistentVolumeClaim..."
kubectl apply -f "$K8S_DIR/postgres/postgres-pvc.yaml"

print_info "  2.5 创建 Deployment..."
kubectl apply -f "$K8S_DIR/postgres/postgres-deployment.yaml"

print_info "  2.6 创建 Service..."
kubectl apply -f "$K8S_DIR/postgres/postgres-service.yaml"

# 等待 PostgreSQL 就绪
print_info "  等待 PostgreSQL 就绪..."
kubectl wait --for=condition=ready pod -l app=postgres -n login-system --timeout=120s || true

# ============================================
# 步骤 3: 部署 Backend
# ============================================
print_info "步骤 3: 部署 Django 后端..."

print_info "  3.1 创建 Secret..."
kubectl apply -f "$K8S_DIR/backend/backend-secret.yaml"

print_info "  3.2 创建 ConfigMap..."
kubectl apply -f "$K8S_DIR/backend/backend-configmap.yaml"

print_info "  3.3 创建 Deployment..."
kubectl apply -f "$K8S_DIR/backend/backend-deployment.yaml"

print_info "  3.4 创建 Service..."
kubectl apply -f "$K8S_DIR/backend/backend-service.yaml"

# 等待 Backend 就绪
print_info "  等待 Backend 就绪..."
kubectl wait --for=condition=ready pod -l app=backend -n login-system --timeout=120s || true

# ============================================
# 步骤 4: 部署 Frontend
# ============================================
print_info "步骤 4: 部署 Vue3 前端..."

print_info "  4.1 创建 ConfigMap..."
kubectl apply -f "$K8S_DIR/frontend/frontend-configmap.yaml"

print_info "  4.2 创建 Deployment..."
kubectl apply -f "$K8S_DIR/frontend/frontend-deployment.yaml"

print_info "  4.3 创建 Service..."
kubectl apply -f "$K8S_DIR/frontend/frontend-service.yaml"

# 等待 Frontend 就绪
print_info "  等待 Frontend 就绪..."
kubectl wait --for=condition=ready pod -l app=frontend -n login-system --timeout=120s || true

# ============================================
# 步骤 5: 部署 Ingress (可选)
# ============================================
read -p "是否部署 Ingress? (需要先安装 Ingress Controller) [y/N]: " deploy_ingress
if [[ "$deploy_ingress" =~ ^[Yy]$ ]]; then
    print_info "步骤 5: 部署 Ingress..."
    kubectl apply -f "$K8S_DIR/ingress.yaml"
else
    print_warn "跳过 Ingress 部署"
fi

# ============================================
# 部署完成
# ============================================
print_info "============================================"
print_info "部署完成！"
print_info "============================================"

# 显示部署状态
print_info "\n查看部署状态:"
kubectl get all -n login-system

# 获取访问信息
print_info "\n访问信息:"
NODE_PORT=$(kubectl get service frontend-service -n login-system -o jsonpath='{.spec.ports[0].nodePort}')
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

print_info "  前端 (NodePort): http://$NODE_IP:$NODE_PORT"
print_info "  或使用 port-forward:"
print_info "    kubectl port-forward service/frontend-service 8080:80 -n login-system"
print_info "    然后访问: http://localhost:8080"

print_info "\n查看 Pod 状态:"
print_info "  kubectl get pods -n login-system"

print_info "\n查看日志:"
print_info "  Backend:  kubectl logs -f deployment/backend-deployment -n login-system"
print_info "  Frontend: kubectl logs -f deployment/frontend-deployment -n login-system"
print_info "  Database: kubectl logs -f deployment/postgres-deployment -n login-system"

print_info "\n如果部署了 Ingress，请配置 hosts 文件:"
print_info "  echo \"$NODE_IP login.local www.login.local api.login.local\" | sudo tee -a /etc/hosts"
print_info "  然后访问: http://login.local"

print_info "\n🎉 部署成功！"

