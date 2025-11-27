-- ============================================
-- PostgreSQL 数据库初始化脚本
-- 用于 K8s 登录系统
-- ============================================

-- 创建数据库（如果不存在）
-- 注意：在 Docker 中，数据库通常已经通过环境变量创建
-- 此脚本主要用于创建表结构和初始数据

-- ============================================
-- 用户表
-- ============================================
-- 注意：Django 会自动创建表结构，此脚本仅作为参考和文档

-- Django 会创建以下表：
-- 1. users (自定义用户表)
-- 2. auth_group (用户组)
-- 3. auth_permission (权限)
-- 4. auth_user_groups (用户-组关系)
-- 5. auth_user_user_permissions (用户-权限关系)
-- 6. django_admin_log (管理日志)
-- 7. django_content_type (内容类型)
-- 8. django_migrations (迁移记录)
-- 9. django_session (会话)

-- ============================================
-- 创建扩展（如果需要）
-- ============================================
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";  -- UUID 支持
-- CREATE EXTENSION IF NOT EXISTS "pg_trgm";     -- 文本搜索支持

-- ============================================
-- 表结构参考（Django 自动创建）
-- ============================================
/*
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    password VARCHAR(128) NOT NULL,
    last_login TIMESTAMP WITH TIME ZONE,
    is_superuser BOOLEAN NOT NULL DEFAULT FALSE,
    username VARCHAR(150) UNIQUE NOT NULL,
    first_name VARCHAR(150) NOT NULL DEFAULT '',
    last_name VARCHAR(150) NOT NULL DEFAULT '',
    email VARCHAR(254) UNIQUE NOT NULL,
    is_staff BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    date_joined TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 索引
CREATE INDEX IF NOT EXISTS users_username_idx ON users(username);
CREATE INDEX IF NOT EXISTS users_email_idx ON users(email);
CREATE INDEX IF NOT EXISTS users_created_at_idx ON users(created_at);
*/

-- ============================================
-- 初始数据（可选）
-- ============================================
-- 注意：密码需要使用 Django 的密码哈希格式
-- 建议通过 Django 管理命令创建超级用户：
-- python manage.py createsuperuser

-- 插入测试数据示例（在实际环境中不建议）
-- INSERT INTO users (username, email, password, is_staff, is_superuser, is_active)
-- VALUES 
--   ('admin', 'admin@example.com', 'pbkdf2_sha256$...', TRUE, TRUE, TRUE);

-- ============================================
-- 触发器：自动更新 updated_at
-- ============================================
/*
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
*/

-- ============================================
-- 数据库配置优化
-- ============================================
-- 设置字符集和排序规则
-- ALTER DATABASE logindb SET client_encoding TO 'UTF8';
-- ALTER DATABASE logindb SET timezone TO 'Asia/Shanghai';

-- ============================================
-- 权限设置
-- ============================================
-- GRANT ALL PRIVILEGES ON DATABASE logindb TO postgres;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;

-- ============================================
-- 性能优化建议
-- ============================================
-- 1. 定期执行 VACUUM ANALYZE
-- 2. 监控慢查询日志
-- 3. 根据需要调整 shared_buffers 和 work_mem
-- 4. 为常用查询字段创建索引

-- ============================================
-- 备份建议
-- ============================================
-- # 备份数据库
-- pg_dump -U postgres -d logindb > backup.sql
-- 
-- # 恢复数据库
-- psql -U postgres -d logindb < backup.sql
-- 
-- # 使用 Docker 备份
-- docker exec postgres_container pg_dump -U postgres logindb > backup.sql

-- ============================================
-- 完成
-- ============================================
-- 数据库初始化脚本完成
-- Django 迁移将创建实际的表结构

