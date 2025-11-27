# ============================================
# 阶段 1: 构建阶段 - 编译 Vue3 应用
# ============================================
FROM node:18-alpine AS builder

# 使用阿里云镜像源加速
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 设置工作目录
WORKDIR /app

# 复制依赖文件
COPY package*.json ./

# 使用淘宝 npm 镜像源加速
RUN npm config set registry https://registry.npmmirror.com

# 安装所有依赖（构建阶段需要 devDependencies 中的 vite）
RUN npm ci

# 复制源代码
COPY . .

# 构建应用
RUN npm run build

# ============================================
# 阶段 2: 运行阶段 - Nginx 服务静态文件
# ============================================
FROM nginx:alpine

# 使用阿里云镜像源加速
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 维护者信息
LABEL maintainer="your-email@example.com"
LABEL description="K8s Login System Frontend - Vue3 + Nginx"

# 从构建阶段复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 复制 Nginx 配置文件
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 暴露端口
EXPOSE 80

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# 启动 Nginx
CMD ["nginx", "-g", "daemon off;"]

