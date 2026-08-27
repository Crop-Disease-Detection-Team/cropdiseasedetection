from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    ChangePasswordView,
    ForgotPasswordView,
    LoginView,
    LogoutView,
    MeView,
    ResendOTPView,
    ResetPasswordView,
    SignupView,
    UserFavouriteDetailView,
    UserFavouriteListView,
    VerifyEmailView,
    VerifyOTPView,
)
from . import admin_views

urlpatterns = [
    path('signup/', SignupView.as_view(), name='signup'),
    path('register/', SignupView.as_view(), name='register'),
    path('verify-otp/', VerifyOTPView.as_view(), name='verify-otp'),
    path('resend-otp/', ResendOTPView.as_view(), name='resend-otp'),
    path('verify-email/', VerifyEmailView.as_view(), name='verify-email'),
    path('login/', LoginView.as_view(), name='login'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('refresh/', TokenRefreshView.as_view(), name='refresh'),
    path('forgot-password/', ForgotPasswordView.as_view(), name='forgot-password'),
    path('reset-password/', ResetPasswordView.as_view(), name='reset-password'),
    path('me/', MeView.as_view(), name='me'),
    path('profile/', MeView.as_view(), name='profile'),
    path('favourites/', UserFavouriteListView.as_view(), name='favourites_list'),
    path('favourites/<int:pk>/', UserFavouriteDetailView.as_view(), name='favourites_detail'),
    path('admin/stats/', admin_views.AdminDashboardStatsView.as_view(), name='admin_stats'),
    path('admin/users/', admin_views.AdminUserListView.as_view(), name='admin_users'),
    path('admin/users/<int:pk>/<str:action>/', admin_views.AdminUserActionView.as_view(), name='admin_user_action'),
    path('admin/users/<int:pk>/', admin_views.AdminUserActionView.as_view(), name='admin_user_delete'),
    path('change-password/', ChangePasswordView.as_view(), name='change-password'),
    path('logout/', LogoutView.as_view(), name='logout'),
]


