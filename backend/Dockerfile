# ============================================
# 阶段 1: 构建阶段 / Stage 1: Build Stage
# ============================================
FROM python:3.11-alpine AS builder

# 设置工作目录 / Set working directory
WORKDIR /app

# 使用阿里云镜像源加速 / Use Aliyun mirror for acceleration
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装系统依赖 / Install system dependencies
RUN apk add --no-cache \
    postgresql-dev \
    gcc \
    python3-dev \
    musl-dev \
    linux-headers

# 复制依赖文件 / Copy requirements file
COPY requirements.txt .

# 使用阿里云 PyPI 镜像源加速 / Use Aliyun PyPI mirror for acceleration
RUN pip install --no-cache-dir --upgrade pip -i https://mirrors.aliyun.com/pypi/simple/ && \
    pip install --no-cache-dir -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/

# ============================================
# 阶段 2: 运行阶段 / Stage 2: Runtime Stage
# ============================================
FROM python:3.11-alpine

# 设置环境变量 / Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

# 使用阿里云镜像源加速 / Use Aliyun mirror for acceleration
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装运行时依赖 / Install runtime dependencies
RUN apk add --no-cache \
    postgresql-libs \
    libpq

# 创建非 root 用户 / Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# 设置工作目录 / Set working directory
WORKDIR /app

# 从构建阶段复制 Python 包 / Copy Python packages from build stage
COPY --from=builder /usr/local/lib/python3.11/site-packages/ /usr/local/lib/python3.11/site-packages/
COPY --from=builder /usr/local/bin/ /usr/local/bin/

# 复制项目文件 / Copy project files
COPY --chown=appuser:appgroup . .

# 创建静态文件目录 / Create static files directory
RUN mkdir -p /app/staticfiles && \
    chown -R appuser:appgroup /app

# 切换到非 root 用户 / Switch to non-root user
USER appuser

# 收集静态文件 / Collect static files
RUN python manage.py collectstatic --noinput || true

# 暴露端口 / Expose port
EXPOSE 8000

# 健康检查 / Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:8000/api/health/ || exit 1

# 启动命令 / Start command
CMD ["sh", "-c", "python manage.py migrate && gunicorn config.wsgi:application --bind 0.0.0.0:8000 --workers 3 --timeout 60 --access-logfile - --error-logfile -"]
