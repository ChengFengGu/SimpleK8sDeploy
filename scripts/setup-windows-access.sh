#!/bin/bash
# ============================================
# Windows 访问配置脚本 / Windows Access Setup Script
# 自动配置从 Windows 访问 WSL2 中的 K8s 服务
# Auto configure access to K8s services in WSL2 from Windows
# ============================================

set -e

# 颜色定义 / Color definitions
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

# 获取网络信息 / Get network information
WSL_IP=$(hostname -I | awk '{print $1}')
MINIKUBE_IP=$(minikube ip)
NODE_PORT=$(kubectl get svc frontend-service -n login-system -o jsonpath='{.spec.ports[0].nodePort}')

print_title "Windows 访问配置向导 / Windows Access Configuration Wizard"

echo ""
print_info "📋 当前网络信息 / Current network information:"
echo "  WSL2 IP:      $WSL_IP"
echo "  Minikube IP:  $MINIKUBE_IP"
echo "  NodePort:     $NODE_PORT"
echo ""

print_title "选择访问方式 / Choose Access Method"

echo ""
echo "1. NodePort 方式 / NodePort Method (推荐，最稳定 / Recommended, most stable)"
echo "   - 无需额外配置 / No extra configuration needed"
echo "   - 稳定可靠 / Stable and reliable"
echo "   - Windows 访问 / Windows access: http://$MINIKUBE_IP:$NODE_PORT"
echo ""
echo "2. Port-forward 到 8080 / Port-forward to 8080 (推荐，最简单 / Recommended, simplest)"
echo "   - 一条命令搞定 / One command setup"
echo "   - Windows 访问 / Windows access: http://$WSL_IP:8080"
echo ""
echo "3. Port-forward 到 80 + 域名 / Port-forward to 80 + domain (高级 / Advanced)"
echo "   - 需要修改 Windows hosts / Requires Windows hosts modification"
echo "   - Windows 访问 / Windows access: http://login.local"
echo ""

read -p "请选择方式 / Choose method (1/2/3): " choice

case $choice in
    1)
        print_title "方式 1: NodePort 访问 / Method 1: NodePort Access"
        echo ""
        print_info "✅ 无需额外配置，直接访问！/ No extra setup, access directly!"
        echo ""
        print_info "🌐 Windows 浏览器访问地址 / Windows browser access URL:"
        echo "   http://$MINIKUBE_IP:$NODE_PORT"
        echo ""
        print_info "或者使用 WSL2 IP / Or use WSL2 IP:"
        echo "   http://$WSL_IP:$NODE_PORT"
        echo ""
        print_info "💡 API 访问 / API access:"
        echo "   http://$MINIKUBE_IP:$NODE_PORT/api/health/"
        echo ""
        ;;

    2)
        print_title "方式 2: Port-forward 到 8080 / Method 2: Port-forward to 8080"
        echo ""
        print_info "正在启动 port-forward... / Starting port-forward..."
        
        # 停止旧的 port-forward / Stop old port-forward
        pkill -f "port-forward.*8080.*frontend-service" 2>/dev/null || true
        
        # 启动新的 port-forward（后台运行，监听所有网卡）
        # Start new port-forward (background, listen on all interfaces)
        nohup kubectl port-forward -n login-system service/frontend-service 8080:80 --address 0.0.0.0 > /tmp/k8s-port-forward-8080.log 2>&1 &
        PID=$!
        
        sleep 3
        
        if ps -p $PID > /dev/null; then
            print_info "✅ Port-forward 已启动 / Port-forward started (PID: $PID)"
            echo ""
            print_info "🌐 Windows 浏览器访问地址 / Windows browser access URL:"
            echo "   http://$WSL_IP:8080"
            echo ""
            print_info "💡 API 访问 / API access:"
            echo "   http://$WSL_IP:8080/api/health/"
            echo ""
            print_info "📝 日志文件 / Log file: /tmp/k8s-port-forward-8080.log"
            echo ""
            print_warn "⚠️  停止 port-forward / Stop port-forward: kill $PID"
            echo ""
            
            # 测试访问 / Test access
            print_info "🧪 测试访问... / Testing access..."
            sleep 2
            if curl -s http://localhost:8080/api/health/ > /dev/null; then
                print_info "✅ 本地测试成功！/ Local test successful!"
            else
                print_warn "⚠️  本地测试失败，请检查日志 / Local test failed, check logs"
            fi
        else
            print_warn "❌ Port-forward 启动失败 / Port-forward startup failed"
            cat /tmp/k8s-port-forward-8080.log
        fi
        ;;

    3)
        print_title "方式 3: Port-forward + 域名 / Method 3: Port-forward + Domain"
        echo ""
        print_info "正在启动 port-forward (端口 80)... / Starting port-forward (port 80)..."
        
        # 停止旧的 port-forward / Stop old port-forward
        pkill -f "port-forward.*:80.*frontend-service" 2>/dev/null || true
        
        # 启动新的 port-forward / Start new port-forward
        nohup kubectl port-forward -n login-system service/frontend-service 80:80 --address 0.0.0.0 > /tmp/k8s-port-forward-80.log 2>&1 &
        PID=$!
        
        sleep 3
        
        if ps -p $PID > /dev/null; then
            print_info "✅ Port-forward 已启动 / Port-forward started (PID: $PID)"
            echo ""
            print_info "📝 请在 Windows 中配置 hosts 文件 / Configure hosts file in Windows:"
            echo ""
            echo "   1. 以管理员身份打开记事本 / Open Notepad as Administrator"
            echo "   2. 打开文件 / Open file: C:\\Windows\\System32\\drivers\\etc\\hosts"
            echo "   3. 在文件末尾添加 / Add to end of file:"
            echo ""
            echo "      # K8s Login System"
            echo "      $WSL_IP  login.local www.login.local api.login.local"
            echo ""
            echo "   4. 保存文件 / Save file"
            echo "   5. 在 PowerShell (管理员) 中执行 / Run in PowerShell (Admin): ipconfig /flushdns"
            echo ""
            print_info "🌐 配置完成后，Windows 浏览器访问 / After configuration, access from Windows:"
            echo "   http://login.local"
            echo ""
            print_warn "⚠️  停止 port-forward / Stop port-forward: kill $PID"
            echo ""
        else
            print_warn "❌ Port-forward 启动失败 / Port-forward startup failed"
            print_warn "可能是端口 80 被占用，尝试使用方式 2 / Port 80 may be in use, try method 2"
            cat /tmp/k8s-port-forward-80.log
        fi
        ;;

    *)
        print_warn "❌ 无效选择 / Invalid choice"
        exit 1
        ;;
esac

print_title "配置完成 / Configuration Complete"

echo ""
print_info "🔧 常用命令 / Common commands:"
echo "   # 查看 port-forward 进程 / View port-forward processes"
echo "   ps aux | grep port-forward"
echo ""
echo "   # 停止所有 port-forward / Stop all port-forward"
echo "   pkill -f 'port-forward.*frontend-service'"
echo ""
echo "   # 查看日志 / View logs"
echo "   tail -f /tmp/k8s-port-forward-*.log"
echo ""
print_info "✨ 祝使用愉快！/ Enjoy!"
