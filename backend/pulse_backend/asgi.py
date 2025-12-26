"""
ASGI config for pulse_backend project.
Implements proper lifespan protocol for Railway deployment.
"""
import os
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'pulse_backend.settings')

# Initialize Django ASGI application early
django_asgi_app = get_asgi_application()

async def application(scope, receive, send):
    """
    ASGI application with proper lifespan protocol support.
    This signals to Railway when the app is ready and when it's shutting down.
    """
    if scope['type'] == 'lifespan':
        while True:
            message = await receive()
            if message['type'] == 'lifespan.startup':
                # Signal: Application is ready to receive traffic
                print("🚀 [LIFESPAN] Application startup complete - ready for traffic")
                await send({'type': 'lifespan.startup.complete'})
            elif message['type'] == 'lifespan.shutdown':
                # Signal: Application is shutting down gracefully
                print("👋 [LIFESPAN] Application shutdown initiated")
                await send({'type': 'lifespan.shutdown.complete'})
                return
    else:
        # Handle HTTP/WebSocket requests
        await django_asgi_app(scope, receive, send)
