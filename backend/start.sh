#!/bin/bash

# Exit on error
set -e

echo "Starting Pulse Backend Startup Sequence..."

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput --clear

# Run migrations
echo "Applying database migrations..."
python manage.py migrate --noinput

# Start Uvicorn
echo "Launching Uvicorn server on port $PORT..."
exec uvicorn pulse_backend.asgi:application --host 0.0.0.0 --port $PORT --proxy-headers
