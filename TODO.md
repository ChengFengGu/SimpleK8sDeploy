# Kubernetes 登录系统部署 - 任务清单

> 📅 创建时间：2025-11-27  
> 🎯 目标：完成一个基于 K8s 的前后端分离登录系统

---

## 📋 任务概览

- [ ] **阶段一**：前端开发 - Vue3（11 个任务）
- [ ] **阶段二**：后端开发 - Django（8 个任务）
- [ ] **阶段三**：数据库配置（3 个任务）
- [ ] **阶段四**：Docker 镜像构建（3 个任务）
- [ ] **阶段五**：K8s 配置文件（15 个任务）
- [ ] **阶段六**：内网 DNS 配置（3 个任务）
- [ ] **阶段七**：部署脚本（5 个任务）
- [ ] **阶段八**：测试和验证（4 个任务）
- [ ] **阶段九**：文档完善（3 个任务）

**总计：55 个任务**

---

## 🎨 阶段一：前端开发（Vue3）

### 目录结构
```
frontend/
├── Dockerfile               # 多阶段构建
├── nginx.conf              # Nginx 配置
├── package.json            # 项目依赖
├── vite.config.js          # Vite 配置
├── index.html              # 入口 HTML
├── .env.production         # 生产环境变量
└── src/
    ├── main.js             # Vue 应用入口
    ├── App.vue             # 根组件
    ├── router/
    │   └── index.js        # Vue Router 配置
    ├── views/
    │   ├── Login.vue       # 登录页面
    │   ├── Register.vue    # 注册页面
    │   └── Home.vue        # 首页/欢迎页
    ├── components/
    │   ├── LoginForm.vue   # 登录表单组件
    │   └── Navbar.vue      # 导航栏组件
    ├── api/
    │   └── auth.js         # API 请求封装
    ├── utils/
    │   ├── request.js      # Axios 封装
    │   └── auth.js         # Token 管理
    └── assets/
        └── styles/
            └── main.css    # 全局样式
```

### 任务列表

- [ ] **1.1** 创建 `frontend/package.json` - Vue3 项目依赖
  - vue@3.x
  - vue-router@4.x（路由）
  - axios（HTTP 请求）
  - pinia（状态管理，可选）
  - vite（构建工具）
  - @vitejs/plugin-vue

- [ ] **1.2** 创建 `frontend/vite.config.js` - Vite 构建配置
  - Vue 插件配置
  - 代理配置（开发环境）
  - 构建优化

- [ ] **1.3** 创建 `frontend/src/main.js` 和 `App.vue` - Vue 应用入口
  - Vue 实例创建
  - Router 注册
  - 全局样式引入
  - 根组件配置

- [ ] **1.4** 创建 `frontend/src/router/index.js` - 路由配置
  - /login - 登录页面
  - /register - 注册页面
  - / - 首页（需要认证）
  - 路由守卫（Token 验证）

- [ ] **1.5** 创建 `frontend/src/views/Login.vue` - 登录页面组件
  - 响应式表单
  - 表单验证
  - 登录逻辑
  - 错误提示
  - 跳转注册

- [ ] **1.6** 创建 `frontend/src/views/Register.vue` - 注册页面组件
  - 注册表单
  - 密码确认验证
  - 注册逻辑
  - 跳转登录

- [ ] **1.7** 创建 `frontend/src/views/Home.vue` - 首页/欢迎页
  - 显示用户信息
  - 退出登录
  - 受保护的路由

- [ ] **1.8** 创建 `frontend/src/api/auth.js` - API 接口封装
  - login(credentials)
  - register(userData)
  - getProfile()
  - logout()

- [ ] **1.9** 创建 `frontend/src/utils/request.js` - Axios 配置
  - 请求拦截器（添加 Token）
  - 响应拦截器（错误处理）
  - 基础 URL 配置

- [ ] **1.10** 创建 `frontend/src/utils/auth.js` - Token 管理工具
  - setToken()
  - getToken()
  - removeToken()
  - isAuthenticated()

- [ ] **1.11** 创建 `frontend/src/assets/styles/main.css` - 全局样式
  - 现代化 UI 设计
  - 响应式布局
  - 动画效果
  - 主题色配置

---

## ⚙️ 阶段二：后端开发（Django）

### 目录结构
```
backend/
├── Dockerfile
├── requirements.txt         # Python 依赖
├── .dockerignore
├── manage.py                # Django 管理脚本
├── config/                  # 项目配置目录
│   ├── __init__.py
│   ├── settings.py          # Django 设置
│   ├── urls.py              # 主路由配置
│   └── wsgi.py              # WSGI 配置
└── apps/
    └── authentication/      # 认证应用
        ├── __init__.py
        ├── models.py        # 用户模型
        ├── serializers.py   # DRF 序列化器
        ├── views.py         # API 视图
        ├── urls.py          # 路由配置
        ├── middleware.py    # JWT 中间件
        └── tests.py         # 单元测试
```

### 任务列表

- [ ] **2.1** 创建 `backend/requirements.txt` - Python 依赖配置
  - Django>=4.2
  - djangorestframework（DRF）
  - djangorestframework-simplejwt（JWT 认证）
  - psycopg2-binary（PostgreSQL 驱动）
  - python-dotenv（环境变量）
  - django-cors-headers（跨域支持）
  - gunicorn（生产服务器）

- [ ] **2.2** 创建 Django 项目结构和 `config/settings.py`
  - 数据库配置（PostgreSQL）
  - REST Framework 配置
  - JWT 认证配置
  - CORS 配置
  - 环境变量集成

- [ ] **2.3** 创建 `apps/authentication/models.py` - 用户模型
  - 扩展 Django AbstractUser
  - 添加自定义字段
  - 邮箱唯一性验证
  - 时间戳字段

- [ ] **2.4** 创建 `apps/authentication/serializers.py` - 序列化器
  - UserSerializer（用户信息）
  - RegisterSerializer（注册）
  - LoginSerializer（登录）
  - 密码验证和加密

- [ ] **2.5** 创建 `apps/authentication/views.py` - API 视图
  - POST /api/register/ - 用户注册（ViewSet）
  - POST /api/login/ - 用户登录（获取 Token）
  - POST /api/token/refresh/ - 刷新 Token
  - GET /api/profile/ - 获取用户信息（需要认证）
  - POST /api/logout/ - 退出登录（Token 黑名单）
  - GET /api/health/ - 健康检查

- [ ] **2.6** 创建 `config/urls.py` 和 `apps/authentication/urls.py`
  - 主路由配置
  - API 路由注册
  - 版本控制（/api/v1/）

- [ ] **2.7** 创建 `apps/authentication/middleware.py` - JWT 中间件
  - Token 验证中间件
  - 异常处理
  - 日志记录

- [ ] **2.8** 创建 `manage.py` 和 WSGI 配置
  - Django 命令行工具
  - Gunicorn WSGI 配置
  - 静态文件配置

---

## 🗄️ 阶段三：数据库配置

### 目录结构
```
database/
├── init.sql                 # 初始化脚本
└── README.md                # 数据库说明
```

### 任务列表

- [ ] **3.1** 创建 `database/init.sql` - 数据库初始化脚本
  - 创建 users 表
  - 创建索引
  - 插入测试数据

- [ ] **3.2** 创建 `database/README.md` - 数据库文档
  - 表结构说明
  - 字段说明
  - 示例查询

- [ ] **3.3** 设计数据库表结构
  - id（UUID 主键）
  - username（唯一索引）
  - email（唯一索引）
  - password_hash
  - created_at
  - updated_at

---

## 🐳 阶段四：Docker 镜像构建

### 任务列表

- [ ] **4.1** 创建 `frontend/Dockerfile` - 前端镜像（多阶段构建）
  - 阶段 1：构建阶段（基于 node:18-alpine）
    - 安装依赖
    - 执行 npm run build
    - 生成 dist 目录
  - 阶段 2：运行阶段（基于 nginx:alpine）
    - 复制构建产物（dist/）
    - 复制 nginx 配置
    - 暴露 80 端口

- [ ] **4.2** 创建 `frontend/nginx.conf` - Nginx 配置
  - 静态文件服务
  - SPA 路由支持（history 模式）
  - API 反向代理（/api -> backend）
  - Gzip 压缩
  - 缓存策略

- [ ] **4.3** 创建 `backend/Dockerfile` - 后端镜像
  - 基于 python:3.11-alpine
  - 多阶段构建优化
  - 安装系统依赖（PostgreSQL 客户端）
  - 安装 Python 依赖
  - 暴露 8000 端口
  - 配置 Gunicorn
  - 健康检查

---

## ☸️ 阶段五：Kubernetes 配置文件

### 目录结构
```
k8s/
├── namespace.yaml
├── postgres/
│   ├── postgres-secret.yaml
│   ├── postgres-configmap.yaml
│   ├── postgres-pv.yaml
│   ├── postgres-pvc.yaml
│   ├── postgres-deployment.yaml
│   └── postgres-service.yaml
├── backend/
│   ├── backend-secret.yaml
│   ├── backend-configmap.yaml
│   ├── backend-deployment.yaml
│   └── backend-service.yaml
├── frontend/
│   ├── frontend-configmap.yaml
│   ├── frontend-deployment.yaml
│   └── frontend-service.yaml
├── coredns/
│   ├── coredns-configmap.yaml
│   ├── coredns-deployment.yaml
│   └── coredns-service.yaml
└── ingress.yaml
```

### 任务列表

#### 基础配置
- [ ] **5.1** 创建 `k8s/namespace.yaml` - 命名空间配置
  - 命名空间：login-system

#### 数据库层（PostgreSQL）
- [ ] **5.2** 创建 `k8s/postgres/postgres-secret.yaml` - 数据库密钥
  - POSTGRES_PASSWORD
  - POSTGRES_USER
  - base64 编码

- [ ] **5.3** 创建 `k8s/postgres/postgres-configmap.yaml` - 数据库配置
  - POSTGRES_DB
  - init.sql 初始化脚本

- [ ] **5.4** 创建 `k8s/postgres/postgres-pv.yaml` - 持久化卷
  - 存储类型：hostPath 或 nfs
  - 容量：10Gi

- [ ] **5.5** 创建 `k8s/postgres/postgres-pvc.yaml` - 持久化卷声明
  - 请求容量：5Gi

- [ ] **5.6** 创建 `k8s/postgres/postgres-deployment.yaml` - 数据库部署
  - 1 个副本
  - 挂载 PVC
  - 注入 Secret 和 ConfigMap
  - 健康检查

- [ ] **5.7** 创建 `k8s/postgres/postgres-service.yaml` - 数据库服务
  - ClusterIP 类型
  - 端口：5432

#### 后端层（Node.js）
- [ ] **5.8** 创建 `k8s/backend/backend-secret.yaml` - 后端密钥
  - JWT_SECRET
  - DB_PASSWORD

- [ ] **5.9** 创建 `k8s/backend/backend-configmap.yaml` - 后端配置
  - DB_HOST
  - DB_PORT
  - DB_NAME
  - DB_USER

- [ ] **5.10** 创建 `k8s/backend/backend-deployment.yaml` - 后端部署
  - 3 个副本
  - 资源限制
  - 健康检查（liveness & readiness）
  - 滚动更新策略

- [ ] **5.11** 创建 `k8s/backend/backend-service.yaml` - 后端服务
  - ClusterIP 类型
  - 端口：8000

#### 前端层（Nginx）
- [ ] **5.12** 创建 `k8s/frontend/frontend-configmap.yaml` - 前端配置
  - Nginx 配置文件
  - API 代理配置

- [ ] **5.13** 创建 `k8s/frontend/frontend-deployment.yaml` - 前端部署
  - 2 个副本
  - 挂载 ConfigMap
  - 资源限制

- [ ] **5.14** 创建 `k8s/frontend/frontend-service.yaml` - 前端服务
  - NodePort 类型
  - 端口：80 -> 30080

#### Ingress 配置
- [ ] **5.15** 创建 `k8s/ingress.yaml` - 入口控制器
  - 域名路由（login.local, api.login.local）
  - 路径路由
  - TLS 配置（可选）

---

## 🌐 阶段六：内网 DNS 配置

### 任务列表

- [ ] **6.1** 创建 `k8s/coredns/coredns-configmap.yaml` - CoreDNS 配置
  - 自定义域名解析
  - hosts 配置

- [ ] **6.2** 创建 `k8s/coredns/coredns-deployment.yaml` - CoreDNS 部署
  - 2 个副本
  - 挂载配置

- [ ] **6.3** 创建 `k8s/coredns/coredns-service.yaml` - DNS 服务
  - NodePort 类型
  - UDP/TCP 53 端口

---

## 🚀 阶段七：部署脚本

### 目录结构
```
scripts/
├── build-images.sh          # 构建 Docker 镜像
├── push-images.sh           # 推送镜像到仓库
├── deploy.sh                # 一键部署脚本
├── cleanup.sh               # 清理脚本
└── test.sh                  # 测试脚本
```

### 任务列表

- [ ] **7.1** 创建 `scripts/build-images.sh` - 构建镜像脚本
  - 构建前端镜像
  - 构建后端镜像
  - 打标签

- [ ] **7.2** 创建 `scripts/push-images.sh` - 推送镜像脚本
  - 登录 Docker Hub
  - 推送镜像

- [ ] **7.3** 创建 `scripts/deploy.sh` - 部署脚本
  - 创建命名空间
  - 按顺序部署所有资源
  - 等待 Pod 就绪
  - 显示访问信息

- [ ] **7.4** 创建 `scripts/cleanup.sh` - 清理脚本
  - 删除所有资源
  - 删除命名空间
  - 清理持久化卷

- [ ] **7.5** 创建 `scripts/test.sh` - 测试脚本
  - 健康检查
  - API 测试
  - 端到端测试

---

## 🧪 阶段八：测试和验证

### 任务列表

- [ ] **8.1** 本地 Docker 测试
  - 使用 docker-compose 测试三个容器
  - 验证容器间通信
  - 验证数据持久化

- [ ] **8.2** K8s 部署测试
  - 部署到集群
  - 验证所有 Pod 正常运行
  - 验证服务可访问

- [ ] **8.3** 功能测试
  - 用户注册功能
  - 用户登录功能
  - Token 验证功能
  - 退出登录功能

- [ ] **8.4** 压力测试（可选）
  - 并发登录测试
  - 负载均衡验证
  - 性能指标收集

---

## 📚 阶段九：文档完善

### 任务列表

- [ ] **9.1** 创建 `README.md` - 项目主文档
  - 项目介绍
  - 快速开始
  - 架构说明
  - API 文档

- [ ] **9.2** 创建 `DEPLOYMENT.md` - 详细部署指南
  - 前置条件
  - 分步部署教程
  - 故障排查
  - 常见问题

- [ ] **9.3** 创建 `docker-compose.yml` - 本地开发配置
  - 三个服务配置（frontend, backend, database）
  - 前端开发模式（volume 挂载 + HMR）
  - 网络配置
  - 卷挂载
  - 环境变量配置

---

## 📊 进度跟踪

### 完成统计
```
总任务数：55
已完成：0
进行中：0
待开始：55
完成率：0%
```

### 预计时间
- **阶段一**：2-3 小时（Vue3 + Vite 配置）
- **阶段二**：2-3 小时（Django + DRF）
- **阶段三**：30 分钟
- **阶段四**：30-45 分钟（多阶段构建）
- **阶段五**：2-3 小时
- **阶段六**：1 小时
- **阶段七**：1 小时
- **阶段八**：1-2 小时
- **阶段九**：1 小时

**总预计时间**：11-17 小时

---

## 🎯 里程碑

- [ ] **里程碑 1**：完成前端开发（阶段一）
- [ ] **里程碑 2**：完成后端开发（阶段二）
- [ ] **里程碑 3**：完成 Docker 镜像（阶段三 + 四）
- [ ] **里程碑 4**：完成 K8s 配置（阶段五 + 六）
- [ ] **里程碑 5**：完成部署脚本（阶段七）
- [ ] **里程碑 6**：通过所有测试（阶段八）
- [ ] **里程碑 7**：文档完善（阶段九）
- [ ] **里程碑 8**：🎉 项目完成！

---

## 📝 注意事项

### 开发规范
- [ ] 代码注释完整
- [ ] 错误处理完善
- [ ] 日志输出规范
- [ ] 遵循最佳实践

### Vue3 开发规范
- [ ] 使用 Composition API（`<script setup>`）
- [ ] 组件采用单文件组件（.vue）
- [ ] 使用 ref/reactive 管理响应式数据
- [ ] 合理拆分组件，提高复用性
- [ ] 使用 ESLint + Prettier 代码格式化

### 安全要点
- [ ] 密码使用 bcrypt 加密
- [ ] 使用 K8s Secret 存储敏感信息
- [ ] JWT Token 设置合理过期时间
- [ ] 输入验证和 SQL 注入防护

### 性能优化
- [ ] Docker 镜像尽量小（使用 alpine）
- [ ] 多阶段构建
- [ ] 合理设置资源限制
- [ ] 启用缓存机制

---

## 🔗 相关文档

- [x] [K8s登录系统部署方案.md](./K8s登录系统部署方案.md) - 总体方案文档
- [x] [VUE3_NGINX_CONFIG.md](./VUE3_NGINX_CONFIG.md) - Vue3 + Nginx 配置详解
- [ ] README.md - 项目主文档（待创建）
- [ ] DEPLOYMENT.md - 部署指南（待创建）
- [ ] API.md - API 文档（待创建）

---

## 📞 问题反馈

如果在实施过程中遇到问题，请：
1. 查看相关文档和注释
2. 检查日志输出
3. 查阅 K8s 官方文档
4. 进行问题排查

---

**✨ 准备好了吗？让我们开始实施这个项目吧！**

🚀 下一步：开始 **阶段一：前端开发**

