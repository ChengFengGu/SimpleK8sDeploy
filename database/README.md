# 数据库配置文档

## PostgreSQL 数据库说明

### 数据库信息
- **数据库类型**: PostgreSQL 15
- **数据库名**: `logindb`
- **默认用户**: `postgres`
- **端口**: `5432`

---

## 表结构

### 用户表 (users)

Django 自动创建的自定义用户表：

| 字段 | 类型 | 说明 | 约束 |
|------|------|------|------|
| id | SERIAL | 主键 | PRIMARY KEY |
| username | VARCHAR(150) | 用户名 | UNIQUE, NOT NULL |
| email | VARCHAR(254) | 邮箱 | UNIQUE, NOT NULL |
| password | VARCHAR(128) | 密码（加密） | NOT NULL |
| first_name | VARCHAR(150) | 名 | |
| last_name | VARCHAR(150) | 姓 | |
| is_active | BOOLEAN | 是否激活 | DEFAULT TRUE |
| is_staff | BOOLEAN | 是否为员工 | DEFAULT FALSE |
| is_superuser | BOOLEAN | 是否为超级用户 | DEFAULT FALSE |
| date_joined | TIMESTAMP | 注册时间 | DEFAULT NOW() |
| last_login | TIMESTAMP | 最后登录时间 | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT NOW() |
| updated_at | TIMESTAMP | 更新时间 | DEFAULT NOW() |

### 索引
- `users_username_idx` - 用户名索引
- `users_email_idx` - 邮箱索引
- `users_created_at_idx` - 创建时间索引

---

## Docker 部署

### 使用 Docker Compose（推荐）

```bash
# 启动数据库
docker-compose up -d postgres

# 查看日志
docker-compose logs -f postgres

# 停止数据库
docker-compose stop postgres

# 删除数据库（包括数据）
docker-compose down -v
```

### 直接使用 Docker

```bash
# 运行 PostgreSQL 容器
docker run -d \
  --name postgres-db \
  -e POSTGRES_DB=logindb \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres123 \
  -p 5432:5432 \
  -v postgres_data:/var/lib/postgresql/data \
  postgres:15-alpine

# 查看日志
docker logs -f postgres-db

# 进入容器
docker exec -it postgres-db psql -U postgres -d logindb

# 停止容器
docker stop postgres-db

# 删除容器
docker rm postgres-db
```

---

## 数据库连接

### 连接字符串

```bash
# 开发环境
postgresql://postgres:postgres123@localhost:5432/logindb

# Docker 容器内
postgresql://postgres:postgres123@postgres:5432/logindb

# K8s 环境
postgresql://postgres:postgres123@postgres-service:5432/logindb
```

### Django 配置

在 `backend/config/settings.py` 中：

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'logindb',
        'USER': 'postgres',
        'PASSWORD': 'postgres123',
        'HOST': 'localhost',  # 或 'postgres'（Docker）
        'PORT': '5432',
    }
}
```

### 环境变量

```bash
DB_NAME=logindb
DB_USER=postgres
DB_PASSWORD=postgres123
DB_HOST=localhost
DB_PORT=5432
```

---

## Django 数据库迁移

### 创建迁移

```bash
# 激活虚拟环境
source venv/bin/activate  # 或 conda activate djangodemo

# 创建迁移文件
python manage.py makemigrations

# 执行迁移
python manage.py migrate

# 查看迁移状态
python manage.py showmigrations

# 查看 SQL 语句
python manage.py sqlmigrate authentication 0001
```

### 创建超级用户

```bash
python manage.py createsuperuser

# 输入用户名、邮箱和密码
Username: admin
Email: admin@example.com
Password: ********
Password (again): ********
```

---

## 数据库管理

### 使用 psql 命令行

```bash
# 连接数据库
psql -h localhost -U postgres -d logindb

# 常用命令
\dt                 # 列出所有表
\d users            # 查看 users 表结构
\du                 # 列出所有用户
\l                  # 列出所有数据库
\q                  # 退出

# 查询示例
SELECT * FROM users;
SELECT username, email FROM users WHERE is_active = true;
```

### 使用 Docker 执行 psql

```bash
# 方法1：直接执行命令
docker exec -it postgres-db psql -U postgres -d logindb -c "SELECT * FROM users;"

# 方法2：进入交互式 shell
docker exec -it postgres-db psql -U postgres -d logindb
```

---

## 数据备份与恢复

### 备份数据库

```bash
# 使用 pg_dump
pg_dump -h localhost -U postgres -d logindb > backup_$(date +%Y%m%d).sql

# 使用 Docker
docker exec postgres-db pg_dump -U postgres logindb > backup.sql

# 只备份数据（不包括表结构）
pg_dump -h localhost -U postgres -d logindb --data-only > data_backup.sql

# 只备份表结构（不包括数据）
pg_dump -h localhost -U postgres -d logindb --schema-only > schema_backup.sql
```

### 恢复数据库

```bash
# 使用 psql
psql -h localhost -U postgres -d logindb < backup.sql

# 使用 Docker
docker exec -i postgres-db psql -U postgres -d logindb < backup.sql

# 恢复特定表
pg_restore -h localhost -U postgres -d logindb -t users backup.sql
```

---

## 监控和维护

### 查看数据库大小

```sql
-- 查看所有数据库大小
SELECT 
    datname as database_name,
    pg_size_pretty(pg_database_size(datname)) as size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;

-- 查看表大小
SELECT 
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### 查看活动连接

```sql
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    query
FROM pg_stat_activity
WHERE datname = 'logindb';
```

### 性能优化

```sql
-- 分析表统计信息
ANALYZE users;

-- 清理和分析
VACUUM ANALYZE users;

-- 重建索引
REINDEX TABLE users;
```

---

## 故障排查

### 连接问题

```bash
# 测试连接
pg_isready -h localhost -p 5432

# 检查端口占用
netstat -an | grep 5432
lsof -i :5432

# 查看 PostgreSQL 日志
docker logs postgres-db
```

### 常见错误

#### 1. 连接被拒绝
```
psycopg2.OperationalError: connection refused
```
**解决**: 检查 PostgreSQL 是否运行，端口是否正确

#### 2. 密码认证失败
```
psycopg2.OperationalError: password authentication failed
```
**解决**: 检查用户名和密码是否正确

#### 3. 数据库不存在
```
psycopg2.OperationalError: database "logindb" does not exist
```
**解决**: 创建数据库或检查数据库名称

---

## 安全建议

### 生产环境

1. **使用强密码**
   ```bash
   # 生成随机密码
   openssl rand -base64 32
   ```

2. **限制网络访问**
   ```bash
   # 只允许特定 IP 访问
   # 修改 pg_hba.conf
   host    logindb    postgres    10.0.0.0/8    md5
   ```

3. **使用 SSL 连接**
   ```python
   DATABASES = {
       'default': {
           ...
           'OPTIONS': {
               'sslmode': 'require',
           }
       }
   }
   ```

4. **定期备份**
   ```bash
   # 添加到 crontab
   0 2 * * * pg_dump -U postgres logindb > /backup/logindb_$(date +\%Y\%m\%d).sql
   ```

---

## K8s 部署注意事项

1. **使用 Secret 存储密码**
2. **使用 PersistentVolume 持久化数据**
3. **配置资源限制**
4. **设置健康检查**
5. **考虑使用 StatefulSet**

详见 K8s 配置文件。

---

## 参考资源

- [PostgreSQL 官方文档](https://www.postgresql.org/docs/)
- [Django 数据库文档](https://docs.djangoproject.com/en/4.2/ref/databases/)
- [Docker PostgreSQL](https://hub.docker.com/_/postgres)

---

**最后更新**: 2025-11-27

