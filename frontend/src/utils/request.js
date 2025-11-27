/**
 * Axios 封装
 * 统一处理请求和响应，自动添加 Token，统一错误处理
 */

import axios from 'axios'
import { getAccessToken, removeTokens } from './auth'
import router from '../router'

// 创建 axios 实例
const request = axios.create({
  baseURL: '/api', // 所有请求都加上 /api 前缀
  timeout: 10000, // 请求超时时间
  headers: {
    'Content-Type': 'application/json'
  }
})

// 请求拦截器：自动添加 Token
request.interceptors.request.use(
  config => {
    const token = getAccessToken()
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  error => {
    console.error('请求错误：', error)
    return Promise.reject(error)
  }
)

// 响应拦截器：统一错误处理
request.interceptors.response.use(
  response => {
    // 直接返回 data 部分
    return response.data
  },
  async error => {
    if (error.response) {
      const { status, data } = error.response
      
      switch (status) {
        case 401:
          // Token 过期或无效
          console.error('未授权，请重新登录')
          removeTokens()
          router.push('/login')
          break
          
        case 403:
          console.error('没有权限访问')
          break
          
        case 404:
          console.error('请求的资源不存在')
          break
          
        case 500:
          console.error('服务器错误')
          break
          
        default:
          console.error(`请求失败：${data?.message || error.message}`)
      }
      
      return Promise.reject(error)
    } else if (error.request) {
      // 请求已发送但没有收到响应
      console.error('网络错误，请检查网络连接')
      return Promise.reject(new Error('网络错误'))
    } else {
      // 发送请求时出错
      console.error('请求配置错误：', error.message)
      return Promise.reject(error)
    }
  }
)

export default request

