# Docker 部署指南

## 📦 部署架构

```
┌─────────────────────────────────────────┐
│           Nginx (可选)                   │
│         端口: 8080                       │
└──────────────┬──────────────────────────┘
               │
    ┌──────────┴─────────┐
    │                    │
┌───▼────────────┐  ┌───▼────────────┐
│  Frontend      │  │  Backend       │
│  (Vue3+Nginx)  │  │  (Django+DRF)  │
│  端口: 80      │  │  端口: 8000    │
└────────────────┘  └────┬───────────┘
                         │
                    ┌────▼─────────┐
                    │  PostgreSQL  │
                    │  端口: 5432  │
                    └──────────────┘
```

---

## 🚀 快速开始

### 前置要求

- Docker >= 20.10
- Docker Compose >= 2.0
- 至少 2GB 可用内存
- 至少 5GB 可用磁盘空间

### 步骤 1：创建环境变量文件

```bash
# 复制示例文件
cp .env.example .env

# 编辑配置（可选）
vim .env
```

### 步骤 2：启动所有服务

```bash
# 启动所有服务（后台运行）
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 步骤 3：等待服务就绪

```bash
# 等待数据库初始化（约10-30秒）
docker-compose logs -f postgres | grep "database system is ready"

# 等待后端迁移完成
docker-compose logs -f backend | grep "Applying"
```

### 步骤 4：访问服务

- **前端**: http://localhost (或 http://localhost:80)
- **后端 API**: http://localhost:8000
- **数据库**: localhost:5432

---

## 📋 Docker Compose 命令

### 服务管理

```bash
# 启动所有服务
docker-compose up -d

# 启动特定服务
docker-compose up -d postgres
docker-compose up -d backend
docker-compose up -d frontend

# 停止所有服务
docker-compose stop

# 停止特定服务
docker-compose stop backend

# 重启服务
docker-compose restart backend

# 查看服务状态
docker-compose ps

# 查看服务日志
docker-compose logs -f
docker-compose logs -f backend
docker-compose logs -f postgres

# 删除所有服务（保留数据卷）
docker-compose down

# 删除所有服务和数据卷
docker-compose down -v
```

### 服务执行命令

```bash
# 进入后端容器
docker-compose exec backend sh

# 在后端容器中执行 Django 命令
docker-compose exec backend python manage.py migrate
docker-compose exec backend python manage.py createsuperuser
docker-compose exec backend python manage.py shell

# 进入数据库
docker-compose exec postgres psql -U postgres -d logindb

# 查看数据库表
docker-compose exec postgres psql -U postgres -d logindb -c "\dt"
```

---

## 🔧 配置说明

### 环境变量

在 `.env` 文件中配置：

```bash
# 数据库配置
DB_NAME=logindb                    # 数据库名
DB_USER=postgres                   # 数据库用户
DB_PASSWORD=postgres123            # 数据库密码（生产环境请修改）
DB_HOST=postgres                   # 数据库主机
DB_PORT=5432                       # 数据库端口

# Django 配置
SECRET_KEY=your-secret-key         # Django 密钥（生产环境必须修改）
DEBUG=False                        # 调试模式（生产环境设为 False）
ALLOWED_HOSTS=*                    # 允许的主机

# CORS 配置
CORS_ALLOWED_ORIGINS=http://localhost:5173,http://localhost:8080

# 端口配置
BACKEND_PORT=8000                  # 后端端口
FRONTEND_PORT=80                   # 前端端口
```

### 端口映射

| 服务 | 容器端口 | 主机端口 | 说明 |
|------|----------|----------|------|
| PostgreSQL | 5432 | 5432 | 数据库 |
| Backend | 8000 | 8000 | Django API |
| Frontend | 80 | 80 | Vue3 前端 |
| Nginx (可选) | 80 | 8080 | 反向代理 |

---

## 🗄️ 数据管理

### 数据持久化

数据存储在 Docker 卷中：

```bash
# 查看数据卷
docker volume ls | grep login

# 数据卷信息
docker volume inspect login_postgres_data

# 备份数据卷
docker run --rm -v login_postgres_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/postgres_backup.tar.gz /data

# 恢复数据卷
docker run --rm -v login_postgres_data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/postgres_backup.tar.gz -C /
```

### 数据库备份

```bash
# 备份数据库
docker-compose exec postgres pg_dump -U postgres logindb > backup_$(date +%Y%m%d).sql

# 恢复数据库
docker-compose exec -T postgres psql -U postgres -d logindb < backup.sql

# 删除所有数据（危险操作）
docker-compose exec postgres psql -U postgres -d logindb -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
docker-compose exec backend python manage.py migrate
```

---

## 🧪 测试部署

### 步骤 1：启动数据库

```bash
# 只启动数据库
docker-compose up -d postgres

# 等待数据库就绪
docker-compose logs -f postgres

# 测试数据库连接
docker-compose exec postgres psql -U postgres -d logindb -c "SELECT version();"
```

### 步骤 2：启动后端

```bash
# 启动后端（依赖数据库）
docker-compose up -d backend

# 查看后端日志
docker-compose logs -f backend

# 测试后端 API
curl http://localhost:8000/api/health/
```

### 步骤 3：启动前端

```bash
# 启动前端
docker-compose up -d frontend

# 测试前端
curl http://localhost/
```

### 步骤 4：端到端测试

```bash
# 注册用户
curl -X POST http://localhost:8000/api/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "test123456",
    "password2": "test123456"
  }'

# 登录获取 Token
curl -X POST http://localhost:8000/api/token/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "test123456"
  }'
```

---

## 🔍 故障排查

### 服务无法启动

```bash
# 查看详细日志
docker-compose logs [service_name]

# 查看容器状态
docker-compose ps

# 重新构建镜像
docker-compose build --no-cache
docker-compose up -d
```

### 数据库连接失败

```bash
# 检查数据库是否运行
docker-compose ps postgres

# 检查数据库日志
docker-compose logs postgres

# 测试数据库连接
docker-compose exec postgres pg_isready -U postgres

# 检查网络
docker network inspect login_network
```

### 后端迁移失败

```bash
# 查看后端日志
docker-compose logs backend

# 手动执行迁移
docker-compose exec backend python manage.py migrate

# 检查数据库表
docker-compose exec postgres psql -U postgres -d logindb -c "\dt"
```

### 前端无法访问

```bash
# 检查前端日志
docker-compose logs frontend

# 检查 Nginx 配置
docker-compose exec frontend cat /etc/nginx/conf.d/default.conf

# 测试前端容器
docker-compose exec frontend wget -O- http://localhost/
```

---

## 🛠️ 开发模式

### 使用本地代码（热更新）

修改 `docker-compose.yml`，挂载本地代码：

```yaml
backend:
  volumes:
    - ./backend:/app  # 挂载本地代码
  command: python manage.py runserver 0.0.0.0:8000  # 使用开发服务器
```

### 只运行数据库

```bash
# 只启动数据库，本地运行前后端
docker-compose up -d postgres

# 修改后端配置连接到 Docker 数据库
# DB_HOST=localhost
```

---

## 🚀 生产部署建议

### 1. 安全配置

```bash
# 修改默认密码
DB_PASSWORD=$(openssl rand -base64 32)
SECRET_KEY=$(openssl rand -base64 50)

# 关闭调试模式
DEBUG=False

# 限制允许的主机
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
```

### 2. 性能优化

```yaml
backend:
  deploy:
    resources:
      limits:
        cpus: '2'
        memory: 2G
      reservations:
        cpus: '0.5'
        memory: 512M
```

### 3. 启用 Nginx 反向代理

```bash
# 启动所有服务包括 Nginx
docker-compose --profile with-nginx up -d

# 访问
http://localhost:8080
```

### 4. SSL/TLS 配置

使用 Let's Encrypt 或其他证书：

```yaml
nginx:
  volumes:
    - ./ssl/cert.pem:/etc/nginx/ssl/cert.pem:ro
    - ./ssl/key.pem:/etc/nginx/ssl/key.pem:ro
```

---

## 📊 监控和日志

### 查看资源使用

```bash
# 查看容器资源使用
docker stats

# 查看特定容器
docker stats login-backend login-postgres
```

### 日志管理

```bash
# 实时查看所有日志
docker-compose logs -f

# 查看最近100行日志
docker-compose logs --tail=100

# 导出日志到文件
docker-compose logs > logs_$(date +%Y%m%d).txt
```

---

## 🔄 更新和维护

### 更新镜像

```bash
# 拉取最新镜像
docker-compose pull

# 重新构建
docker-compose build

# 重启服务
docker-compose up -d
```

### 清理系统

```bash
# 删除未使用的镜像
docker image prune -a

# 删除未使用的卷
docker volume prune

# 清理所有未使用资源
docker system prune -a --volumes
```

---

## 📞 帮助

### 常用命令速查

```bash
# 启动
docker-compose up -d

# 停止
docker-compose stop

# 重启
docker-compose restart

# 日志
docker-compose logs -f

# 状态
docker-compose ps

# 进入容器
docker-compose exec [service] sh

# 删除（保留数据）
docker-compose down

# 删除（含数据）
docker-compose down -v
```

---

**部署愉快！** 🎉

