#!/bin/bash
# ============================================
# Kubernetes 清理脚本
# 删除所有部署的资源
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warn "==================== 警告 ===================="
print_warn "此操作将删除 login-system 命名空间中的所有资源"
print_warn "包括数据库数据！"
print_warn "=============================================="

read -p "确定要继续吗? (输入 'yes' 确认): " confirm

if [ "$confirm" != "yes" ]; then
    print_info "取消操作"
    exit 0
fi

print_info "开始清理资源..."

# 删除 Ingress
print_info "删除 Ingress..."
kubectl delete ingress --all -n login-system --ignore-not-found=true

# 删除 Frontend
print_info "删除 Frontend..."
kubectl delete -f ../k8s/frontend/ --ignore-not-found=true

# 删除 Backend
print_info "删除 Backend..."
kubectl delete -f ../k8s/backend/ --ignore-not-found=true

# 删除 PostgreSQL
print_info "删除 PostgreSQL..."
kubectl delete -f ../k8s/postgres/ --ignore-not-found=true

# 删除 PV
print_info "删除 PersistentVolume..."
kubectl delete pv postgres-pv --ignore-not-found=true

# 删除命名空间
print_info "删除命名空间..."
kubectl delete namespace login-system --ignore-not-found=true

print_info "清理完成！"
print_info "如果需要删除本地数据，请手动删除: /mnt/data/postgres"

