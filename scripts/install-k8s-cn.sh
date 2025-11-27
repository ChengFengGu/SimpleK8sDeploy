#!/bin/bash
# ============================================
# K8s 安装脚本 - 使用国内镜像源
# 适用于中国大陆网络环境
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

print_step "K8s 环境安装（使用国内镜像）"

# ============================================
# 0. 检查 Docker
# ============================================
print_step "步骤 0: 检查环境"

if ! command -v docker &> /dev/null; then
    print_error "Docker 未安装，请先安装 Docker"
    exit 1
fi

print_info "✅ Docker 已安装: $(docker --version)"

# ============================================
# 1. 检查 Minikube
# ============================================
print_step "步骤 1: 检查 Minikube"

if command -v minikube &> /dev/null; then
    print_info "✅ Minikube 已安装: $(minikube version --short)"
else
    print_error "Minikube 未安装，请先安装 Minikube"
    print_info "安装命令："
    print_info "  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
    print_info "  sudo install minikube-linux-amd64 /usr/local/bin/minikube"
    exit 1
fi

if command -v kubectl &> /dev/null; then
    print_info "✅ kubectl 已安装: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
    print_warn "kubectl 未安装，将由 minikube 自动配置"
fi

# ============================================
# 2. 清理旧环境
# ============================================
print_step "步骤 2: 清理旧环境"

print_info "停止并删除旧的 Minikube 集群..."
minikube delete --all || true
rm -rf ~/.minikube ~/.kube
print_info "✅ 清理完成"

# ============================================
# 3. 启动 Minikube（使用国内镜像）
# ============================================
print_step "步骤 3: 启动 Minikube 集群"

print_info "使用阿里云镜像仓库启动 Minikube..."
print_info "Minikube 版本: $(minikube version --short)"

# ============================================
# 3.1 预先拉取 kicbase 基础镜像（从阿里云）
# ============================================
print_info "正在从阿里云拉取 kicbase 基础镜像..."
KICBASE_VERSION="v0.0.48"

# 从阿里云拉取镜像
if docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kicbase:${KICBASE_VERSION}; then
    print_info "✅ 基础镜像下载完成"
    
    # 给镜像打标签，让 minikube 使用本地镜像
    print_info "正在重新标记镜像..."
    docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kicbase:${KICBASE_VERSION} \
        gcr.io/k8s-minikube/kicbase:${KICBASE_VERSION}
    docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kicbase:${KICBASE_VERSION} \
        kicbase/stable:${KICBASE_VERSION}
    print_info "✅ 镜像标记完成"
else
    print_warn "从阿里云拉取镜像失败，将尝试从官方源拉取（可能较慢）"
fi

# ============================================
# 3.2 启动 Minikube 集群
# ============================================
print_info "正在启动 Minikube 集群..."
print_info "这可能需要 5-10 分钟，请耐心等待..."

# 使用混合镜像策略：
# 1. 容器镜像: 使用阿里云镜像仓库（快）
# 2. 二进制文件: 通过代理从 Google 官方下载
# 
# 问题：--image-repository 会同时影响容器镜像和二进制文件的下载源
# 解决：通过代理全部从 Google 官方下载，速度应该可以接受
print_info "配置下载策略：通过代理从 Google 官方源下载..."

# 导出环境变量，让 minikube 使用代理
export HTTP_PROXY=http://172.19.160.1:8093
export HTTPS_PROXY=http://172.19.160.1:8093  
export NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,registry.cn-hangzhou.aliyuncs.com

# 不使用 --image-repository，让所有内容通过代理从官方源下载
# 这样可以确保获取最新版本，并且避免阿里云镜像同步延迟问题
minikube start \
    --driver=docker \
    --cpus=2 \
    --memory=4096 \
    --disk-size=20g \
    --force \
    --base-image=gcr.io/k8s-minikube/kicbase:${KICBASE_VERSION}

# 清理代理环境变量
unset HTTP_PROXY HTTPS_PROXY NO_PROXY

print_info "✅ Minikube 启动完成"

# ============================================
# 4. 配置 kubectl
# ============================================
print_step "步骤 4: 配置 kubectl"

kubectl config use-context minikube
print_info "✅ kubectl 配置完成"

# 验证集群
print_info "验证集群状态..."
kubectl cluster-info
kubectl get nodes

# ============================================
# 5. 安装 Nginx Ingress Controller
# ============================================
print_step "步骤 5: 安装 Nginx Ingress Controller"

print_info "启用 Ingress 插件..."
minikube addons enable ingress

print_info "等待 Ingress Controller 就绪（最多 120 秒）..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

print_info "✅ Ingress Controller 安装完成"

# ============================================
# 6. 安装 Metrics Server
# ============================================
print_step "步骤 6: 安装 Metrics Server"

print_info "启用 Metrics Server 插件..."
minikube addons enable metrics-server

print_info "✅ Metrics Server 安装完成"

# ============================================
# 7. 配置 Docker 环境（可选）
# ============================================
print_step "步骤 7: 配置 Docker 环境"

print_info "配置 Docker 使用 Minikube 的 Docker 守护进程..."
print_info "运行以下命令使用 Minikube 的 Docker:"
print_info "  eval \$(minikube docker-env)"

# ============================================
# 验证安装
# ============================================
print_step "验证安装"

print_info "集群信息:"
kubectl cluster-info

print_info "\n节点状态:"
kubectl get nodes -o wide

print_info "\nIngress Controller:"
kubectl get pods -n ingress-nginx

print_info "\nMinikube 插件:"
minikube addons list | grep enabled

print_info "\nMinikube IP:"
MINIKUBE_IP=$(minikube ip)
echo $MINIKUBE_IP

# ============================================
# 完成
# ============================================
print_step "安装完成！"

print_info "\n✅ K8s 集群已就绪！"
print_info "\n常用命令:"
echo "  minikube status        # 查看集群状态"
echo "  minikube dashboard     # 打开仪表板"
echo "  minikube stop          # 停止集群"
echo "  minikube start         # 启动集群"
echo "  minikube delete        # 删除集群"
echo "  kubectl get nodes      # 查看节点"
echo "  eval \$(minikube docker-env)  # 使用 Minikube 的 Docker"

print_info "\n下一步:"
print_info "  1. 配置 Docker 环境: eval \$(minikube docker-env)"
print_info "  2. 构建 Docker 镜像"
print_info "  3. 运行部署脚本: ./scripts/deploy.sh"

print_info "\n🎉 准备就绪！可以开始部署应用了！"

