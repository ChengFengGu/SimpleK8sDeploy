/**
 * 认证相关 API 接口
 */

import request from '../utils/request'

/**
 * 用户登录
 * @param {object} credentials - {username, password}
 * @returns {Promise}
 */
export function login(credentials) {
  return request({
    url: '/token/',
    method: 'post',
    data: credentials
  })
}

/**
 * 用户注册
 * @param {object} userData - {username, email, password}
 * @returns {Promise}
 */
export function register(userData) {
  return request({
    url: '/register/',
    method: 'post',
    data: userData
  })
}

/**
 * 获取用户信息
 * @returns {Promise}
 */
export function getProfile() {
  return request({
    url: '/profile/',
    method: 'get'
  })
}

/**
 * 刷新 Token
 * @param {string} refreshToken
 * @returns {Promise}
 */
export function refreshToken(refreshToken) {
  return request({
    url: '/token/refresh/',
    method: 'post',
    data: { refresh: refreshToken }
  })
}

/**
 * 退出登录
 * @returns {Promise}
 */
export function logout() {
  return request({
    url: '/logout/',
    method: 'post'
  })
}

/**
 * 健康检查
 * @returns {Promise}
 */
export function healthCheck() {
  return request({
    url: '/health/',
    method: 'get'
  })
}

