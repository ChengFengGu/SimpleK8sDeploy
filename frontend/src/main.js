import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './assets/styles/main.css'

const app = createApp(App)

// 状态管理
app.use(createPinia())

// 路由
app.use(router)

// 挂载应用
app.mount('#app')

