# Kubernetes 部署指南

## 📋 目录

1. [前置要求](#前置要求)
2. [部署架构](#部署架构)
3. [快速部署](#快速部署)
4. [手动部署](#手动部署)
5. [验证部署](#验证部署)
6. [访问应用](#访问应用)
7. [故障排查](#故障排查)
8. [清理资源](#清理资源)

---

## 🔧 前置要求

### 必需组件

- ✅ Kubernetes 集群 (v1.19+)
  - Minikube
  - Kind
  - K3s
  - 或云服务商的 K8s 集群
- ✅ kubectl 命令行工具
- ✅ Docker（用于构建镜像）

### 可选组件

- Ingress Controller (nginx-ingress)
- 持久化存储类 (StorageClass)

### 检查环境

```bash
# 检查 kubectl
kubectl version --client

# 检查集群连接
kubectl cluster-info

# 查看节点
kubectl get nodes

# 查看可用的 StorageClass
kubectl get storageclass
```

---

## 🏗️ 部署架构

```
┌────────────────────────────────────────────────────┐
│                  Ingress (可选)                     │
│            login.local / api.login.local            │
└───────────────────────┬────────────────────────────┘
                        │
         ┌──────────────┴──────────────┐
         │                             │
┌────────▼─────────┐         ┌────────▼─────────┐
│   Frontend       │         │   Backend        │
│  (Vue3 + Nginx)  │◀───────▶│  (Django + DRF)  │
│  Replicas: 2     │         │  Replicas: 3     │
│  Port: 80        │         │  Port: 8000      │
└──────────────────┘         └────────┬─────────┘
                                      │
                            ┌─────────▼──────────┐
                            │   PostgreSQL       │
                            │   Replicas: 1      │
                            │   Port: 5432       │
                            │   PV: 10Gi         │
                            └────────────────────┘
```

### K8s 资源清单

| 资源类型 | 名称 | 命名空间 | 说明 |
|---------|------|----------|------|
| Namespace | login-system | - | 资源隔离 |
| Secret | postgres-secret | login-system | 数据库密码 |
| Secret | backend-secret | login-system | Django 密钥 |
| ConfigMap | postgres-config | login-system | 数据库配置 |
| ConfigMap | backend-config | login-system | 后端配置 |
| ConfigMap | frontend-config | login-system | 前端Nginx配置 |
| PV | postgres-pv | - | 持久化卷 |
| PVC | postgres-pvc | login-system | 持久化声明 |
| Deployment | postgres-deployment | login-system | 数据库部署 |
| Deployment | backend-deployment | login-system | 后端部署 |
| Deployment | frontend-deployment | login-system | 前端部署 |
| Service | postgres-service | login-system | 数据库服务 |
| Service | backend-service | login-system | 后端服务 |
| Service | frontend-service | login-system | 前端服务 |
| Ingress | login-system-ingress | login-system | 入口路由 |

---

## 🚀 快速部署

### 步骤 1：构建 Docker 镜像

```bash
# 构建后端镜像
cd backend
docker build -t login-backend:latest .

# 构建前端镜像
cd ../frontend
docker build -t login-frontend:latest .

# 如果使用 Minikube，需要将镜像加载到 Minikube
minikube image load login-backend:latest
minikube image load login-frontend:latest
```

### 步骤 2：运行自动部署脚本

```bash
cd /root/learn/01-k8s
./scripts/deploy.sh
```

脚本会自动按顺序部署：
1. 创建命名空间
2. 部署 PostgreSQL
3. 部署 Backend
4. 部署 Frontend
5. (可选) 部署 Ingress

---

## 📝 手动部署

### 步骤 1：创建命名空间

```bash
kubectl apply -f k8s/namespace.yaml
```

### 步骤 2：部署 PostgreSQL

```bash
# 创建 Secret
kubectl apply -f k8s/postgres/postgres-secret.yaml

# 创建 ConfigMap
kubectl apply -f k8s/postgres/postgres-configmap.yaml

# 创建 PV 和 PVC
kubectl apply -f k8s/postgres/postgres-pv.yaml
kubectl apply -f k8s/postgres/postgres-pvc.yaml

# 创建 Deployment
kubectl apply -f k8s/postgres/postgres-deployment.yaml

# 创建 Service
kubectl apply -f k8s/postgres/postgres-service.yaml

# 等待 PostgreSQL 就绪
kubectl wait --for=condition=ready pod -l app=postgres -n login-system --timeout=120s
```

### 步骤 3：部署 Backend

```bash
# 创建 Secret
kubectl apply -f k8s/backend/backend-secret.yaml

# 创建 ConfigMap
kubectl apply -f k8s/backend/backend-configmap.yaml

# 创建 Deployment
kubectl apply -f k8s/backend/backend-deployment.yaml

# 创建 Service
kubectl apply -f k8s/backend/backend-service.yaml

# 等待 Backend 就绪
kubectl wait --for=condition=ready pod -l app=backend -n login-system --timeout=120s
```

### 步骤 4：部署 Frontend

```bash
# 创建 ConfigMap
kubectl apply -f k8s/frontend/frontend-configmap.yaml

# 创建 Deployment
kubectl apply -f k8s/frontend/frontend-deployment.yaml

# 创建 Service
kubectl apply -f k8s/frontend/frontend-service.yaml

# 等待 Frontend 就绪
kubectl wait --for=condition=ready pod -l app=frontend -n login-system --timeout=120s
```

### 步骤 5：(可选) 部署 Ingress

```bash
# 确保已安装 Ingress Controller
kubectl apply -f k8s/ingress.yaml
```

---

## ✅ 验证部署

### 查看所有资源

```bash
kubectl get all -n login-system
```

### 查看 Pod 状态

```bash
kubectl get pods -n login-system

# 预期输出:
# NAME                                    READY   STATUS    RESTARTS   AGE
# backend-deployment-xxx-xxx              1/1     Running   0          2m
# backend-deployment-xxx-yyy              1/1     Running   0          2m
# backend-deployment-xxx-zzz              1/1     Running   0          2m
# frontend-deployment-xxx-xxx             1/1     Running   0          1m
# frontend-deployment-xxx-yyy             1/1     Running   0          1m
# postgres-deployment-xxx-xxx             1/1     Running   0          3m
```

### 查看 Service

```bash
kubectl get svc -n login-system

# 预期输出:
# NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
# backend-service    ClusterIP   10.96.x.x       <none>        8000/TCP       2m
# frontend-service   NodePort    10.96.x.x       <none>        80:30080/TCP   1m
# postgres-service   ClusterIP   10.96.x.x       <none>        5432/TCP       3m
```

### 查看持久化卷

```bash
kubectl get pv,pvc -n login-system
```

### 查看日志

```bash
# PostgreSQL 日志
kubectl logs -f deployment/postgres-deployment -n login-system

# Backend 日志
kubectl logs -f deployment/backend-deployment -n login-system

# Frontend 日志
kubectl logs -f deployment/frontend-deployment -n login-system
```

---

## 🌐 访问应用

### 方法 1：NodePort 访问

```bash
# 获取 NodePort 端口
kubectl get svc frontend-service -n login-system

# 获取节点 IP
kubectl get nodes -o wide

# 访问
# http://<NODE_IP>:30080
```

### 方法 2：Port Forward

```bash
# 转发到本地端口
kubectl port-forward service/frontend-service 8080:80 -n login-system

# 访问
# http://localhost:8080
```

### 方法 3：使用 Ingress（需要配置 hosts）

```bash
# 获取 Ingress IP
kubectl get ingress -n login-system

# 添加到 hosts 文件
# Linux/Mac
echo "<INGRESS_IP> login.local www.login.local api.login.local" | sudo tee -a /etc/hosts

# Windows (管理员权限)
# echo <INGRESS_IP> login.local www.login.local api.login.local >> C:\Windows\System32\drivers\etc\hosts

# 访问
# http://login.local
```

---

## 🔍 故障排查

### Pod 无法启动

```bash
# 查看 Pod 详细信息
kubectl describe pod <pod-name> -n login-system

# 查看 Pod 日志
kubectl logs <pod-name> -n login-system

# 查看 Pod 事件
kubectl get events -n login-system --sort-by='.lastTimestamp'
```

### 数据库连接失败

```bash
# 检查 PostgreSQL Pod 是否运行
kubectl get pods -l app=postgres -n login-system

# 进入 PostgreSQL Pod
kubectl exec -it deployment/postgres-deployment -n login-system -- psql -U postgres -d logindb

# 测试 DNS 解析
kubectl run -it --rm debug --image=busybox --restart=Never -n login-system -- nslookup postgres-service
```

### Backend 无法访问数据库

```bash
# 查看 Backend 环境变量
kubectl exec deployment/backend-deployment -n login-system -- env | grep DB

# 进入 Backend Pod
kubectl exec -it deployment/backend-deployment -n login-system -- sh

# 测试数据库连接
nc -zv postgres-service 5432
```

### 镜像拉取失败

```bash
# 如果使用本地镜像，确保设置 imagePullPolicy: IfNotPresent
# 或者将镜像推送到镜像仓库

# Minikube 用户
minikube image load login-backend:latest
minikube image load login-frontend:latest
```

### PV 无法绑定

```bash
# 查看 PV/PVC 状态
kubectl get pv,pvc -n login-system

# 查看详细信息
kubectl describe pv postgres-pv
kubectl describe pvc postgres-pvc -n login-system

# 确保目录存在
# 对于 hostPath类型的 PV
sudo mkdir -p /mnt/data/postgres
sudo chmod 777 /mnt/data/postgres
```

---

## 🧪 测试部署

### 测试 API 接口

```bash
# 使用 port-forward
kubectl port-forward service/backend-service 8000:8000 -n login-system &

# 测试健康检查
curl http://localhost:8000/api/health/

# 测试注册
curl -X POST http://localhost:8000/api/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "test123456",
    "password2": "test123456"
  }'

# 测试登录
curl -X POST http://localhost:8000/api/token/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "test123456"
  }'
```

### 测试前端

```bash
# 使用 port-forward
kubectl port-forward service/frontend-service 8080:80 -n login-system &

# 访问浏览器
# http://localhost:8080
```

---

## 🔄 更新部署

### 更新镜像

```bash
# 重新构建镜像
docker build -t login-backend:v2 ./backend

# 更新 Deployment 中的镜像
kubectl set image deployment/backend-deployment backend=login-backend:v2 -n login-system

# 查看滚动更新状态
kubectl rollout status deployment/backend-deployment -n login-system
```

### 回滚部署

```bash
# 查看部署历史
kubectl rollout history deployment/backend-deployment -n login-system

# 回滚到上一个版本
kubectl rollout undo deployment/backend-deployment -n login-system

# 回滚到特定版本
kubectl rollout undo deployment/backend-deployment --to-revision=2 -n login-system
```

### 更新配置

```bash
# 修改 ConfigMap
kubectl edit configmap backend-config -n login-system

# 重启 Pod 使配置生效
kubectl rollout restart deployment/backend-deployment -n login-system
```

---

## 🗑️ 清理资源

### 使用清理脚本

```bash
./scripts/cleanup.sh
```

### 手动清理

```bash
# 删除所有资源（保留 PV）
kubectl delete namespace login-system

# 删除 PV
kubectl delete pv postgres-pv

# 清理本地数据
sudo rm -rf /mnt/data/postgres
```

---

## 📊 扩缩容

### 手动扩缩容

```bash
# 扩展后端副本到 5 个
kubectl scale deployment backend-deployment --replicas=5 -n login-system

# 扩展前端副本到 3 个
kubectl scale deployment frontend-deployment --replicas=3 -n login-system
```

### 自动扩缩容 (HPA)

```bash
# 基于 CPU 使用率自动扩缩容
kubectl autoscale deployment backend-deployment \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n login-system

# 查看 HPA 状态
kubectl get hpa -n login-system
```

---

## 🔐 安全建议

### 生产环境清单

- [ ] 修改所有默认密码
- [ ] 使用 Secret 存储敏感信息
- [ ] 启用 RBAC
- [ ] 配置 Network Policy
- [ ] 使用私有镜像仓库
- [ ] 配置资源限制和请求
- [ ] 启用 Pod Security Policy
- [ ] 配置备份策略
- [ ] 启用 TLS/SSL
- [ ] 定期更新镜像

---

## 📚 参考资源

- [Kubernetes 官方文档](https://kubernetes.io/docs/)
- [kubectl 命令参考](https://kubernetes.io/docs/reference/kubectl/)
- [Kubernetes 最佳实践](https://kubernetes.io/docs/concepts/configuration/overview/)

---

**部署愉快！** 🎉

