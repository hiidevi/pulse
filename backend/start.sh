#!/bin/bash

# Exit on error
set -e

# Start Uvicorn with fallback port
PORT=${PORT:-8080}
echo "----------------------------------------"
echo "Starting Uvicorn..."
echo "Assigned PORT: $PORT" 
echo "----------------------------------------"
echo "Launching Uvicorn server on port $PORT..."
exec uvicorn pulse_backend.asgi:application --host 0.0.0.0 --port $PORT --proxy-headers
