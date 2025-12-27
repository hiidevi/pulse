"""
ASGI config for pulse_backend project.
"""
import os
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'pulse_backend.settings')

# Use Django's default ASGI application
# Uvicorn handles lifespan protocol automatically
application = get_asgi_application()
