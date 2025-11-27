<template>
  <div class="auth-container">
    <div class="auth-card">
      <!-- 标题 -->
      <div class="auth-header">
        <h1>📝 注册账户</h1>
        <p>创建您的账户，开始使用系统</p>
      </div>

      <!-- 注册表单 -->
      <form @submit.prevent="handleRegister" class="auth-form">
        <!-- 用户名 -->
        <div class="form-group">
          <label for="username">
            <span class="icon">👤</span>
            用户名
          </label>
          <input
            id="username"
            v-model="formData.username"
            type="text"
            placeholder="请输入用户名（3-20个字符）"
            required
            minlength="3"
            maxlength="20"
            autocomplete="username"
          />
        </div>

        <!-- 邮箱 -->
        <div class="form-group">
          <label for="email">
            <span class="icon">📧</span>
            邮箱
          </label>
          <input
            id="email"
            v-model="formData.email"
            type="email"
            placeholder="请输入邮箱地址"
            required
            autocomplete="email"
          />
        </div>

        <!-- 密码 -->
        <div class="form-group">
          <label for="password">
            <span class="icon">🔑</span>
            密码
          </label>
          <input
            id="password"
            v-model="formData.password"
            type="password"
            placeholder="请输入密码（至少6位）"
            required
            minlength="6"
            autocomplete="new-password"
          />
        </div>

        <!-- 确认密码 -->
        <div class="form-group">
          <label for="confirmPassword">
            <span class="icon">🔐</span>
            确认密码
          </label>
          <input
            id="confirmPassword"
            v-model="formData.confirmPassword"
            type="password"
            placeholder="请再次输入密码"
            required
            autocomplete="new-password"
          />
        </div>

        <!-- 错误提示 -->
        <div v-if="errorMessage" class="error-message">
          ⚠️ {{ errorMessage }}
        </div>

        <!-- 成功提示 -->
        <div v-if="successMessage" class="success-message">
          ✅ {{ successMessage }}
        </div>

        <!-- 注册按钮 -->
        <button type="submit" class="btn-primary" :disabled="loading">
          <span v-if="loading">注册中...</span>
          <span v-else>注册</span>
        </button>
      </form>

      <!-- 底部链接 -->
      <div class="auth-footer">
        <p>
          已有账户？
          <router-link to="/login">立即登录</router-link>
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { register } from '../api/auth'

const router = useRouter()

// 表单数据
const formData = reactive({
  username: '',
  email: '',
  password: '',
  confirmPassword: ''
})

// 状态
const loading = ref(false)
const errorMessage = ref('')
const successMessage = ref('')

// 处理注册
const handleRegister = async () => {
  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  // 前端验证
  if (formData.password !== formData.confirmPassword) {
    errorMessage.value = '两次输入的密码不一致'
    loading.value = false
    return
  }

  if (formData.password.length < 6) {
    errorMessage.value = '密码长度至少为6位'
    loading.value = false
    return
  }

  try {
    // 调用注册 API
    const response = await register({
      username: formData.username,
      email: formData.email,
      password: formData.password,
      password2: formData.confirmPassword
    })

    console.log('✅ 注册成功:', response)

    // 显示成功消息
    successMessage.value = '注册成功！3秒后跳转到登录页面...'

    // 3秒后跳转到登录页
    setTimeout(() => {
      router.push('/login')
    }, 3000)
  } catch (error) {
    console.error('❌ 注册失败:', error)
    console.error('错误响应:', error.response)
    console.error('错误数据:', error.response?.data)

    // 显示错误信息
    if (error.response?.data?.username) {
      errorMessage.value = `用户名: ${error.response.data.username.join(', ')}`
    } else if (error.response?.data?.email) {
      errorMessage.value = `邮箱: ${error.response.data.email.join(', ')}`
    } else if (error.response?.data?.password) {
      errorMessage.value = `密码: ${error.response.data.password.join(', ')}`
    } else if (error.response?.data?.detail) {
      errorMessage.value = error.response.data.detail
    } else if (error.response?.data?.message) {
      errorMessage.value = error.response.data.message
    } else {
      // 显示所有错误字段
      const errors = error.response?.data
      if (errors && typeof errors === 'object') {
        const errorMessages = Object.entries(errors).map(([key, value]) => {
          return `${key}: ${Array.isArray(value) ? value.join(', ') : value}`
        }).join('; ')
        errorMessage.value = errorMessages || '注册失败，请稍后重试'
      } else {
        errorMessage.value = '注册失败，请稍后重试'
      }
    }
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.auth-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  padding: 20px;
}

.auth-card {
  background: white;
  border-radius: 20px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  padding: 40px;
  width: 100%;
  max-width: 440px;
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

.auth-header {
  text-align: center;
  margin-bottom: 30px;
}

.auth-header h1 {
  font-size: 28px;
  color: #333;
  margin-bottom: 10px;
  font-weight: 700;
}

.auth-header p {
  color: #666;
  font-size: 14px;
}

.auth-form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group label {
  font-size: 14px;
  font-weight: 600;
  color: #333;
  display: flex;
  align-items: center;
  gap: 6px;
}

.form-group label .icon {
  font-size: 16px;
}

.form-group input {
  padding: 12px 16px;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  font-size: 15px;
  transition: all 0.3s ease;
  background: #f8f9fa;
}

.form-group input:focus {
  outline: none;
  border-color: #667eea;
  background: white;
  box-shadow: 0 0 0 4px rgba(102, 126, 234, 0.1);
}

.error-message {
  background: #fee;
  color: #c33;
  padding: 12px;
  border-radius: 8px;
  font-size: 14px;
  text-align: center;
}

.success-message {
  background: #efe;
  color: #3c3;
  padding: 12px;
  border-radius: 8px;
  font-size: 14px;
  text-align: center;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  padding: 14px;
  border-radius: 10px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-top: 10px;
}

.btn-primary:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 10px 25px rgba(102, 126, 234, 0.4);
}

.btn-primary:active:not(:disabled) {
  transform: translateY(0);
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.auth-footer {
  margin-top: 25px;
  text-align: center;
  padding-top: 20px;
  border-top: 1px solid #e0e0e0;
}

.auth-footer p {
  font-size: 14px;
  color: #666;
}

.auth-footer a {
  color: #667eea;
  text-decoration: none;
  font-weight: 600;
  transition: color 0.3s ease;
}

.auth-footer a:hover {
  color: #764ba2;
  text-decoration: underline;
}

/* 响应式设计 */
@media (max-width: 480px) {
  .auth-card {
    padding: 30px 20px;
  }

  .auth-header h1 {
    font-size: 24px;
  }
}
</style>

