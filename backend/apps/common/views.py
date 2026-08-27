from rest_framework import generics, permissions
from apps.common.models import SystemSettings, AdminLog
from apps.common.permissions import IsAdminUserRole
from rest_framework import serializers

class SystemSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = SystemSettings
        fields = '__all__'

class AdminLogSerializer(serializers.ModelSerializer):
    admin_email = serializers.CharField(source='admin.email', read_only=True)
    class Meta:
        model = AdminLog
        fields = ['id', 'admin_email', 'action', 'details', 'ip_address', 'created_at']

class AdminSystemSettingsView(generics.RetrieveUpdateAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminUserRole]
    serializer_class = SystemSettingsSerializer

    def get_object(self):
        obj, created = SystemSettings.objects.get_or_create(id=1)
        return obj

class AdminLogListView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminUserRole]
    serializer_class = AdminLogSerializer
    queryset = AdminLog.objects.all().order_by('-created_at')


class HealthCheckView(generics.GenericAPIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        return generics.Response({'status': 'healthy', 'system': 'AgriVision AI', 'version': '1.0.0'})

