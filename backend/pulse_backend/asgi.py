"""
ASGI config for pulse_backend project.
Includes lifespan protocol support for Railway compatibility.
"""
import os
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'pulse_backend.settings')

# Initialize Django ASGI application
django_asgi_app = get_asgi_application()

async def application(scope, receive, send):
    """
    ASGI application with lifespan protocol support.
    Prevents 'lifespan protocol unsupported' warning that Railway treats as error.
    """
    if scope['type'] == 'lifespan':
        while True:
            message = await receive()
            if message['type'] == 'lifespan.startup':
                await send({'type': 'lifespan.startup.complete'})
            elif message['type'] == 'lifespan.shutdown':
                await send({'type': 'lifespan.shutdown.complete'})
                return
    else:
        await django_asgi_app(scope, receive, send)
