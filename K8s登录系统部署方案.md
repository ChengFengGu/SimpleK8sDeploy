# Kubernetes 登录系统部署方案

## 一、Kubernetes 简介

### 1.1 什么是 Kubernetes（K8s）？

Kubernetes（简称 K8s）是一个开源的容器编排平台，最初由 Google 设计，现在由云原生计算基金会（CNCF）维护。它能够自动化容器化应用程序的部署、扩展和管理。

### 1.2 K8s 的核心优势

- **自动化部署和回滚**：自动部署应用，如果出现问题可以快速回滚
- **服务发现和负载均衡**：自动分配 IP 地址和 DNS 名称，并在多个容器间进行负载均衡
- **存储编排**：自动挂载存储系统（本地存储、公有云存储等）
- **自我修复**：自动重启失败的容器，替换和重新调度不健康的节点
- **水平扩展**：通过简单的命令或 UI，或者根据 CPU 使用率自动扩展应用
- **密钥和配置管理**：安全地存储和管理敏感信息

### 1.3 K8s 核心概念

- **Pod**：K8s 最小的部署单元，包含一个或多个容器
- **Deployment**：管理 Pod 的副本数量和更新策略
- **Service**：为 Pod 提供稳定的网络访问入口
- **ConfigMap**：存储非敏感的配置信息
- **Secret**：存储敏感信息（如密码、密钥）
- **Namespace**：用于隔离不同的资源
- **Ingress**：管理外部访问集群内服务的规则

---

## 二、项目架构设计

### 2.1 系统概述

我们将构建一个经典的三层架构登录系统：

```
┌─────────────────────────────────────────────────────────┐
│                    外部用户访问                          │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
            ┌────────────────┐
            │  Ingress/负载均衡 │
            └────────┬───────┘
                     │
         ┌───────────┴───────────┐
         │                       │
         ▼                       ▼
┌─────────────────┐     ┌─────────────────┐
│   前端容器       │     │   后端容器       │
│   (Nginx)       │────▶│   (Node.js/     │
│   - HTML/CSS/JS │     │    Python/Go)   │
│   - 登录页面     │     │   - API 接口     │
└─────────────────┘     └────────┬────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │   数据库容器     │
                        │   (MySQL/       │
                        │    PostgreSQL)  │
                        │   - 用户表       │
                        └─────────────────┘
```

### 2.2 技术栈选择

#### 前端
- **框架**：React / Vue.js（静态文件）
- **Web 服务器**：Nginx
- **容器**：基于 `nginx:alpine` 镜像

#### 后端
- **语言**：Node.js (Express) 
- **功能**：
  - 用户登录 API
  - JWT Token 生成和验证
  - 密码加密（bcrypt）
- **容器**：基于 `node:18-alpine` 镜像

#### 数据库
- **数据库**：PostgreSQL
- **数据结构**：用户表（users）
  - id（主键）
  - username（用户名）
  - password（加密后的密码）
  - email（邮箱）
  - created_at（创建时间）
- **容器**：基于 `postgres:15-alpine` 镜像

---

## 三、Docker 容器化方案

### 3.1 前端 Docker 镜像

**目录结构**：
```
frontend/
├── Dockerfile
├── nginx.conf
└── src/
    ├── index.html
    ├── login.html
    ├── css/
    │   └── style.css
    └── js/
        └── app.js
```

**Dockerfile 说明**：
- 使用 Nginx 作为 Web 服务器
- 将静态文件复制到容器中
- 配置反向代理到后端服务
- 暴露 80 端口

### 3.2 后端 Docker 镜像

**目录结构**：
```
backend/
├── Dockerfile
├── package.json
└── src/
    ├── server.js
    ├── routes/
    │   └── auth.js
    ├── models/
    │   └── user.js
    └── middleware/
        └── auth.js
```

**Dockerfile 说明**：
- 基于 Node.js 18
- 安装依赖包（express, pg, bcrypt, jsonwebtoken）
- 复制应用代码
- 暴露 3000 端口
- 启动 Express 服务器

### 3.3 数据库 Docker 镜像

**配置**：
- 使用官方 PostgreSQL 镜像
- 通过环境变量配置数据库名、用户名和密码
- 持久化数据卷
- 初始化 SQL 脚本创建用户表

---

## 四、Kubernetes 部署方案

### 4.1 命名空间（Namespace）

创建独立的命名空间 `login-system`，用于隔离登录系统的所有资源。

### 4.2 数据库层（PostgreSQL）

**资源清单**：

1. **Secret**：存储数据库密码
   - `postgres-secret.yaml`
   - 包含：POSTGRES_PASSWORD

2. **ConfigMap**：存储数据库配置
   - `postgres-configmap.yaml`
   - 包含：数据库名、用户名、初始化脚本

3. **PersistentVolume & PersistentVolumeClaim**：持久化存储
   - `postgres-pv.yaml`
   - `postgres-pvc.yaml`
   - 确保数据不会因 Pod 重启而丢失

4. **Deployment**：部署数据库
   - `postgres-deployment.yaml`
   - 1 个副本（单实例）
   - 挂载持久化卷
   - 注入 Secret 和 ConfigMap

5. **Service**：内部服务发现
   - `postgres-service.yaml`
   - ClusterIP 类型（仅集群内部访问）
   - 端口：5432

### 4.3 后端层（Node.js API）

**资源清单**：

1. **Secret**：存储 JWT 密钥和数据库连接信息
   - `backend-secret.yaml`

2. **ConfigMap**：存储应用配置
   - `backend-configmap.yaml`
   - 数据库主机地址、端口等

3. **Deployment**：部署后端服务
   - `backend-deployment.yaml`
   - 3 个副本（高可用）
   - 健康检查（liveness 和 readiness probes）
   - 资源限制（CPU 和内存）

4. **Service**：后端服务入口
   - `backend-service.yaml`
   - ClusterIP 类型
   - 端口：3000

### 4.4 前端层（Nginx）

**资源清单**：

1. **ConfigMap**：Nginx 配置文件
   - `frontend-configmap.yaml`
   - 反向代理配置，将 `/api` 请求转发到后端服务

2. **Deployment**：部署前端服务
   - `frontend-deployment.yaml`
   - 2 个副本
   - 挂载 ConfigMap 作为 Nginx 配置

3. **Service**：前端服务入口
   - `frontend-service.yaml`
   - NodePort 或 LoadBalancer 类型
   - 端口：80

### 4.5 Ingress（可选）

**资源清单**：

- **Ingress**：统一入口和路由规则
  - `ingress.yaml`
  - 配置域名路由
  - TLS/SSL 证书配置
  - 路径路由（/ 指向前端，/api 指向后端）

### 4.6 部署顺序

```
1. 创建 Namespace
   ↓
2. 部署数据库层
   - Secret
   - ConfigMap
   - PV/PVC
   - Deployment
   - Service
   ↓
3. 等待数据库就绪
   ↓
4. 部署后端层
   - Secret
   - ConfigMap
   - Deployment
   - Service
   ↓
5. 部署前端层
   - ConfigMap
   - Deployment
   - Service
   ↓
6. 配置 Ingress（可选）
```

---

## 五、功能特性

### 5.1 登录页面功能

1. **用户注册**
   - 输入用户名、邮箱、密码
   - 前端验证（格式检查）
   - 后端密码加密存储

2. **用户登录**
   - 输入用户名和密码
   - 后端验证凭据
   - 返回 JWT Token
   - 前端存储 Token 到 localStorage

3. **Token 验证**
   - 受保护的页面需要 Token
   - 后端中间件验证 Token
   - Token 过期自动跳转登录页

### 5.2 K8s 特性应用

1. **高可用性**
   - 前端和后端多副本部署
   - Pod 自动重启和替换
   - 滚动更新零停机

2. **负载均衡**
   - Service 自动负载均衡
   - 请求分发到多个 Pod

3. **配置管理**
   - ConfigMap 管理非敏感配置
   - Secret 管理密码和密钥
   - 配置与代码分离

4. **健康检查**
   - Liveness Probe：检测容器是否存活
   - Readiness Probe：检测容器是否准备好接收流量

5. **资源管理**
   - CPU 和内存限制
   - 防止资源耗尽
   - 优化集群利用率

---

## 六、网络通信流程

### 6.1 用户登录流程

```
1. 用户在浏览器访问：http://your-domain.com/login
   ↓
2. Ingress 路由到前端 Service
   ↓
3. 前端 Service 将请求转发到 Nginx Pod
   ↓
4. Nginx 返回 login.html 页面
   ↓
5. 用户输入用户名和密码，点击登录
   ↓
6. 前端 JS 发送 POST 请求到 /api/login
   ↓
7. Ingress 将 /api 请求路由到后端 Service
   ↓
8. 后端 Service 将请求转发到 Node.js Pod
   ↓
9. Node.js 查询 PostgreSQL Service
   ↓
10. PostgreSQL Service 转发到数据库 Pod
   ↓
11. 验证用户名和密码
   ↓
12. 返回结果：成功生成 JWT Token，失败返回错误
   ↓
13. 前端接收响应，存储 Token 或显示错误
```

### 6.2 Service 发现机制

K8s 内部通过 DNS 自动服务发现：
- 前端访问后端：`http://backend-service:3000`
- 后端访问数据库：`postgresql://postgres-service:5432/logindb`

---

## 七、安全考虑

### 7.1 密码安全
- 使用 bcrypt 加密密码（不存储明文）
- 密码强度验证

### 7.2 Token 安全
- JWT Token 包含过期时间
- 签名验证防止篡改
- HTTPS 传输（生产环境）

### 7.3 K8s 安全
- Secret 加密存储敏感信息
- RBAC（基于角色的访问控制）
- Network Policy 限制 Pod 间通信
- 镜像安全扫描

### 7.4 数据库安全
- 数据库仅在集群内部访问（ClusterIP）
- 强密码策略
- 定期备份

---

## 八、监控和日志

### 8.1 日志收集
- 使用 EFK 堆栈（Elasticsearch + Fluentd + Kibana）
- 或使用 Loki + Grafana
- 集中收集所有 Pod 的日志

### 8.2 监控指标
- 使用 Prometheus + Grafana
- 监控指标：
  - Pod CPU/内存使用率
  - 请求数量和响应时间
  - 数据库连接数
  - 错误率

### 8.3 告警
- 设置告警规则：
  - Pod 重启次数过多
  - 资源使用率过高
  - 服务不可用

---

## 九、扩展和优化

### 9.1 水平扩展
```bash
# 手动扩展后端副本到 5 个
kubectl scale deployment backend-deployment -n login-system --replicas=5

# 自动扩展（HPA）
kubectl autoscale deployment backend-deployment \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n login-system
```

### 9.2 滚动更新
- 更新镜像版本后自动滚动更新
- 设置更新策略（maxSurge, maxUnavailable）
- 支持回滚到上一个版本

### 9.3 数据库优化
- 使用 StatefulSet 部署数据库（保证有序性）
- 主从复制（读写分离）
- 连接池优化

### 9.4 缓存层
- 添加 Redis 缓存
- 缓存 Token 验证结果
- 缓存热点数据

---

## 十、开发和部署流程

### 10.1 本地开发
1. 使用 Docker Compose 本地测试
2. 开发完成后构建 Docker 镜像
3. 推送镜像到镜像仓库（Docker Hub / 私有仓库）

### 10.2 CI/CD 流程
1. 代码提交到 Git 仓库
2. CI 自动运行测试
3. 构建 Docker 镜像并打标签
4. 推送镜像到仓库
5. 自动部署到 K8s 集群（Staging 环境）
6. 测试通过后部署到生产环境

### 10.3 部署命令
```bash
# 创建命名空间
kubectl create namespace login-system

# 应用所有配置文件
kubectl apply -f k8s/ -n login-system

# 查看部署状态
kubectl get all -n login-system

# 查看日志
kubectl logs -f deployment/backend-deployment -n login-system

# 访问服务
kubectl port-forward service/frontend-service 8080:80 -n login-system
```

---

## 十一、文件结构概览

```
login-system/
├── frontend/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── src/
│       ├── index.html
│       ├── login.html
│       ├── register.html
│       ├── css/
│       │   └── style.css
│       └── js/
│           └── app.js
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   └── src/
│       ├── server.js
│       ├── config/
│       │   └── database.js
│       ├── routes/
│       │   └── auth.js
│       ├── models/
│       │   └── user.js
│       └── middleware/
│           └── auth.js
├── database/
│   └── init.sql
├── k8s/
│   ├── namespace.yaml
│   ├── postgres/
│   │   ├── postgres-secret.yaml
│   │   ├── postgres-configmap.yaml
│   │   ├── postgres-pv.yaml
│   │   ├── postgres-pvc.yaml
│   │   ├── postgres-deployment.yaml
│   │   └── postgres-service.yaml
│   ├── backend/
│   │   ├── backend-secret.yaml
│   │   ├── backend-configmap.yaml
│   │   ├── backend-deployment.yaml
│   │   └── backend-service.yaml
│   ├── frontend/
│   │   ├── frontend-configmap.yaml
│   │   ├── frontend-deployment.yaml
│   │   └── frontend-service.yaml
│   └── ingress.yaml
├── docker-compose.yml (本地开发用)
└── README.md
```

---

## 十二、预期结果

完成部署后，您将获得：

1. ✅ 一个完整的、容器化的登录系统
2. ✅ 前后端分离架构，可独立扩展
3. ✅ 通过 K8s 实现高可用和自动伸缩
4. ✅ 配置与代码分离，易于管理
5. ✅ 完整的健康检查和自愈能力
6. ✅ 可扩展的架构，便于后续添加功能
7. ✅ 生产级别的部署方案

---

## 十三、下一步行动

一旦您同意这个方案，我将开始：

1. **创建前端代码**
   - 精美的登录页面（HTML/CSS/JS）
   - 注册页面
   - 登录后的欢迎页面

2. **创建后端代码**
   - Express.js 服务器
   - 登录/注册 API
   - JWT Token 认证中间件

3. **创建 Dockerfile**
   - 前端 Dockerfile
   - 后端 Dockerfile
   - 数据库初始化脚本

4. **创建 K8s 配置文件**
   - 所有 YAML 配置文件
   - 按照上述架构组织

5. **提供部署脚本**
   - 一键部署脚本
   - 清理脚本
   - 测试脚本

6. **创建文档**
   - 详细的部署步骤
   - 故障排查指南
   - API 文档

---

## 十四、内网域名配置方案

### 14.1 为什么需要内网域名？

在内网环境中，使用域名而不是 IP 地址访问服务有以下优势：
- 更容易记忆和使用
- IP 地址变动时无需修改配置
- 支持基于域名的路由和 SSL 证书
- 更接近生产环境的使用体验

### 14.2 方案选择

我们提供三种方案，按复杂度和适用场景排序：

#### 方案一：修改本地 hosts 文件（最简单）

**适用场景**：个人开发、单机测试

**优点**：
- 配置简单快速
- 无需额外服务
- 立即生效

**缺点**：
- 每台机器都需要单独配置
- 不适合团队协作
- IP 变化需要手动更新

**实施步骤**：

1. 获取 Ingress 或 Service 的 IP 地址
```bash
# 如果使用 Ingress
kubectl get ingress -n login-system

# 如果使用 NodePort
kubectl get nodes -o wide

# 如果使用 LoadBalancer
kubectl get service frontend-service -n login-system
```

2. 编辑 hosts 文件

**Linux/macOS**：
```bash
sudo vim /etc/hosts

# 添加以下行（替换为实际 IP）
192.168.1.100  login.local
192.168.1.100  www.login.local
192.168.1.100  api.login.local
```

**Windows**：
```powershell
# 以管理员身份打开记事本
# 编辑文件：C:\Windows\System32\drivers\etc\hosts

# 添加以下行
192.168.1.100  login.local
192.168.1.100  www.login.local
192.168.1.100  api.login.local
```

3. 验证配置
```bash
ping login.local
curl http://login.local
```

#### 方案二：使用 CoreDNS 内网 DNS 服务器（推荐）

**适用场景**：团队开发、测试环境、小型内网

**优点**：
- 集中管理，配置一次全网可用
- 支持通配符域名
- 动态更新，无需重启客户端
- 与 K8s 集成良好

**缺点**：
- 需要搭建 DNS 服务器
- 客户端需要修改 DNS 配置

**实施步骤**：

1. **在 K8s 集群中部署 CoreDNS**

创建 CoreDNS 配置文件 `k8s/coredns/coredns-configmap.yaml`：
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  custom.server: |
    # 自定义域名配置
    login.local:53 {
        errors
        cache 30
        forward . 192.168.1.100  # Ingress 或 LoadBalancer IP
        log
    }
    
    # 支持通配符
    *.login.local:53 {
        errors
        cache 30
        forward . 192.168.1.100
        log
    }
  
  # 或者使用 hosts 插件
  custom.hosts: |
    192.168.1.100  login.local
    192.168.1.100  www.login.local
    192.168.1.100  api.login.local
    192.168.1.100  admin.login.local
```

2. **部署专用的 CoreDNS 服务**

创建 `k8s/coredns/coredns-deployment.yaml`：
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: internal-coredns
  namespace: login-system
spec:
  replicas: 2
  selector:
    matchLabels:
      app: internal-coredns
  template:
    metadata:
      labels:
        app: internal-coredns
    spec:
      containers:
      - name: coredns
        image: coredns/coredns:1.10.1
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
        volumeMounts:
        - name: config-volume
          mountPath: /etc/coredns
        args: [ "-conf", "/etc/coredns/Corefile" ]
      volumes:
      - name: config-volume
        configMap:
          name: coredns-config
          items:
          - key: Corefile
            path: Corefile
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-config
  namespace: login-system
data:
  Corefile: |
    .:53 {
        errors
        health
        ready
        
        # 自定义 hosts 文件
        hosts {
            192.168.1.100  login.local
            192.168.1.100  www.login.local
            192.168.1.100  api.login.local
            fallthrough
        }
        
        # 转发其他请求到上游 DNS
        forward . 8.8.8.8 8.8.4.4
        
        cache 30
        loop
        reload
        loadbalance
    }
```

3. **创建 Service**

创建 `k8s/coredns/coredns-service.yaml`：
```yaml
apiVersion: v1
kind: Service
metadata:
  name: internal-dns
  namespace: login-system
spec:
  selector:
    app: internal-coredns
  type: NodePort  # 或 LoadBalancer
  ports:
  - name: dns-udp
    port: 53
    targetPort: 53
    protocol: UDP
    nodePort: 30053  # 可自定义
  - name: dns-tcp
    port: 53
    targetPort: 53
    protocol: TCP
    nodePort: 30053
```

4. **部署 CoreDNS**
```bash
kubectl apply -f k8s/coredns/
kubectl get pods -n login-system -l app=internal-coredns
```

5. **获取 DNS 服务器 IP**
```bash
# 获取 NodePort 方式的 IP（使用任一节点 IP）
kubectl get nodes -o wide

# 或者 LoadBalancer 的 IP
kubectl get service internal-dns -n login-system
```

6. **配置客户端使用内网 DNS**

**Linux (Ubuntu/Debian)**：
```bash
# 方法1：修改 /etc/resolv.conf（重启后可能失效）
sudo vim /etc/resolv.conf
# 在最前面添加
nameserver 192.168.1.50  # DNS 服务器 IP

# 方法2：使用 systemd-resolved（持久化）
sudo vim /etc/systemd/resolved.conf
# 修改或添加
[Resolve]
DNS=192.168.1.50
FallbackDNS=8.8.8.8 8.8.4.4

sudo systemctl restart systemd-resolved

# 方法3：使用 NetworkManager
nmcli connection modify "连接名称" ipv4.dns "192.168.1.50"
nmcli connection up "连接名称"
```

**macOS**：
```bash
# 打开网络偏好设置
# 选择当前网络连接 -> 高级 -> DNS
# 添加 DNS 服务器：192.168.1.50

# 或使用命令行
networksetup -setdnsservers Wi-Fi 192.168.1.50 8.8.8.8
```

**Windows**：
```powershell
# 图形界面方式：
# 控制面板 -> 网络和共享中心 -> 更改适配器设置
# 右键网络连接 -> 属性 -> Internet 协议版本 4 (TCP/IPv4)
# 设置首选 DNS 服务器：192.168.1.50

# 命令行方式（管理员权限）：
netsh interface ip set dns "以太网" static 192.168.1.50 primary
netsh interface ip add dns "以太网" 8.8.8.8 index=2
```

7. **验证 DNS 解析**
```bash
# Linux/macOS
nslookup login.local
dig login.local

# Windows
nslookup login.local

# 测试访问
ping login.local
curl http://login.local
```

#### 方案三：使用 dnsmasq（轻量级方案）

**适用场景**：小型网络、路由器级别配置

**实施步骤**：

1. **在服务器上安装 dnsmasq**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install dnsmasq

# CentOS/RHEL
sudo yum install dnsmasq
```

2. **配置 dnsmasq**
```bash
sudo vim /etc/dnsmasq.conf

# 添加配置
# 监听接口
interface=eth0
bind-interfaces

# 设置 DNS 缓存大小
cache-size=1000

# 添加自定义域名解析
address=/login.local/192.168.1.100
address=/www.login.local/192.168.1.100
address=/api.login.local/192.168.1.100

# 通配符支持
address=/.login.local/192.168.1.100

# 上游 DNS 服务器
server=8.8.8.8
server=8.8.4.4
```

3. **创建 hosts 文件（可选）**
```bash
sudo vim /etc/dnsmasq.hosts

# 添加记录
192.168.1.100  login.local
192.168.1.100  www.login.local
192.168.1.100  api.login.local

# 在 dnsmasq.conf 中启用
# addn-hosts=/etc/dnsmasq.hosts
```

4. **启动服务**
```bash
sudo systemctl start dnsmasq
sudo systemctl enable dnsmasq
sudo systemctl status dnsmasq
```

5. **测试**
```bash
dig @localhost login.local
```

### 14.3 配置 Ingress 使用自定义域名

更新 `k8s/ingress.yaml`：

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: login-system-ingress
  namespace: login-system
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    # 如果有 SSL 证书
    # cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  rules:
  # 主域名 - 前端
  - host: login.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 3000
  
  # www 子域名 - 前端
  - host: www.login.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
  
  # API 子域名 - 后端
  - host: api.login.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 3000
  
  # tls:
  # - hosts:
  #   - login.local
  #   - www.login.local
  #   - api.login.local
  #   secretName: login-local-tls
```

### 14.4 生成自签名 SSL 证书（可选）

即使是内网域名，也可以配置 HTTPS：

```bash
# 创建证书目录
mkdir -p ssl

# 生成私钥
openssl genrsa -out ssl/login.local.key 2048

# 生成证书签名请求
openssl req -new -key ssl/login.local.key -out ssl/login.local.csr \
  -subj "/C=CN/ST=Beijing/L=Beijing/O=MyCompany/CN=login.local"

# 创建扩展配置文件（支持多域名）
cat > ssl/login.local.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = login.local
DNS.2 = www.login.local
DNS.3 = api.login.local
DNS.4 = *.login.local
EOF

# 生成自签名证书
openssl x509 -req -in ssl/login.local.csr \
  -signkey ssl/login.local.key \
  -out ssl/login.local.crt \
  -days 365 \
  -extfile ssl/login.local.ext

# 创建 K8s Secret
kubectl create secret tls login-local-tls \
  --cert=ssl/login.local.crt \
  --key=ssl/login.local.key \
  -n login-system

# 在 Ingress 中启用 TLS（取消注释 tls 部分）
```

### 14.5 域名方案对比

| 方案 | 复杂度 | 维护成本 | 适用规模 | 推荐指数 |
|------|--------|----------|----------|----------|
| 修改 hosts | 低 | 高（每台机器配置） | 1-3 台 | ⭐⭐ |
| CoreDNS | 中 | 低（集中管理） | 3-100+ 台 | ⭐⭐⭐⭐⭐ |
| dnsmasq | 低-中 | 中（单点配置） | 3-50 台 | ⭐⭐⭐⭐ |

### 14.6 推荐配置流程

**对于本项目，推荐使用以下配置**：

```bash
# 1. 使用简单易记的域名
login.local          # 主站（前端）
api.login.local      # API 接口（后端）

# 2. 如果团队使用，部署 CoreDNS
kubectl apply -f k8s/coredns/

# 3. 如果仅个人开发，修改 hosts 文件
sudo echo "192.168.1.100  login.local api.login.local" >> /etc/hosts

# 4. 配置 Ingress
kubectl apply -f k8s/ingress.yaml

# 5. 测试访问
curl http://login.local
curl http://api.login.local/health
```

### 14.7 常见问题和解决方案

#### 问题1：DNS 不生效
```bash
# 清除 DNS 缓存
# Linux
sudo systemd-resolve --flush-caches

# macOS
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Windows（管理员权限）
ipconfig /flushdns
```

#### 问题2：浏览器无法访问
- 检查防火墙是否允许 80/443 端口
- 确认 Ingress Controller 是否正常运行
- 使用 `curl -v` 查看详细错误信息

#### 问题3：部分机器可以访问，部分不行
- 确认 DNS 配置是否正确
- 检查网络连通性
- 查看 DNS 查询日志

```bash
# 查看 CoreDNS 日志
kubectl logs -f -n login-system -l app=internal-coredns
```

---

## 十五、需要的前置条件

开始部署前，请确保您已经：

- [ ] 安装了 Docker
- [ ] 安装了 Kubernetes（minikube / kind / k3s / 生产集群）
- [ ] 安装了 kubectl 命令行工具
- [ ] 有基本的 Docker 和 K8s 知识
- [ ] （可选）有镜像仓库账号（Docker Hub 等）
- [ ] 已规划好内网域名（如 login.local）
- [ ] 确定使用哪种 DNS 方案

---

**请您查看这个方案，如果同意，我将立即开始具体的代码编写和部署实施！** 🚀

