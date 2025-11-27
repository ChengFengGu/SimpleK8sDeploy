#!/bin/bash
# ============================================
# 数据恢复脚本
# 恢复 PostgreSQL 数据库
# ============================================

set -e

# 颜色定义
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

print_title() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# 检查参数
if [ $# -eq 0 ]; then
    print_error "用法: $0 <backup_file.sql.gz>"
    echo ""
    print_info "可用的备份文件:"
    ls -lh ./backups/logindb_backup_*.sql.gz 2>/dev/null || print_warn "没有找到备份文件"
    exit 1
fi

BACKUP_FILE="$1"

# 检查备份文件是否存在
if [ ! -f "$BACKUP_FILE" ]; then
    print_error "备份文件不存在: $BACKUP_FILE"
    exit 1
fi

# 检查命名空间是否存在
if ! kubectl get namespace login-system &> /dev/null; then
    print_error "命名空间 login-system 不存在"
    exit 1
fi

# 检查 PostgreSQL Pod 是否运行
if ! kubectl get pods -n login-system -l app=postgres | grep -q Running; then
    print_error "PostgreSQL Pod 未运行"
    exit 1
fi

print_title "PostgreSQL 数据库恢复"

print_info "备份文件: $BACKUP_FILE"
SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
print_info "文件大小: $SIZE"

# 获取 PostgreSQL Pod 名称
POD_NAME=$(kubectl get pods -n login-system -l app=postgres -o jsonpath='{.items[0].metadata.name}')
print_info "PostgreSQL Pod: $POD_NAME"

# 警告确认
print_warn "========================================="
print_warn "⚠️  警告：此操作将覆盖现有数据库！"
print_warn "========================================="
read -p "确定要继续吗? (输入 'yes' 确认): " confirm

if [ "$confirm" != "yes" ]; then
    print_info "取消操作"
    exit 0
fi

# 创建临时目录
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

# 解压备份文件
print_info "解压备份文件..."
if [[ "$BACKUP_FILE" == *.gz ]]; then
    gunzip -c "$BACKUP_FILE" > "$TMP_DIR/restore.sql"
else
    cp "$BACKUP_FILE" "$TMP_DIR/restore.sql"
fi

# 显示备份信息
print_info "\n备份文件信息:"
head -20 "$TMP_DIR/restore.sql"

# 停止 Backend Pod（避免数据冲突）
print_info "\n停止 Backend Pods..."
kubectl scale deployment backend-deployment --replicas=0 -n login-system
sleep 5

# 执行恢复
print_info "开始恢复数据库..."
print_info "这可能需要几分钟时间，请耐心等待..."

# 删除现有数据库并重新创建
kubectl exec -n login-system "$POD_NAME" -- \
    psql -U postgres -c "DROP DATABASE IF EXISTS logindb;"

kubectl exec -n login-system "$POD_NAME" -- \
    psql -U postgres -c "CREATE DATABASE logindb;"

# 恢复数据
cat "$TMP_DIR/restore.sql" | kubectl exec -i -n login-system "$POD_NAME" -- \
    psql -U postgres -d logindb

if [ $? -eq 0 ]; then
    print_info "✅ 数据库恢复成功！"
    
    # 验证恢复
    print_info "\n验证数据库..."
    TABLES=$(kubectl exec -n login-system "$POD_NAME" -- \
        psql -U postgres -d logindb -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';")
    print_info "表数量: $TABLES"
    
    USER_COUNT=$(kubectl exec -n login-system "$POD_NAME" -- \
        psql -U postgres -d logindb -t -c "SELECT COUNT(*) FROM authentication_user;" 2>/dev/null || echo "0")
    print_info "用户数量: $USER_COUNT"
    
    # 重启 Backend Pod
    print_info "\n重启 Backend Pods..."
    kubectl scale deployment backend-deployment --replicas=3 -n login-system
    
    # 等待 Backend 就绪
    print_info "等待 Backend 就绪..."
    kubectl wait --for=condition=ready pod -l app=backend -n login-system --timeout=120s || true
    
    print_title "恢复完成"
    print_info "✅ 数据库已成功恢复！"
    print_info "\n💡 验证恢复:"
    echo "  kubectl exec -it -n login-system deployment/postgres-deployment -- psql -U postgres -d logindb"
    echo "  \dt"
    echo "  SELECT * FROM authentication_user;"
    
else
    print_error "❌ 数据库恢复失败！"
    
    # 恢复 Backend Pod
    print_info "恢复 Backend Pods..."
    kubectl scale deployment backend-deployment --replicas=3 -n login-system
    
    exit 1
fi

