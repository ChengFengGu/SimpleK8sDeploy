"""
Authentication app URL 配置
"""
from django.urls import path
from . import views

app_name = 'authentication'

urlpatterns = [
    # API 根路径
    path('', views.api_root, name='api-root'),
    
    # 用户注册
    path('register/', views.RegisterView.as_view(), name='register'),
    
    # 用户信息
    path('profile/', views.ProfileView.as_view(), name='profile'),
    
    # 修改密码
    path('change-password/', views.ChangePasswordView.as_view(), name='change-password'),
    
    # 退出登录
    path('logout/', views.logout_view, name='logout'),
    
    # 健康检查
    path('health/', views.health_check, name='health'),
]

