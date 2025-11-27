"""
API 视图
"""
from rest_framework import status, generics
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.views import APIView
from django.contrib.auth import get_user_model
from .serializers import UserSerializer, RegisterSerializer, ChangePasswordSerializer

User = get_user_model()


class RegisterView(generics.CreateAPIView):
    """
    用户注册视图
    POST /api/register/
    """
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [AllowAny]
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        # 返回用户信息
        user_serializer = UserSerializer(user)
        return Response({
            'message': '注册成功',
            'user': user_serializer.data
        }, status=status.HTTP_201_CREATED)


class ProfileView(APIView):
    """
    用户信息视图
    GET /api/profile/ - 获取当前用户信息
    PUT /api/profile/ - 更新当前用户信息
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        """获取当前用户信息"""
        serializer = UserSerializer(request.user)
        return Response(serializer.data)
    
    def put(self, request):
        """更新当前用户信息"""
        serializer = UserSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response({
                'message': '更新成功',
                'user': serializer.data
            })
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ChangePasswordView(APIView):
    """
    修改密码视图
    POST /api/change-password/
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            # 设置新密码
            request.user.set_password(serializer.validated_data['new_password'])
            request.user.save()
            
            return Response({
                'message': '密码修改成功'
            }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    """
    退出登录视图
    POST /api/logout/
    
    注意：由于使用 JWT，实际的"退出"是在前端删除 Token
    这个接口主要用于服务端记录日志或执行其他清理操作
    """
    return Response({
        'message': '退出登录成功'
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    """
    健康检查接口
    GET /api/health/
    """
    return Response({
        'status': 'healthy',
        'service': 'authentication-api',
        'version': '1.0.0'
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([AllowAny])
def api_root(request):
    """
    API 根路径
    GET /api/
    """
    return Response({
        'message': 'Login System API',
        'version': '1.0.0',
        'endpoints': {
            'token': '/api/token/',
            'token_refresh': '/api/token/refresh/',
            'register': '/api/register/',
            'profile': '/api/profile/',
            'change_password': '/api/change-password/',
            'logout': '/api/logout/',
            'health': '/api/health/',
        }
    })

