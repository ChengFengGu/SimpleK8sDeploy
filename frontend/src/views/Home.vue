<template>
  <div class="home-container">
    <div class="home-card">
      <!-- 顶部导航 -->
      <div class="navbar">
        <div class="logo">
          <span class="icon">🏠</span>
          <h2>登录系统</h2>
        </div>
        <button @click="handleLogout" class="btn-logout">
          <span class="icon">🚪</span>
          退出登录
        </button>
      </div>

      <!-- 欢迎区域 -->
      <div class="welcome-section">
        <div class="welcome-icon">✨</div>
        <h1>欢迎回来！</h1>
        <p class="subtitle">您已成功登录系统</p>
      </div>

      <!-- 用户信息卡片 -->
      <div class="user-info-card">
        <div class="card-header">
          <span class="icon">👤</span>
          <h3>用户信息</h3>
        </div>
        <div class="card-body">
          <div v-if="loading" class="loading">
            <div class="spinner"></div>
            <p>加载中...</p>
          </div>
          <div v-else-if="userInfo" class="info-grid">
            <div class="info-item">
              <label>用户名</label>
              <span class="value">{{ userInfo.username || '未设置' }}</span>
            </div>
            <div class="info-item">
              <label>邮箱</label>
              <span class="value">{{ userInfo.email || '未设置' }}</span>
            </div>
            <div class="info-item">
              <label>用户ID</label>
              <span class="value">{{ userInfo.id || '未知' }}</span>
            </div>
            <div class="info-item">
              <label>注册时间</label>
              <span class="value">{{ formatDate(userInfo.created_at) }}</span>
            </div>
          </div>
          <div v-else class="no-data">
            <p>⚠️ 无法加载用户信息</p>
          </div>
        </div>
      </div>

      <!-- 系统信息卡片 -->
      <div class="system-info-card">
        <div class="card-header">
          <span class="icon">⚙️</span>
          <h3>系统信息</h3>
        </div>
        <div class="card-body">
          <div class="info-grid">
            <div class="info-item">
              <label>前端框架</label>
              <span class="value">Vue 3 + Vite</span>
            </div>
            <div class="info-item">
              <label>后端框架</label>
              <span class="value">Django + DRF</span>
            </div>
            <div class="info-item">
              <label>数据库</label>
              <span class="value">PostgreSQL</span>
            </div>
            <div class="info-item">
              <label>容器编排</label>
              <span class="value">Kubernetes</span>
            </div>
          </div>
        </div>
      </div>

      <!-- 功能提示 -->
      <div class="feature-tips">
        <h4>✨ 系统特性</h4>
        <ul>
          <li>🔐 JWT Token 认证</li>
          <li>🚀 单页应用（SPA）无刷新切换</li>
          <li>📦 前后端分离架构</li>
          <li>☸️ Kubernetes 容器编排</li>
          <li>🔄 自动扩展和负载均衡</li>
          <li>💾 数据持久化存储</li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { getProfile } from '../api/auth'
import { getUserInfo, clearAuth } from '../utils/auth'

const router = useRouter()

// 状态
const loading = ref(true)
const userInfo = ref(null)

// 加载用户信息
const loadUserInfo = async () => {
  loading.value = true
  
  try {
    // 先从 localStorage 获取
    const cachedUserInfo = getUserInfo()
    if (cachedUserInfo) {
      userInfo.value = cachedUserInfo
    }

    // 再从服务器获取最新信息
    const response = await getProfile()
    if (response) {
      userInfo.value = response
    }
  } catch (error) {
    console.error('❌ 获取用户信息失败:', error)
    // 如果是 401 错误，会被 axios 拦截器处理，自动跳转到登录页
  } finally {
    loading.value = false
  }
}

// 退出登录
const handleLogout = () => {
  if (confirm('确定要退出登录吗？')) {
    clearAuth()
    router.push('/login')
  }
}

// 格式化日期
const formatDate = (dateString) => {
  if (!dateString) return '未知'
  try {
    const date = new Date(dateString)
    return date.toLocaleString('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    })
  } catch {
    return '未知'
  }
}

// 组件挂载时加载数据
onMounted(() => {
  loadUserInfo()
})
</script>

<style scoped>
.home-container {
  min-height: 100vh;
  padding: 20px;
  display: flex;
  justify-content: center;
  align-items: flex-start;
}

.home-card {
  background: white;
  border-radius: 20px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  width: 100%;
  max-width: 800px;
  margin-top: 40px;
  overflow: hidden;
  animation: slideUp 0.5s ease;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* 导航栏 */
.navbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 30px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.logo {
  display: flex;
  align-items: center;
  gap: 10px;
}

.logo .icon {
  font-size: 24px;
}

.logo h2 {
  margin: 0;
  font-size: 20px;
  font-weight: 700;
}

.btn-logout {
  background: rgba(255, 255, 255, 0.2);
  border: 2px solid white;
  color: white;
  padding: 8px 20px;
  border-radius: 8px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 600;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 6px;
}

.btn-logout:hover {
  background: white;
  color: #667eea;
}

/* 欢迎区域 */
.welcome-section {
  text-align: center;
  padding: 40px 30px;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
}

.welcome-icon {
  font-size: 60px;
  margin-bottom: 20px;
  animation: bounce 2s infinite;
}

@keyframes bounce {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-10px);
  }
}

.welcome-section h1 {
  font-size: 32px;
  color: #333;
  margin: 0 0 10px 0;
  font-weight: 700;
}

.welcome-section .subtitle {
  font-size: 16px;
  color: #666;
  margin: 0;
}

/* 卡片通用样式 */
.user-info-card,
.system-info-card {
  margin: 30px;
  border: 2px solid #e0e0e0;
  border-radius: 15px;
  overflow: hidden;
}

.card-header {
  background: #f8f9fa;
  padding: 15px 20px;
  display: flex;
  align-items: center;
  gap: 10px;
  border-bottom: 2px solid #e0e0e0;
}

.card-header .icon {
  font-size: 20px;
}

.card-header h3 {
  margin: 0;
  font-size: 18px;
  color: #333;
  font-weight: 600;
}

.card-body {
  padding: 20px;
}

/* 加载状态 */
.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 15px;
  padding: 20px;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #667eea;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* 信息网格 */
.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.info-item label {
  font-size: 12px;
  color: #999;
  text-transform: uppercase;
  font-weight: 600;
  letter-spacing: 0.5px;
}

.info-item .value {
  font-size: 16px;
  color: #333;
  font-weight: 500;
}

.no-data {
  text-align: center;
  padding: 20px;
  color: #999;
}

/* 功能提示 */
.feature-tips {
  margin: 30px;
  padding: 25px;
  background: linear-gradient(135deg, #667eea10 0%, #764ba210 100%);
  border-radius: 15px;
}

.feature-tips h4 {
  margin: 0 0 15px 0;
  font-size: 18px;
  color: #333;
}

.feature-tips ul {
  list-style: none;
  padding: 0;
  margin: 0;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 10px;
}

.feature-tips li {
  font-size: 14px;
  color: #555;
  padding: 8px 12px;
  background: white;
  border-radius: 8px;
  transition: all 0.3s ease;
}

.feature-tips li:hover {
  transform: translateX(5px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

/* 响应式设计 */
@media (max-width: 768px) {
  .home-card {
    margin-top: 0;
    border-radius: 0;
  }

  .navbar {
    flex-direction: column;
    gap: 15px;
  }

  .welcome-section h1 {
    font-size: 24px;
  }

  .info-grid {
    grid-template-columns: 1fr;
  }

  .feature-tips ul {
    grid-template-columns: 1fr;
  }
}
</style>

