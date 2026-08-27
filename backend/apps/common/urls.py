from django.urls import path
from .views import AdminSystemSettingsView, AdminLogListView, HealthCheckView

urlpatterns = [
    path('health/', HealthCheckView.as_view(), name='health_check'),
    path('admin/settings/', AdminSystemSettingsView.as_view(), name='admin_settings'),
    path('admin/logs/', AdminLogListView.as_view(), name='admin_logs'),
]

