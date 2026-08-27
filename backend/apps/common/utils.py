from .models import AdminLog

def log_admin_action(admin, action, details='', ip_address=None):
    if admin and admin.is_authenticated:
        AdminLog.objects.create(
            admin=admin,
            action=action,
            details=details,
            ip_address=ip_address
        )
