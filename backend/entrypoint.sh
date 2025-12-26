#!/bin/sh
set -e

# Default to 8080 if PORT not set
PORT=${PORT:-8080}

echo "-----------------------------------------------------"
echo "STARTING PULSE BACKEND"
echo " Detected PORT environment variable: $PORT"
echo "-----------------------------------------------------"

# Run migrations
echo "Running migrations..."
python manage.py migrate --noinput

# Start Uvicorn
echo "Starting Uvicorn on 0.0.0.0:$PORT..."
exec uvicorn pulse_backend.asgi:application --host 0.0.0.0 --port $PORT --proxy-headers
