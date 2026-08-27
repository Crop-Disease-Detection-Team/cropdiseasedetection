from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

v1_patterns = [
    path('auth/', include('apps.accounts.urls')),
    path('', include('apps.scans.urls')),
    path('', include('apps.common.urls')),
]

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),

    # Health check
    path('api/health/', include('apps.common.urls')),

    # API v1 routes
    path('api/v1/', include(v1_patterns)),

    # Legacy / Direct API routes
    path('api/accounts/', include('apps.accounts.urls')),
    path('api/scans/', include('apps.scans.urls')),
    path('api/common/', include('apps.common.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)

