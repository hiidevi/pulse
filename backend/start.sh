#!/bin/bash

# Exit on error
set -e

# Start Uvicorn
echo "Launching Uvicorn server on port $PORT..."
exec uvicorn pulse_backend.asgi:application --host 0.0.0.0 --port $PORT --proxy-headers
