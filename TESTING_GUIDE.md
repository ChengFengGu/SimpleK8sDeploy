# 前后端联调测试指南

## 🚀 服务状态

### ✅ 后端服务（Django + DRF）
- **状态**: 运行中
- **端口**: 8001
- **地址**: http://localhost:8001
- **数据库**: SQLite (db.sqlite3)

### ✅ 前端服务（Vue3 + Vite）
- **状态**: 运行中  
- **端口**: 5173
- **地址**: http://localhost:5173
- **API 代理**: `/api` → `http://localhost:8001`

---

## 📊 API 代理验证

### 1. 通过前端代理访问后端 API

```bash
# 健康检查
curl http://localhost:5173/api/health/

# API 根路径
curl http://localhost:5173/api/

# 响应示例：
{
  "status": "healthy",
  "service": "authentication-api",
  "version": "1.0.0"
}
```

### 2. 直接访问后端 API

```bash
# 健康检查
curl http://localhost:8001/api/health/

# API 根路径
curl http://localhost:8001/api/
```

---

## 🧪 功能测试流程

### 测试场景 1：用户注册

#### 通过浏览器测试
1. 打开浏览器访问：http://localhost:5173/register
2. 填写表单：
   - 用户名：`demo001`
   - 邮箱：`demo001@example.com`
   - 密码：`demo123456`
   - 确认密码：`demo123456`
3. 点击"注册"按钮
4. **预期结果**：显示"注册成功！3秒后跳转到登录页面..."

#### 通过 curl 测试
```bash
curl -X POST http://localhost:5173/api/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "demo001",
    "email": "demo001@example.com",
    "password": "demo123456",
    "password2": "demo123456"
  }'

# 预期响应：
{
  "message": "注册成功",
  "user": {
    "id": 2,
    "username": "demo001",
    "email": "demo001@example.com",
    "created_at": "2025-11-27 17:30:00"
  }
}
```

### 测试场景 2：用户登录

#### 通过浏览器测试
1. 访问：http://localhost:5173/login
2. 填写登录信息：
   - 用户名：`testuser`（或刚注册的用户）
   - 密码：`test123456`
3. 点击"登录"按钮
4. **预期结果**：跳转到首页 `/`，显示用户信息

#### 通过 curl 测试
```bash
curl -X POST http://localhost:5173/api/token/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "test123456"
  }'

# 预期响应：
{
  "refresh": "eyJhbGci...",
  "access": "eyJhbGci..."
}
```

### 测试场景 3：访问受保护的页面

#### 通过浏览器测试
1. 未登录状态访问：http://localhost:5173/
2. **预期结果**：自动跳转到登录页 `/login?redirect=/`
3. 登录后再访问首页
4. **预期结果**：显示用户信息、欢迎消息

#### 通过 curl 测试
```bash
# 先获取 Token
TOKEN=$(curl -X POST http://localhost:5173/api/token/ \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"test123456"}' \
  -s | python -c "import sys, json; print(json.load(sys.stdin)['access'])")

# 使用 Token 访问用户信息
curl http://localhost:5173/api/profile/ \
  -H "Authorization: Bearer $TOKEN"

# 预期响应：
{
  "id": 1,
  "username": "testuser",
  "email": "test@example.com",
  ...
}
```

### 测试场景 4：退出登录

#### 通过浏览器测试
1. 在首页点击"退出登录"按钮
2. **预期结果**：跳转到登录页，localStorage 中的 Token 被清除

---

## 🔍 浏览器开发者工具检查

### 1. Network 标签页检查
打开浏览器开发者工具（F12）→ Network 标签：

#### 注册请求
- **请求**: `POST http://localhost:5173/api/register/`
- **请求头**: `Content-Type: application/json`
- **请求体**: 用户注册信息
- **响应码**: `201 Created`
- **响应体**: 包含用户信息

#### 登录请求
- **请求**: `POST http://localhost:5173/api/token/`
- **请求体**: 用户名和密码
- **响应码**: `200 OK`
- **响应体**: 包含 access 和 refresh token

#### 获取用户信息
- **请求**: `GET http://localhost:5173/api/profile/`
- **请求头**: `Authorization: Bearer <token>`
- **响应码**: `200 OK`
- **响应体**: 用户详细信息

### 2. Console 标签页检查
查看控制台日志：

```
✅ Vue3 应用已启动
📦 环境: development
📄 路由跳转: /login -> /
⚠️ 需要登录，跳转到登录页
✅ 登录成功: {access: "...", refresh: "..."}
```

### 3. Application 标签页检查
检查 localStorage：

```
access_token: "eyJhbGci..."
refresh_token: "eyJhbGci..."
user_info: {"id":1,"username":"testuser",...}
```

---

## 🐛 常见问题排查

### 问题 1: 登录后仍然跳转到登录页

**可能原因**：
- Token 没有正确存储到 localStorage
- 路由守卫配置有问题

**排查步骤**：
1. 打开浏览器控制台，检查是否有错误
2. 查看 Application → Local Storage，确认 Token 是否存在
3. 检查 Network 标签，查看 `/api/token/` 请求是否成功

### 问题 2: API 请求返回 404

**可能原因**：
- 后端服务未启动
- API 路径错误
- Vite 代理配置问题

**排查步骤**：
```bash
# 检查后端服务
curl http://localhost:8001/api/health/

# 检查前端代理
curl http://localhost:5173/api/health/

# 查看 Vite 代理日志（终端）
```

### 问题 3: CORS 错误

**可能原因**：
- 后端 CORS 配置问题

**解决方案**：
后端已配置 CORS，应该不会出现此问题。如果出现，检查 `backend/config/settings.py` 中的 CORS 配置。

### 问题 4: 注册/登录失败

**可能原因**：
- 用户名或邮箱已存在
- 密码不符合要求（至少6位）
- 两次密码不一致

**排查步骤**：
1. 查看浏览器控制台的错误信息
2. 查看 Network 标签中的响应内容
3. 后端日志（Django 终端）

---

## 📝 测试清单

### 前端功能测试
- [ ] 访问首页自动跳转到登录页
- [ ] 注册页面表单验证正常
- [ ] 注册成功后跳转到登录页
- [ ] 登录表单验证正常
- [ ] 登录成功后跳转到首页
- [ ] 首页显示用户信息
- [ ] 退出登录后跳转到登录页
- [ ] 刷新页面后登录状态保持

### 后端 API 测试
- [ ] `/api/` 根路径返回正常
- [ ] `/api/health/` 健康检查正常
- [ ] `/api/register/` 用户注册正常
- [ ] `/api/token/` 登录获取 Token 正常
- [ ] `/api/token/refresh/` Token 刷新正常
- [ ] `/api/profile/` 获取用户信息正常（需认证）
- [ ] 无 Token 访问受保护接口返回 401
- [ ] 错误的 Token 返回 401

### 集成测试
- [ ] 前端可以通过代理访问后端 API
- [ ] 注册 → 登录 → 查看信息 → 退出 完整流程正常
- [ ] Token 自动添加到请求头
- [ ] 401 错误自动跳转登录页
- [ ] 路由守卫正常工作

---

## 🎯 性能检查

### 页面加载时间
- 首次加载：< 2秒
- 后续加载：< 500ms（缓存）

### API 响应时间
- 注册：< 200ms
- 登录：< 100ms
- 获取用户信息：< 50ms

### 网络请求
- 静态资源 Gzip 压缩
- API 请求合理（无重复请求）

---

## 📊 测试数据

### 已创建的测试用户

| 用户名 | 邮箱 | 密码 | 用途 |
|--------|------|------|------|
| testuser | test@example.com | test123456 | 基础测试 |
| demo001 | demo001@example.com | demo123456 | 注册测试 |

---

## 🔗 快速访问链接

- **前端首页**: http://localhost:5173/
- **登录页面**: http://localhost:5173/login
- **注册页面**: http://localhost:5173/register
- **后端 API**: http://localhost:8001/api/
- **Django Admin**: http://localhost:8001/admin/

---

## 💡 下一步

联调测试通过后，可以进行：

1. ✅ **创建数据库初始化脚本**
2. ✅ **构建 Docker 镜像**
3. ✅ **编写 K8s 配置文件**
4. ✅ **部署到 Kubernetes**

---

**测试愉快！** 🎉

