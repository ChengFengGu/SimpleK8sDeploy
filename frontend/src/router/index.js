/**
 * Vue Router 配置
 * 定义路由规则和路由守卫
 */

import { createRouter, createWebHistory } from 'vue-router'
import { isAuthenticated } from '../utils/auth'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/Login.vue'),
    meta: {
      title: '登录',
      requiresAuth: false
    }
  },
  {
    path: '/register',
    name: 'Register',
    component: () => import('../views/Register.vue'),
    meta: {
      title: '注册',
      requiresAuth: false
    }
  },
  {
    path: '/',
    name: 'Home',
    component: () => import('../views/Home.vue'),
    meta: {
      title: '首页',
      requiresAuth: true
    }
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/'
  }
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
})

// 全局前置守卫：权限验证
router.beforeEach((to, from, next) => {
  // 设置页面标题
  document.title = to.meta.title 
    ? `${to.meta.title} - 登录系统` 
    : '登录系统'
  
  const authenticated = isAuthenticated()
  
  // 需要认证的路由
  if (to.meta.requiresAuth && !authenticated) {
    console.log('⚠️ 需要登录，跳转到登录页')
    next({ name: 'Login', query: { redirect: to.fullPath } })
    return
  }
  
  // 已登录用户访问登录或注册页，跳转到首页
  if ((to.name === 'Login' || to.name === 'Register') && authenticated) {
    console.log('ℹ️ 已登录，跳转到首页')
    next({ name: 'Home' })
    return
  }
  
  next()
})

// 全局后置钩子
router.afterEach((to, from) => {
  // 页面跳转后的处理
  console.log(`📄 路由跳转: ${from.path} -> ${to.path}`)
})

export default router

