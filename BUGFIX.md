# 🐛 Bug 修复记录

## 问题：注册接口返回 400 Bad Request

### 错误描述
- **时间**: 2025-11-27
- **位置**: `/api/register/`
- **状态码**: 400 Bad Request
- **影响**: 用户无法注册

### 问题原因
前端在调用注册 API 时，只发送了以下字段：
```javascript
{
  username: formData.username,
  email: formData.email,
  password: formData.password
}
```

但后端 Django 序列化器要求必须包含 `password2` 字段来确认密码：
```python
class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(...)
    password2 = serializers.CharField(...)  # ← 必需字段
```

### 解决方案
修改 `frontend/src/views/Register.vue` 文件，添加 `password2` 字段：

```javascript
// 修改前
const response = await register({
  username: formData.username,
  email: formData.email,
  password: formData.password
})

// 修改后
const response = await register({
  username: formData.username,
  email: formData.email,
  password: formData.password,
  password2: formData.confirmPassword  // ← 添加此行
})
```

### 验证修复

#### 1. 在浏览器中测试
1. 访问 http://localhost:5173/register
2. 填写注册表单
3. 点击注册
4. **预期结果**: 显示"注册成功！3秒后跳转到登录页面..."

#### 2. 使用 curl 测试
```bash
curl -X POST http://localhost:5173/api/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser2",
    "email": "testuser2@example.com",
    "password": "password123",
    "password2": "password123"
  }'

# 预期响应: 201 Created
{
  "message": "注册成功",
  "user": {
    "id": 3,
    "username": "testuser2",
    ...
  }
}
```

### 额外改进
同时优化了错误处理逻辑，现在会显示更详细的验证错误信息：

```javascript
// 改进的错误处理
const errors = error.response?.data
if (errors && typeof errors === 'object') {
  const errorMessages = Object.entries(errors).map(([key, value]) => {
    return `${key}: ${Array.isArray(value) ? value.join(', ') : value}`
  }).join('; ')
  errorMessage.value = errorMessages || '注册失败，请稍后重试'
}
```

### 状态
✅ **已修复** - Vite 热更新已自动应用

---

## 测试清单

- [x] 修复前端代码
- [x] 添加详细错误处理
- [ ] 浏览器测试注册功能
- [ ] 浏览器测试登录功能
- [ ] 测试完整流程（注册→登录→查看信息）

---

**修复完成时间**: 2025-11-27 18:45

