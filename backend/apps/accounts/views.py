import secrets
import random
from datetime import timedelta
from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from .models import User, UserFavourite
from .serializers import (
    ChangePasswordSerializer,
    LoginSerializer,
    OTPVerifySerializer,
    ForgotPasswordSerializer,
    ResetPasswordSerializer,
    SignupSerializer,
    UserSerializer,
    UserFavouriteSerializer,
)

User = get_user_model()


def jwt_for(user):
    refresh = RefreshToken.for_user(user)
    refresh['role'] = user.role
    access = refresh.access_token
    access['role'] = user.role
    return {'access': str(access), 'refresh': str(refresh)}

def generate_otp(user):
    otp = str(random.randint(100000, 999999))
    user.verification_otp = otp
    user.otp_expires_at = timezone.now() + timedelta(minutes=10)
    user.otp_last_sent = timezone.now()
    user.save(update_fields=['verification_otp', 'otp_expires_at', 'otp_last_sent'])
    return otp

class SignupView(generics.CreateAPIView):
    serializer_class = SignupSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        otp = generate_otp(user)

        # Provide tokens immediately after signup so the client can persist session
        return Response({
            'message': 'Signup successful.',
            'dev_otp': otp,
            'email': user.email,
            'user': UserSerializer(user).data,
            **jwt_for(user)
        }, status=status.HTTP_201_CREATED)


class VerifyOTPView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = OTPVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        email = serializer.validated_data['email']
        code = serializer.validated_data['code']
        
        user = User.objects.filter(email=email).first()
        if not user:
            return Response({'detail': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
            
        if user.verification_otp != code or user.otp_expires_at < timezone.now():
            return Response({'detail': 'Invalid or expired OTP.'}, status=status.HTTP_400_BAD_REQUEST)
            
        # Verify success
        user.is_email_verified = True
        user.is_active = True
        user.verification_otp = None
        user.save(update_fields=['is_email_verified', 'is_active', 'verification_otp'])
        
        return Response({
            'message': 'Email verified.',
            'user': UserSerializer(user).data,
            **jwt_for(user)
        })


class ResendOTPView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email')
        if not email:
            return Response({'detail': 'Email is required.'}, status=status.HTTP_400_BAD_REQUEST)
        user = User.objects.filter(email=email).first()
        if not user:
            return Response({'detail': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
        otp = generate_otp(user)
        return Response({'message': 'New OTP generated.', 'dev_otp': otp})


class VerifyEmailView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        return VerifyOTPView().post(request)


class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user']
        return Response({'user': UserSerializer(user).data, **jwt_for(user)})


class ForgotPasswordView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = ForgotPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = User.objects.filter(email=serializer.validated_data['email']).first()
        if user:
            otp = generate_otp(user)
            return Response({'message': 'If the account exists, a reset OTP has been sent.', 'dev_otp': otp})
        return Response({'message': 'If the account exists, a reset OTP has been sent.'})


class ResetPasswordView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = ResetPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        email = serializer.validated_data['email']
        code = serializer.validated_data['code']
        password = serializer.validated_data['password']
        
        user = User.objects.filter(email=email).first()
        if not user or user.verification_otp != code or user.otp_expires_at < timezone.now():
            return Response({'detail': 'Invalid or expired OTP.'}, status=status.HTTP_400_BAD_REQUEST)
            
        user.set_password(password)
        user.verification_otp = None
        user.save(update_fields=['password', 'verification_otp'])
        
        return Response({'message': 'Password reset successful.'})


class MeView(APIView):
    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def patch(self, request):
        serializer = UserSerializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)


class ChangePasswordView(APIView):
    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = request.user
        if not user.check_password(serializer.validated_data['current_password']):
            return Response({'current_password': 'Current password is incorrect.'}, status=status.HTTP_400_BAD_REQUEST)
        user.set_password(serializer.validated_data['new_password'])
        user.save(update_fields=['password'])
        return Response({'message': 'Password changed successfully.'})


class LogoutView(APIView):
    def post(self, request):
        refresh = request.data.get('refresh')
        if refresh:
            try:
                token = RefreshToken(refresh)
                token.blacklist()
            except Exception:
                pass
        return Response({'message': 'Logged out.'})


class UserFavouriteListView(generics.ListCreateAPIView):
    serializer_class = UserFavouriteSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return UserFavourite.objects.filter(user=self.request.user).select_related('disease', 'disease__crop').order_by('-saved_at')

    def perform_create(self, serializer):
        disease_id = serializer.validated_data.get('disease_id')
        disease_obj = serializer.validated_data.get('disease')
        from apps.scans.models import Disease
        disease = disease_obj or (generics.get_object_or_404(Disease, pk=disease_id) if disease_id else None)
        if not disease:
            raise serializers.ValidationError({'disease_id': 'Disease ID is required.'})
        notes = serializer.validated_data.get('notes', '')
        fav, created = UserFavourite.objects.get_or_create(
            user=self.request.user,
            disease=disease,
            defaults={'notes': notes}
        )
        if not created and notes:
            fav.notes = notes
            fav.save(update_fields=['notes'])
        serializer.instance = fav


class UserFavouriteDetailView(generics.DestroyAPIView):
    serializer_class = UserFavouriteSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return UserFavourite.objects.filter(user=self.request.user)

