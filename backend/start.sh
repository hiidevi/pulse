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

# Start Daphne
echo "Launching Daphne server on port $PORT..."
exec daphne -b 0.0.0.0 -p $PORT pulse_backend.asgi:application
