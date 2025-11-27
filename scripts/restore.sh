#!/bin/bash
# ============================================
# 数据恢复脚本 / Database Restore Script
# 恢复 PostgreSQL 数据库 / Restore PostgreSQL database
# ============================================

set -e

# 颜色定义 / Color definitions
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

# 检查参数 / Check arguments
if [ $# -eq 0 ]; then
    print_error "用法 / Usage: $0 <backup_file.sql.gz>"
    echo ""
    print_info "可用的备份文件 / Available backup files:"
    ls -lh ./backups/logindb_backup_*.sql.gz 2>/dev/null || print_warn "没有找到备份文件 / No backup files found"
    exit 1
fi

BACKUP_FILE="$1"

# 检查备份文件是否存在 / Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    print_error "备份文件不存在 / Backup file does not exist: $BACKUP_FILE"
    exit 1
fi

# 检查命名空间是否存在 / Check if namespace exists
if ! kubectl get namespace login-system &> /dev/null; then
    print_error "命名空间 login-system 不存在 / Namespace login-system does not exist"
    exit 1
fi

# 检查 PostgreSQL Pod 是否运行 / Check if PostgreSQL Pod is running
if ! kubectl get pods -n login-system -l app=postgres | grep -q Running; then
    print_error "PostgreSQL Pod 未运行 / PostgreSQL Pod is not running"
    exit 1
fi

print_title "PostgreSQL 数据库恢复 / PostgreSQL Database Restore"

print_info "备份文件 / Backup file: $BACKUP_FILE"
SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
print_info "文件大小 / File size: $SIZE"

# 获取 PostgreSQL Pod 名称 / Get PostgreSQL Pod name
POD_NAME=$(kubectl get pods -n login-system -l app=postgres -o jsonpath='{.items[0].metadata.name}')
print_info "PostgreSQL Pod: $POD_NAME"

# 警告确认 / Warning confirmation
print_warn "========================================="
print_warn "⚠️  警告 / WARNING：此操作将覆盖现有数据库！/ This will overwrite existing database!"
print_warn "========================================="
read -p "确定要继续吗? / Continue? (输入/type 'yes' 确认/to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    print_info "取消操作 / Operation cancelled"
    exit 0
fi

# 创建临时目录 / Create temporary directory
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

# 解压备份文件 / Decompress backup file
print_info "解压备份文件... / Decompressing backup file..."
if [[ "$BACKUP_FILE" == *.gz ]]; then
    gunzip -c "$BACKUP_FILE" > "$TMP_DIR/restore.sql"
else
    cp "$BACKUP_FILE" "$TMP_DIR/restore.sql"
fi

# 显示备份信息 / Show backup information
print_info "\n备份文件信息 / Backup file information:"
head -20 "$TMP_DIR/restore.sql"

# 停止 Backend Pod（避免数据冲突）/ Stop Backend Pods (avoid data conflict)
print_info "\n停止 Backend Pods... / Stopping Backend Pods..."
kubectl scale deployment backend-deployment --replicas=0 -n login-system
sleep 5

# 执行恢复 / Execute restore
print_info "开始恢复数据库... / Starting database restore..."
print_info "这可能需要几分钟时间，请耐心等待... / This may take several minutes, please be patient..."

# 删除现有数据库并重新创建 / Drop existing database and recreate
kubectl exec -n login-system "$POD_NAME" -- \
    psql -U postgres -c "DROP DATABASE IF EXISTS logindb;"

kubectl exec -n login-system "$POD_NAME" -- \
    psql -U postgres -c "CREATE DATABASE logindb;"

# 恢复数据 / Restore data
cat "$TMP_DIR/restore.sql" | kubectl exec -i -n login-system "$POD_NAME" -- \
    psql -U postgres -d logindb

if [ $? -eq 0 ]; then
    print_info "✅ 数据库恢复成功！/ Database restore successful!"
    
    # 验证恢复 / Verify restore
    print_info "\n验证数据库... / Verifying database..."
    TABLES=$(kubectl exec -n login-system "$POD_NAME" -- \
        psql -U postgres -d logindb -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';")
    print_info "表数量 / Table count: $TABLES"
    
    USER_COUNT=$(kubectl exec -n login-system "$POD_NAME" -- \
        psql -U postgres -d logindb -t -c "SELECT COUNT(*) FROM authentication_user;" 2>/dev/null || echo "0")
    print_info "用户数量 / User count: $USER_COUNT"
    
    # 重启 Backend Pod / Restart Backend Pods
    print_info "\n重启 Backend Pods... / Restarting Backend Pods..."
    kubectl scale deployment backend-deployment --replicas=3 -n login-system
    
    # 等待 Backend 就绪 / Wait for Backend to be ready
    print_info "等待 Backend 就绪... / Waiting for Backend to be ready..."
    kubectl wait --for=condition=ready pod -l app=backend -n login-system --timeout=120s || true
    
    print_title "恢复完成 / Restore Complete"
    print_info "✅ 数据库已成功恢复！/ Database successfully restored!"
    print_info "\n💡 验证恢复 / Verify restore:"
    echo "  kubectl exec -it -n login-system deployment/postgres-deployment -- psql -U postgres -d logindb"
    echo "  \dt"
    echo "  SELECT * FROM authentication_user;"
    
else
    print_error "❌ 数据库恢复失败！/ Database restore failed!"
    
    # 恢复 Backend Pod / Restore Backend Pods
    print_info "恢复 Backend Pods... / Restoring Backend Pods..."
    kubectl scale deployment backend-deployment --replicas=3 -n login-system
    
    exit 1
fi
