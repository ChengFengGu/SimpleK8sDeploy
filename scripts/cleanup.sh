#!/bin/bash
# ============================================
# Kubernetes 清理脚本 / Kubernetes Cleanup Script
# 删除所有部署的资源 / Delete all deployed resources
# ============================================

set -e

# 颜色定义 / Color definitions
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

print_warn "==================== 警告 / WARNING ===================="
print_warn "此操作将删除 login-system 命名空间中的所有资源"
print_warn "This will delete all resources in login-system namespace"
print_warn "包括数据库数据！/ Including database data!"
print_warn "========================================================"

read -p "确定要继续吗? / Continue? (输入/type 'yes' 确认/to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    print_info "取消操作 / Operation cancelled"
    exit 0
fi

print_info "开始清理资源... / Starting cleanup..."

# 删除 Ingress / Delete Ingress
print_info "删除 Ingress... / Deleting Ingress..."
kubectl delete ingress --all -n login-system --ignore-not-found=true

# 删除 Frontend / Delete Frontend
print_info "删除 Frontend... / Deleting Frontend..."
kubectl delete -f ../k8s/frontend/ --ignore-not-found=true

# 删除 Backend / Delete Backend
print_info "删除 Backend... / Deleting Backend..."
kubectl delete -f ../k8s/backend/ --ignore-not-found=true

# 删除 PostgreSQL / Delete PostgreSQL
print_info "删除 PostgreSQL... / Deleting PostgreSQL..."
kubectl delete -f ../k8s/postgres/ --ignore-not-found=true

# 删除 PV / Delete PV
print_info "删除 PersistentVolume... / Deleting PersistentVolume..."
kubectl delete pv postgres-pv --ignore-not-found=true

# 删除命名空间 / Delete namespace
print_info "删除命名空间... / Deleting namespace..."
kubectl delete namespace login-system --ignore-not-found=true

print_info "清理完成！/ Cleanup completed!"
print_info "如果需要删除本地数据，请手动删除: /mnt/data/postgres"
print_info "To delete local data, manually remove: /mnt/data/postgres"
