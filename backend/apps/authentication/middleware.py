"""
自定义中间件
可以在这里添加请求日志、性能监控等功能
"""
import logging
import time

logger = logging.getLogger(__name__)


class RequestLoggingMiddleware:
    """
    请求日志中间件
    记录每个请求的方法、路径和响应时间
    """
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        # 记录请求开始时间
        start_time = time.time()
        
        # 处理请求
        response = self.get_response(request)
        
        # 计算请求耗时
        duration = time.time() - start_time
        
        # 记录日志
        logger.info(
            f"{request.method} {request.path} - "
            f"Status: {response.status_code} - "
            f"Duration: {duration:.3f}s"
        )
        
        return response


class JWTAuthenticationMiddleware:
    """
    JWT 认证中间件（可选）
    可以在这里添加额外的 Token 验证逻辑
    """
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        # 可以在这里添加自定义的 JWT 验证逻辑
        # 例如：检查 Token 是否在黑名单中
        
        response = self.get_response(request)
        return response

