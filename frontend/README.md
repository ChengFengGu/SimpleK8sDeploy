# 前端应用 - Vue3 + Vite

基于 Vue3 + Vite 构建的登录系统前端应用。

## 技术栈

- **框架**: Vue 3 (Composition API)
- **构建工具**: Vite
- **路由**: Vue Router 4
- **HTTP客户端**: Axios
- **状态管理**: Pinia
- **Web服务器**: Nginx (生产环境)

## 项目结构

```
frontend/
├── public/              # 静态资源
├── src/
│   ├── api/            # API 接口
│   │   └── auth.js     # 认证相关接口
│   ├── assets/         # 资源文件
│   │   └── styles/     # 样式文件
│   │       └── main.css
│   ├── components/     # 可复用组件
│   ├── router/         # 路由配置
│   │   └── index.js    # 路由定义和守卫
│   ├── utils/          # 工具函数
│   │   ├── auth.js     # Token 管理
│   │   └── request.js  # Axios 封装
│   ├── views/          # 页面组件
│   │   ├── Login.vue   # 登录页面
│   │   ├── Register.vue # 注册页面
│   │   └── Home.vue    # 首页
│   ├── App.vue         # 根组件
│   └── main.js         # 入口文件
├── Dockerfile          # Docker 配置
├── nginx.conf          # Nginx 配置
├── vite.config.js      # Vite 配置
├── index.html          # HTML 入口
└── package.json        # 项目配置
```

## 快速开始

### 前置要求

- Node.js >= 18.x
- npm >= 9.x

### 安装依赖

```bash
npm install
```

### 启动开发服务器

```bash
npm run dev
```

访问: http://localhost:5173

开发服务器会自动代理 API 请求到后端（默认 http://localhost:8000）

### 构建生产版本

```bash
npm run build
```

构建产物将输出到 `dist/` 目录

### 预览生产版本

```bash
npm run preview
```

## Docker 部署

### 构建镜像

```bash
# 在 frontend 目录下执行
docker build -t login-frontend:latest .
```

该镜像使用多阶段构建：
1. 第一阶段：使用 Node.js 构建 Vue 应用
2. 第二阶段：使用 Nginx 服务静态文件

### 运行容器

```bash
docker run -d -p 8080:80 --name frontend login-frontend:latest
```

访问: http://localhost:8080

### 在 Kubernetes 中部署

前端服务会通过 K8s Service 和 Ingress 暴露，详见项目根目录的 K8s 配置文件。

## 功能特性

### ✅ 已实现功能

- **用户认证**
  - 用户登录
  - 用户注册
  - JWT Token 认证
  - 自动 Token 刷新（可扩展）

- **路由管理**
  - Vue Router History 模式
  - 路由守卫（认证拦截）
  - 自动跳转到登录页

- **HTTP 请求**
  - Axios 请求/响应拦截器
  - 自动添加 Authorization 头
  - 统一错误处理
  - 请求超时处理

- **用户体验**
  - 响应式设计
  - 现代化 UI
  - 加载状态提示
  - 表单验证
  - 错误提示
  - 路由过渡动画

## API 接口

### 基础 URL

- **开发环境**: `http://localhost:8000/api`
- **生产环境**: `/api` (通过 Nginx 反向代理到后端)

### 认证接口

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| POST | `/api/token/` | 用户登录，获取 Token | ❌ |
| POST | `/api/register/` | 用户注册 | ❌ |
| GET | `/api/profile/` | 获取用户信息 | ✅ |
| POST | `/api/token/refresh/` | 刷新 Token | ❌ |
| POST | `/api/logout/` | 退出登录 | ✅ |
| GET | `/api/health/` | 健康检查 | ❌ |

### 请求示例

#### 登录
```javascript
POST /api/token/
Content-Type: application/json

{
  "username": "user1",
  "password": "password123"
}

// 响应
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

#### 获取用户信息
```javascript
GET /api/profile/
Authorization: Bearer <access_token>

// 响应
{
  "id": 1,
  "username": "user1",
  "email": "user1@example.com",
  "created_at": "2025-11-27T10:00:00Z"
}
```

## 环境变量

### 开发环境 (.env.development)

```bash
VITE_API_URL=http://localhost:8000
VITE_APP_TITLE=登录系统（开发环境）
```

### 生产环境 (.env.production)

```bash
VITE_API_URL=/api
VITE_APP_TITLE=登录系统
```

在代码中使用：
```javascript
const apiUrl = import.meta.env.VITE_API_URL
```

## 路由配置

| 路径 | 名称 | 组件 | 认证要求 |
|------|------|------|----------|
| `/login` | Login | Login.vue | ❌ |
| `/register` | Register | Register.vue | ❌ |
| `/` | Home | Home.vue | ✅ |

### 路由守卫

- 访问需要认证的路由时，会自动检查 Token
- 未登录用户会被重定向到登录页
- 已登录用户访问登录/注册页会被重定向到首页

## Nginx 配置说明

### SPA 路由支持

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

所有非文件请求都返回 `index.html`，让 Vue Router 处理路由。

### API 反向代理

```nginx
location /api/ {
    proxy_pass http://backend-service:8000;
}
```

将 `/api/` 开头的请求代理到 Django 后端服务。

### 静态资源缓存

```nginx
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

静态资源设置长时间缓存，提高性能。

## 开发指南

### 目录规范

- `views/` - 页面级组件（对应路由）
- `components/` - 可复用的 UI 组件
- `api/` - API 接口封装
- `utils/` - 工具函数
- `router/` - 路由配置
- `assets/` - 静态资源（会被 Vite 处理）

### 代码规范

- 使用 Vue 3 Composition API (`<script setup>`)
- 使用 `ref` 和 `reactive` 管理响应式数据
- 组件命名使用 PascalCase
- 文件命名使用 kebab-case 或 PascalCase

### 添加新页面

1. 在 `src/views/` 创建组件文件
2. 在 `src/router/index.js` 添加路由配置
3. 如需认证，设置 `meta: { requiresAuth: true }`

### 添加新 API

在 `src/api/` 目录下创建或编辑接口文件：

```javascript
import request from '../utils/request'

export function yourApi(params) {
  return request({
    url: '/your-endpoint/',
    method: 'post',
    data: params
  })
}
```

## 浏览器支持

- Chrome >= 87
- Firefox >= 78
- Safari >= 14
- Edge >= 88

## 性能优化

- ✅ 使用 Vite 的快速 HMR
- ✅ 代码分割和懒加载
- ✅ 静态资源压缩（Gzip）
- ✅ 长期缓存策略
- ✅ Tree-shaking（移除未使用代码）
- ✅ 生产环境移除 console

## 常见问题

### 1. API 请求 CORS 错误

**原因**: 开发环境跨域问题

**解决**: 
- 检查 `vite.config.js` 中的 proxy 配置
- 确保后端配置了 CORS

### 2. 刷新页面 404

**原因**: 生产环境 Nginx 未配置 SPA 路由支持

**解决**: 
- 确保 `nginx.conf` 包含 `try_files $uri $uri/ /index.html;`

### 3. Token 自动失效

**原因**: Token 存储在 localStorage，可能被清除

**解决**:
- 实现 Token 刷新机制
- 或使用 HttpOnly Cookie（更安全）

### 4. 构建后静态资源 404

**原因**: 路径配置问题

**解决**:
- 检查 `vite.config.js` 中的 `base` 配置
- 确保 Nginx root 路径正确

## 项目依赖

### 生产依赖

```json
{
  "vue": "^3.3.11",
  "vue-router": "^4.2.5",
  "axios": "^1.6.2",
  "pinia": "^2.1.7"
}
```

### 开发依赖

```json
{
  "@vitejs/plugin-vue": "^4.5.2",
  "vite": "^5.0.8"
}
```

## 相关文档

- [Vue 3 官方文档](https://cn.vuejs.org/)
- [Vite 官方文档](https://cn.vitejs.dev/)
- [Vue Router 官方文档](https://router.vuejs.org/zh/)
- [Axios 文档](https://axios-http.com/zh/)

## 许可证

MIT

---

**开发者**: K8s Login System Team  
**更新时间**: 2025-11-27

