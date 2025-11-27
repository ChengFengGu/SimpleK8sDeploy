#!/bin/bash
# ============================================
# 数据备份脚本
# 备份 PostgreSQL 数据库
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

print_title "PostgreSQL 数据库备份"

# 备份目录
BACKUP_DIR="${BACKUP_DIR:-./backups}"
mkdir -p "$BACKUP_DIR"

# 备份文件名
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/logindb_backup_$TIMESTAMP.sql"

print_info "备份目录: $BACKUP_DIR"
print_info "备份文件: $BACKUP_FILE"

# 获取 PostgreSQL Pod 名称
POD_NAME=$(kubectl get pods -n login-system -l app=postgres -o jsonpath='{.items[0].metadata.name}')
print_info "PostgreSQL Pod: $POD_NAME"

# 执行备份
print_info "开始备份数据库..."

kubectl exec -n login-system "$POD_NAME" -- \
    pg_dump -U postgres logindb > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    # 获取备份文件大小
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    print_info "✅ 备份成功！"
    print_info "   文件: $BACKUP_FILE"
    print_info "   大小: $SIZE"
    
    # 压缩备份文件
    print_info "正在压缩备份文件..."
    gzip "$BACKUP_FILE"
    COMPRESSED_FILE="${BACKUP_FILE}.gz"
    COMPRESSED_SIZE=$(du -h "$COMPRESSED_FILE" | cut -f1)
    print_info "✅ 压缩完成！"
    print_info "   文件: $COMPRESSED_FILE"
    print_info "   大小: $COMPRESSED_SIZE"
    
    # 显示备份内容预览
    print_info "\n备份内容预览:"
    gunzip -c "$COMPRESSED_FILE" | head -20
    
    # 清理旧备份（保留最近7天）
    print_info "\n清理旧备份（保留最近7天）..."
    find "$BACKUP_DIR" -name "logindb_backup_*.sql.gz" -type f -mtime +7 -delete
    
    # 显示所有备份
    print_info "\n当前所有备份:"
    ls -lh "$BACKUP_DIR"/logindb_backup_*.sql.gz 2>/dev/null || print_warn "没有找到其他备份文件"
    
else
    print_error "❌ 备份失败！"
    exit 1
fi

print_title "备份完成"

print_info "\n💡 恢复备份命令:"
echo "  ./scripts/restore.sh $COMPRESSED_FILE"

print_info "\n💡 下载备份到本地:"
echo "  scp $COMPRESSED_FILE user@your-pc:/path/to/local/"

print_info "\n💡 定期备份建议:"
echo "  添加到 crontab: 0 2 * * * cd /root/learn/01-k8s && ./scripts/backup.sh"

