# Vue3 + Nginx 配置说明

## 为什么需要特殊配置？

Vue Router 在使用 **History 模式**时，所有路由都是在前端处理的。但是当用户直接访问或刷新页面时（如 `http://login.local/register`），Nginx 会尝试查找 `/register` 文件，这会导致 404 错误。

因此，需要配置 Nginx 将所有请求都重定向到 `index.html`，让 Vue Router 来处理路由。

---

## Nginx 配置示例

```nginx
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip 压缩配置
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript 
               application/x-javascript application/xml+rss 
               application/javascript application/json;

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # API 反向代理到后端
    location /api/ {
        proxy_pass http://backend-service:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS 设置（如果后端没有处理）
        # add_header Access-Control-Allow-Origin *;
        # add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS';
        # add_header Access-Control-Allow-Headers 'Content-Type, Authorization';
    }

    # Vue Router History 模式配置
    # 所有非文件请求都返回 index.html
    location / {
        try_files $uri $uri/ /index.html;
    }

    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
    }
}
```

---

## 关键配置说明

### 1. SPA 路由支持
```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```
- 首先尝试查找文件 `$uri`
- 如果不存在，尝试查找目录 `$uri/`
- 都不存在则返回 `index.html`，让 Vue Router 处理

### 2. API 反向代理
```nginx
location /api/ {
    proxy_pass http://backend-service:8000;
    ...
}
```
- 将 `/api/` 开头的请求代理到 Django 后端
- 在 K8s 环境中使用 Service 名称 `backend-service`

### 3. 静态资源缓存
```nginx
location ~* \.(js|css|png|jpg|...)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```
- 对静态资源设置长时间缓存
- 提高加载性能

### 4. Gzip 压缩
```nginx
gzip on;
gzip_types text/plain text/css application/javascript ...;
```
- 启用压缩，减少传输大小
- 提高加载速度

---

## Vite 配置（开发环境）

在本地开发时，Vite 有自己的开发服务器。`vite.config.js` 配置：

```javascript
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  
  // 开发服务器配置
  server: {
    port: 5173,
    host: '0.0.0.0', // 允许外部访问
    
    // API 代理配置（开发环境）
    proxy: {
      '/api': {
        target: 'http://localhost:8000', // Django 后端地址
        changeOrigin: true,
        // rewrite: (path) => path.replace(/^\/api/, '') // 如果需要重写路径
      }
    }
  },
  
  // 构建配置
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: false,
    
    // 分包策略
    rollupOptions: {
      output: {
        manualChunks: {
          'vue-vendor': ['vue', 'vue-router'],
          'axios-vendor': ['axios']
        }
      }
    }
  }
})
```

---

## Vue Router 配置

```javascript
import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  // 使用 History 模式（需要 Nginx 配置支持）
  history: createWebHistory(import.meta.env.BASE_URL),
  
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/Login.vue')
    },
    {
      path: '/register',
      name: 'register',
      component: () => import('../views/Register.vue')
    },
    {
      path: '/',
      name: 'home',
      component: () => import('../views/Home.vue'),
      meta: { requiresAuth: true } // 需要认证
    }
  ]
})

// 路由守卫
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('access_token')
  
  if (to.meta.requiresAuth && !token) {
    // 需要认证但没有 token，跳转到登录页
    next({ name: 'login' })
  } else if (to.name === 'login' && token) {
    // 已登录用户访问登录页，跳转到首页
    next({ name: 'home' })
  } else {
    next()
  }
})

export default router
```

---

## Axios 配置（带 Token 拦截器）

```javascript
import axios from 'axios'
import router from '../router'

const request = axios.create({
  baseURL: '/api', // 所有请求都加上 /api 前缀
  timeout: 10000
})

// 请求拦截器：自动添加 Token
request.interceptors.request.use(
  config => {
    const token = localStorage.getItem('access_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  error => {
    return Promise.reject(error)
  }
)

// 响应拦截器：统一错误处理
request.interceptors.response.use(
  response => {
    return response.data
  },
  async error => {
    if (error.response) {
      switch (error.response.status) {
        case 401:
          // Token 过期或无效
          localStorage.removeItem('access_token')
          localStorage.removeItem('refresh_token')
          router.push('/login')
          break
        case 403:
          console.error('没有权限')
          break
        case 404:
          console.error('请求的资源不存在')
          break
        case 500:
          console.error('服务器错误')
          break
        default:
          console.error('请求失败：', error.message)
      }
    }
    return Promise.reject(error)
  }
)

export default request
```

---

## 多阶段 Dockerfile

```dockerfile
# ============ 阶段 1：构建阶段 ============
FROM node:18-alpine AS builder

WORKDIR /app

# 复制依赖文件
COPY package*.json ./

# 安装依赖
RUN npm ci --only=production

# 复制源代码
COPY . .

# 构建 Vue 应用
RUN npm run build

# ============ 阶段 2：运行阶段 ============
FROM nginx:alpine

# 复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 复制 Nginx 配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 暴露端口
EXPOSE 80

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
```

---

## 环境变量配置

### 开发环境（.env.development）
```bash
VITE_API_BASE_URL=http://localhost:8000/api
VITE_APP_TITLE=登录系统（开发）
```

### 生产环境（.env.production）
```bash
VITE_API_BASE_URL=/api
VITE_APP_TITLE=登录系统
```

在代码中使用：
```javascript
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL
```

---

## 本地开发 vs K8s 部署

| 方面 | 本地开发 | K8s 部署 |
|-----|---------|---------|
| 前端服务器 | Vite Dev Server (5173) | Nginx (80) |
| 后端地址 | localhost:8000 | backend-service:8000 |
| API 代理 | Vite proxy | Nginx proxy_pass |
| 热更新 | ✅ 支持 | ❌ 需重新构建 |
| 构建 | 不需要 | 需要（npm run build） |
| 路由模式 | History | History + Nginx 配置 |

---

## 常见问题

### 1. 刷新页面出现 404
**原因**：Nginx 没有配置 SPA 路由支持  
**解决**：添加 `try_files $uri $uri/ /index.html;`

### 2. API 请求 CORS 错误
**原因**：跨域配置问题  
**解决**：
- 方案 1：在 Django 中配置 CORS（推荐）
- 方案 2：在 Nginx 中添加 CORS 头

### 3. 静态资源 404
**原因**：Vite 构建后的路径问题  
**解决**：检查 `vite.config.js` 中的 `base` 配置

### 4. Token 未自动添加到请求
**原因**：Axios 拦截器未生效  
**解决**：确保使用封装后的 axios 实例，而非原生 axios

---

## 推荐的目录结构

```
frontend/
├── public/              # 静态资源（不会被 Vite 处理）
│   └── favicon.ico
├── src/
│   ├── main.js         # 入口文件
│   ├── App.vue         # 根组件
│   ├── router/         # 路由配置
│   ├── views/          # 页面组件
│   ├── components/     # 可复用组件
│   ├── api/            # API 接口
│   ├── utils/          # 工具函数
│   ├── composables/    # 组合式函数
│   └── assets/         # 资源文件（会被 Vite 处理）
├── .env.development    # 开发环境变量
├── .env.production     # 生产环境变量
├── vite.config.js      # Vite 配置
├── package.json        # 项目配置
├── Dockerfile          # Docker 配置
└── nginx.conf          # Nginx 配置
```

---

## 参考资源

- [Vue3 官方文档](https://cn.vuejs.org/)
- [Vue Router 官方文档](https://router.vuejs.org/zh/)
- [Vite 官方文档](https://cn.vitejs.dev/)
- [Nginx 配置参考](https://nginx.org/en/docs/)

