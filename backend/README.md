# 后端应用 - Django + Django REST Framework

基于 Django 4.2 和 Django REST Framework 构建的 RESTful API 后端服务。

## 技术栈

- **框架**: Django 4.2
- **API框架**: Django REST Framework 3.14
- **认证**: djangorestframework-simplejwt (JWT)
- **数据库**: PostgreSQL
- **WSGI服务器**: Gunicorn
- **数据库驱动**: psycopg2-binary

## 项目结构

```
backend/
├── config/                 # 项目配置
│   ├── __init__.py
│   ├── settings.py        # Django 设置
│   ├── urls.py            # 主路由配置
│   ├── wsgi.py            # WSGI 配置
│   └── asgi.py            # ASGI 配置
├── apps/                   # 应用目录
│   └── authentication/    # 认证应用
│       ├── models.py      # 数据模型
│       ├── serializers.py # 序列化器
│       ├── views.py       # 视图
│       ├── urls.py        # 路由
│       ├── admin.py       # Admin 配置
│       └── middleware.py  # 中间件
├── manage.py              # Django 管理脚本
├── requirements.txt       # Python 依赖
├── Dockerfile             # Docker 配置
└── README.md              # 项目文档
```

## 快速开始

### 前置要求

- Python >= 3.11
- PostgreSQL >= 15
- pip >= 23.x

### 安装依赖

```bash
# 创建虚拟环境
python -m venv venv

# 激活虚拟环境
# Linux/macOS:
source venv/bin/activate
# Windows:
venv\Scripts\activate

# 安装依赖
pip install -r requirements.txt
```

### 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，设置数据库连接等配置
```

### 数据库迁移

```bash
# 创建迁移文件
python manage.py makemigrations

# 执行迁移
python manage.py migrate

# 创建超级用户（可选）
python manage.py createsuperuser
```

### 启动开发服务器

```bash
python manage.py runserver 0.0.0.0:8000
```

访问: http://localhost:8000/api/

### 访问 Django Admin

```bash
# 创建超级用户后访问
http://localhost:8000/admin/
```

## API 接口文档

### 基础 URL

```
http://localhost:8000/api/
```

### 认证接口

#### 1. 用户注册

```http
POST /api/register/
Content-Type: application/json

{
  "username": "testuser",
  "email": "test@example.com",
  "password": "password123",
  "password2": "password123"
}

响应 (201 Created):
{
  "message": "注册成功",
  "user": {
    "id": 1,
    "username": "testuser",
    "email": "test@example.com",
    "created_at": "2025-11-27 10:00:00"
  }
}
```

#### 2. 用户登录（获取 Token）

```http
POST /api/token/
Content-Type: application/json

{
  "username": "testuser",
  "password": "password123"
}

响应 (200 OK):
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

#### 3. 刷新 Token

```http
POST /api/token/refresh/
Content-Type: application/json

{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}

响应 (200 OK):
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

#### 4. 获取用户信息

```http
GET /api/profile/
Authorization: Bearer <access_token>

响应 (200 OK):
{
  "id": 1,
  "username": "testuser",
  "email": "test@example.com",
  "first_name": "",
  "last_name": "",
  "created_at": "2025-11-27 10:00:00",
  "updated_at": "2025-11-27 10:00:00"
}
```

#### 5. 更新用户信息

```http
PUT /api/profile/
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "first_name": "张",
  "last_name": "三"
}

响应 (200 OK):
{
  "message": "更新成功",
  "user": { ... }
}
```

#### 6. 修改密码

```http
POST /api/change-password/
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "old_password": "oldpass123",
  "new_password": "newpass123",
  "new_password2": "newpass123"
}

响应 (200 OK):
{
  "message": "密码修改成功"
}
```

#### 7. 退出登录

```http
POST /api/logout/
Authorization: Bearer <access_token>

响应 (200 OK):
{
  "message": "退出登录成功"
}
```

#### 8. 健康检查

```http
GET /api/health/

响应 (200 OK):
{
  "status": "healthy",
  "service": "authentication-api",
  "version": "1.0.0"
}
```

## 数据模型

### User 模型

```python
class User(AbstractUser):
    email = models.EmailField(unique=True)  # 邮箱（唯一）
    created_at = models.DateTimeField(auto_now_add=True)  # 创建时间
    updated_at = models.DateTimeField(auto_now=True)  # 更新时间
```

继承自 Django 的 `AbstractUser`，包含以下字段：
- `username` - 用户名（唯一）
- `email` - 邮箱（唯一）
- `password` - 密码（加密存储）
- `first_name` - 名
- `last_name` - 姓
- `is_active` - 是否激活
- `is_staff` - 是否为员工
- `is_superuser` - 是否为超级用户
- `last_login` - 最后登录时间
- `date_joined` - 注册时间
- `created_at` - 创建时间
- `updated_at` - 更新时间

## Docker 部署

### 构建镜像

```bash
docker build -t login-backend:latest .
```

### 运行容器

```bash
docker run -d \
  -p 8000:8000 \
  -e DB_HOST=postgres \
  -e DB_NAME=logindb \
  -e DB_USER=postgres \
  -e DB_PASSWORD=yourpassword \
  --name backend \
  login-backend:latest
```

### 使用 Docker Compose（本地测试）

```bash
# 在项目根目录
docker-compose up -d
```

## 环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `SECRET_KEY` | Django 密钥 | - |
| `DEBUG` | 调试模式 | `False` |
| `ALLOWED_HOSTS` | 允许的主机 | `*` |
| `DB_NAME` | 数据库名称 | `logindb` |
| `DB_USER` | 数据库用户 | `postgres` |
| `DB_PASSWORD` | 数据库密码 | `postgres` |
| `DB_HOST` | 数据库主机 | `localhost` |
| `DB_PORT` | 数据库端口 | `5432` |
| `CORS_ALLOWED_ORIGINS` | CORS 允许的源 | - |

## Django 管理命令

```bash
# 创建迁移
python manage.py makemigrations

# 执行迁移
python manage.py migrate

# 创建超级用户
python manage.py createsuperuser

# 收集静态文件
python manage.py collectstatic

# 启动开发服务器
python manage.py runserver

# 进入 Shell
python manage.py shell

# 查看所有命令
python manage.py help
```

## 开发指南

### 添加新的 API 接口

1. 在 `apps/authentication/views.py` 添加视图
2. 在 `apps/authentication/urls.py` 添加路由
3. 在 `apps/authentication/serializers.py` 添加序列化器（如需要）

### 数据库迁移

```bash
# 每次修改 models.py 后执行
python manage.py makemigrations
python manage.py migrate
```

### 测试 API

使用 curl 或 Postman 测试：

```bash
# 注册
curl -X POST http://localhost:8000/api/register/ \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@example.com","password":"pass123","password2":"pass123"}'

# 登录
curl -X POST http://localhost:8000/api/token/ \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"pass123"}'

# 获取用户信息
curl http://localhost:8000/api/profile/ \
  -H "Authorization: Bearer <your_access_token>"
```

## 安全配置

### 生产环境检查清单

- [ ] 设置强密钥 `SECRET_KEY`
- [ ] 关闭调试模式 `DEBUG=False`
- [ ] 配置 `ALLOWED_HOSTS`
- [ ] 使用 HTTPS
- [ ] 配置数据库安全连接
- [ ] 定期更新依赖
- [ ] 启用 Django 安全中间件
- [ ] 配置 CORS 白名单

## 性能优化

- ✅ 使用 Gunicorn 多进程
- ✅ 数据库连接池
- ✅ JWT Token 认证（无状态）
- ✅ 密码使用 bcrypt 加密
- ✅ API 响应优化
- ✅ 静态文件收集

## 故障排查

### 数据库连接错误

```bash
# 检查数据库是否运行
psql -h localhost -U postgres -d logindb

# 检查环境变量
echo $DB_HOST $DB_NAME $DB_USER
```

### 迁移错误

```bash
# 查看迁移状态
python manage.py showmigrations

# 回滚迁移
python manage.py migrate authentication <migration_name>

# 重置数据库（小心使用）
python manage.py flush
```

## 相关文档

- [Django 官方文档](https://docs.djangoproject.com/)
- [Django REST Framework 文档](https://www.django-rest-framework.org/)
- [Simple JWT 文档](https://django-rest-framework-simplejwt.readthedocs.io/)

## 许可证

MIT

---

**开发者**: K8s Login System Team  
**更新时间**: 2025-11-27

