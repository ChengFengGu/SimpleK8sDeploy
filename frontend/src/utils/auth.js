/**
 * Token 管理工具
 * 用于在 localStorage 中存储和管理 JWT Token
 */

const ACCESS_TOKEN_KEY = 'access_token'
const REFRESH_TOKEN_KEY = 'refresh_token'
const USER_INFO_KEY = 'user_info'

/**
 * 获取 Access Token
 * @returns {string|null}
 */
export function getAccessToken() {
  return localStorage.getItem(ACCESS_TOKEN_KEY)
}

/**
 * 设置 Access Token
 * @param {string} token
 */
export function setAccessToken(token) {
  localStorage.setItem(ACCESS_TOKEN_KEY, token)
}

/**
 * 获取 Refresh Token
 * @returns {string|null}
 */
export function getRefreshToken() {
  return localStorage.getItem(REFRESH_TOKEN_KEY)
}

/**
 * 设置 Refresh Token
 * @param {string} token
 */
export function setRefreshToken(token) {
  localStorage.setItem(REFRESH_TOKEN_KEY, token)
}

/**
 * 设置 Token（同时设置 access 和 refresh）
 * @param {string} accessToken
 * @param {string} refreshToken
 */
export function setTokens(accessToken, refreshToken) {
  setAccessToken(accessToken)
  if (refreshToken) {
    setRefreshToken(refreshToken)
  }
}

/**
 * 移除所有 Token
 */
export function removeTokens() {
  localStorage.removeItem(ACCESS_TOKEN_KEY)
  localStorage.removeItem(REFRESH_TOKEN_KEY)
  localStorage.removeItem(USER_INFO_KEY)
}

/**
 * 检查是否已登录（是否有 Token）
 * @returns {boolean}
 */
export function isAuthenticated() {
  return !!getAccessToken()
}

/**
 * 获取用户信息
 * @returns {object|null}
 */
export function getUserInfo() {
  const userInfo = localStorage.getItem(USER_INFO_KEY)
  return userInfo ? JSON.parse(userInfo) : null
}

/**
 * 设置用户信息
 * @param {object} userInfo
 */
export function setUserInfo(userInfo) {
  localStorage.setItem(USER_INFO_KEY, JSON.stringify(userInfo))
}

/**
 * 清除所有认证信息
 */
export function clearAuth() {
  removeTokens()
}

