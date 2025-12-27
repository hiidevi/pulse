"""
URL configuration for pulse_backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse, HttpResponse
from django.views.decorators.cache import never_cache
import django

@never_cache
def health_check(request):
    """
    Health check endpoint for Render.
    Returns service status, Django version, and database connectivity.
    """
    from django.db import connection
    from django.db.utils import OperationalError
    
    db_status = "unknown"
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            db_status = "connected"
    except OperationalError:
        db_status = "disconnected"
        return JsonResponse({'status': 'unhealthy', 'database': db_status}, status=503)

    return JsonResponse({
        'status': 'healthy',
        'service': 'pulse-backend',
        'django_version': django.get_version(),
        'database': db_status,
    })

urlpatterns = [
    path('', lambda r: HttpResponse("OK"), name='root'),
    path('health/', health_check, name='health'),
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
]
