"""
用户模型
扩展 Django 的 AbstractUser 模型
"""
from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """
    自定义用户模型
    继承自 Django 的 AbstractUser，添加额外字段
    """
    email = models.EmailField(
        verbose_name='邮箱',
        unique=True,
        help_text='用户邮箱地址，必须唯一'
    )
    
    created_at = models.DateTimeField(
        verbose_name='创建时间',
        auto_now_add=True,
        help_text='账户创建时间'
    )
    
    updated_at = models.DateTimeField(
        verbose_name='更新时间',
        auto_now=True,
        help_text='账户最后更新时间'
    )
    
    class Meta:
        verbose_name = '用户'
        verbose_name_plural = '用户'
        db_table = 'users'
        ordering = ['-created_at']
    
    def __str__(self):
        return self.username
    
    @property
    def full_name(self):
        """返回用户全名"""
        return f"{self.first_name} {self.last_name}".strip() or self.username

