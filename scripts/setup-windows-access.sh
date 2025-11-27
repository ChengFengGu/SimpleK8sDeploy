#!/bin/bash
# ============================================
# Windows 访问配置脚本
# 自动配置从 Windows 访问 WSL2 中的 K8s 服务
# ============================================

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_title() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# 获取网络信息
WSL_IP=$(hostname -I | awk '{print $1}')
MINIKUBE_IP=$(minikube ip)
NODE_PORT=$(kubectl get svc frontend-service -n login-system -o jsonpath='{.spec.ports[0].nodePort}')

print_title "Windows 访问配置向导"

echo ""
print_info "📋 当前网络信息："
echo "  WSL2 IP:      $WSL_IP"
echo "  Minikube IP:  $MINIKUBE_IP"
echo "  NodePort:     $NODE_PORT"
echo ""

print_title "选择访问方式"

echo ""
echo "1. NodePort 方式（推荐，最稳定）"
echo "   - 无需额外配置"
echo "   - 稳定可靠"
echo "   - Windows 访问: http://$MINIKUBE_IP:$NODE_PORT"
echo ""
echo "2. Port-forward 到 8080（推荐，最简单）"
echo "   - 一条命令搞定"
echo "   - Windows 访问: http://$WSL_IP:8080"
echo ""
echo "3. Port-forward 到 80 + 域名（高级）"
echo "   - 需要修改 Windows hosts"
echo "   - Windows 访问: http://login.local"
echo ""

read -p "请选择方式 (1/2/3): " choice

case $choice in
    1)
        print_title "方式 1: NodePort 访问"
        echo ""
        print_info "✅ 无需额外配置，直接访问！"
        echo ""
        print_info "🌐 Windows 浏览器访问地址："
        echo "   http://$MINIKUBE_IP:$NODE_PORT"
        echo ""
        print_info "或者使用 WSL2 IP："
        echo "   http://$WSL_IP:$NODE_PORT"
        echo ""
        print_info "💡 API 访问："
        echo "   http://$MINIKUBE_IP:$NODE_PORT/api/health/"
        echo ""
        ;;

    2)
        print_title "方式 2: Port-forward 到 8080"
        echo ""
        print_info "正在启动 port-forward..."
        
        # 停止旧的 port-forward
        pkill -f "port-forward.*8080.*frontend-service" 2>/dev/null || true
        
        # 启动新的 port-forward（后台运行，监听所有网卡）
        nohup kubectl port-forward -n login-system service/frontend-service 8080:80 --address 0.0.0.0 > /tmp/k8s-port-forward-8080.log 2>&1 &
        PID=$!
        
        sleep 3
        
        if ps -p $PID > /dev/null; then
            print_info "✅ Port-forward 已启动 (PID: $PID)"
            echo ""
            print_info "🌐 Windows 浏览器访问地址："
            echo "   http://$WSL_IP:8080"
            echo ""
            print_info "💡 API 访问："
            echo "   http://$WSL_IP:8080/api/health/"
            echo ""
            print_info "📝 日志文件: /tmp/k8s-port-forward-8080.log"
            echo ""
            print_warn "⚠️  停止 port-forward: kill $PID"
            echo ""
            
            # 测试访问
            print_info "🧪 测试访问..."
            sleep 2
            if curl -s http://localhost:8080/api/health/ > /dev/null; then
                print_info "✅ 本地测试成功！"
            else
                print_warn "⚠️  本地测试失败，请检查日志"
            fi
        else
            print_warn "❌ Port-forward 启动失败"
            cat /tmp/k8s-port-forward-8080.log
        fi
        ;;

    3)
        print_title "方式 3: Port-forward + 域名"
        echo ""
        print_info "正在启动 port-forward (端口 80)..."
        
        # 停止旧的 port-forward
        pkill -f "port-forward.*:80.*frontend-service" 2>/dev/null || true
        
        # 启动新的 port-forward
        nohup kubectl port-forward -n login-system service/frontend-service 80:80 --address 0.0.0.0 > /tmp/k8s-port-forward-80.log 2>&1 &
        PID=$!
        
        sleep 3
        
        if ps -p $PID > /dev/null; then
            print_info "✅ Port-forward 已启动 (PID: $PID)"
            echo ""
            print_info "📝 请在 Windows 中配置 hosts 文件："
            echo ""
            echo "   1. 以管理员身份打开记事本"
            echo "   2. 打开文件: C:\\Windows\\System32\\drivers\\etc\\hosts"
            echo "   3. 在文件末尾添加："
            echo ""
            echo "      # K8s Login System"
            echo "      $WSL_IP  login.local www.login.local api.login.local"
            echo ""
            echo "   4. 保存文件"
            echo "   5. 在 PowerShell (管理员) 中执行: ipconfig /flushdns"
            echo ""
            print_info "🌐 配置完成后，Windows 浏览器访问："
            echo "   http://login.local"
            echo ""
            print_warn "⚠️  停止 port-forward: kill $PID"
            echo ""
        else
            print_warn "❌ Port-forward 启动失败"
            print_warn "可能是端口 80 被占用，尝试使用方式 2"
            cat /tmp/k8s-port-forward-80.log
        fi
        ;;

    *)
        print_warn "❌ 无效选择"
        exit 1
        ;;
esac

print_title "配置完成"

echo ""
print_info "📚 更多信息请查看: ./Windows访问配置.md"
echo ""
print_info "🔧 常用命令:"
echo "   # 查看 port-forward 进程"
echo "   ps aux | grep port-forward"
echo ""
echo "   # 停止所有 port-forward"
echo "   pkill -f 'port-forward.*frontend-service'"
echo ""
echo "   # 查看日志"
echo "   tail -f /tmp/k8s-port-forward-*.log"
echo ""
print_info "✨ 祝使用愉快！"

