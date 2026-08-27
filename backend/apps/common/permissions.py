from rest_framework import permissions

class IsAdminUserRole(permissions.BasePermission):
    """
    Allows access only to users with the 'admin' role.
    """
    def hasattr_role(self, request):
        return hasattr(request.user, 'role')

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and self.hasattr_role(request) and request.user.role == 'admin')
