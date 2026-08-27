from django.db import models
from django.conf import settings

class SystemSettings(models.Model):
    system_name = models.CharField(max_length=255, default="AgriVision AI")
    application_version = models.CharField(max_length=50, default="1.0.0")
    maintenance_mode = models.BooleanField(default=False)
    prediction_threshold = models.FloatField(default=0.5)
    default_language = models.CharField(max_length=10, default="en")
    email_host = models.CharField(max_length=255, blank=True)
    email_port = models.IntegerField(default=587)
    email_user = models.CharField(max_length=255, blank=True)
    otp_expiry_minutes = models.IntegerField(default=10)
    jwt_expiration_minutes = models.IntegerField(default=30)
    upload_size_limit_mb = models.IntegerField(default=10)
    ai_model_selection = models.CharField(max_length=50, default="onnx")
    last_backup_at = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.system_name


class AdminLog(models.Model):
    admin = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='admin_logs')
    action = models.CharField(max_length=255)
    details = models.TextField(blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.admin.email} - {self.action} at {self.created_at}"
