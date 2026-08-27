from django.contrib.auth import get_user_model
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Count, Q
from django.utils import timezone
from datetime import timedelta

from apps.common.permissions import IsAdminUserRole
from apps.common.utils import log_admin_action
from apps.scans.models import ScanHistory, Disease
from .serializers import UserSerializer

User = get_user_model()

class AdminDashboardStatsView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminUserRole]

    def get(self, request):
        now = timezone.now()
        today = now.date()
        week_ago = now - timedelta(days=7)
        month_ago = now - timedelta(days=30)
        
        users = User.objects.all()
        scans = ScanHistory.objects.all()
        diseases = Disease.objects.all()

        total_users = users.count()
        active_users = users.filter(is_active=True).count()
        inactive_users = total_users - active_users
        total_admins = users.filter(role='admin').count()

        total_scans = scans.count()
        today_scans = scans.filter(created_at__date=today).count()
        week_scans = scans.filter(created_at__gte=week_ago).count()
        month_scans = scans.filter(created_at__gte=month_ago).count()

        # Some basic chart stats
        # For simplicity, returning empty lists here; can be populated further if needed.
        daily_scans = []
        disease_freq = []
        top_diseases = []

        return Response({
            'total_users': total_users,
            'active_users': active_users,
            'inactive_users': inactive_users,
            'total_admins': total_admins,
            'total_scans': total_scans,
            'today_scans': today_scans,
            'this_week_scans': week_scans,
            'this_month_scans': month_scans,
            'total_diseases': diseases.count(),
            'daily_stats': daily_scans,
            'disease_frequency': disease_freq,
            'top_diseases': top_diseases,
        })


class AdminUserListView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminUserRole]
    serializer_class = UserSerializer

    def get_queryset(self):
        queryset = User.objects.all()
        search = self.request.query_params.get('search', None)
        role = self.request.query_params.get('role', None)
        if search:
            queryset = queryset.filter(Q(email__icontains=search) | Q(full_name__icontains=search))
        if role:
            queryset = queryset.filter(role=role)
        return queryset.order_by('-date_joined')


class AdminUserActionView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminUserRole]

    def _get_user(self, pk):
        try:
            return User.objects.get(pk=pk)
        except User.DoesNotExist:
            return None

    def post(self, request, pk, action):
        user = self._get_user(pk)
        if not user:
            return Response({'detail': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

        if action == 'activate':
            user.is_active = True
            user.save()
            log_admin_action(request.user, 'Activated User', f'User: {user.email}')
        elif action == 'deactivate':
            user.is_active = False
            user.save()
            log_admin_action(request.user, 'Deactivated User', f'User: {user.email}')
        elif action == 'promote':
            user.role = 'admin'
            user.save()
            log_admin_action(request.user, 'Promoted to Admin', f'User: {user.email}')
        elif action == 'demote':
            user.role = 'user'
            user.save()
            log_admin_action(request.user, 'Demoted to User', f'User: {user.email}')
        elif action == 'reset_password':
            new_pass = request.data.get('password', 'password123')
            user.set_password(new_pass)
            user.save()
            log_admin_action(request.user, 'Reset User Password', f'User: {user.email}')
        else:
            return Response({'detail': 'Invalid action.'}, status=status.HTTP_400_BAD_REQUEST)

        return Response({'message': f'User {action} successful.'})

    def delete(self, request, pk):
        user = self._get_user(pk)
        if not user:
            return Response({'detail': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
        email = user.email
        user.delete()
        log_admin_action(request.user, 'Deleted User', f'User: {email}')
        return Response({'message': 'User deleted.'})
