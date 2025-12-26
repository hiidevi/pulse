# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set work directory
WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    build-essential \
    libpq-dev \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Install Python requirements
COPY backend/requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY backend/ /app/

# Environment for static files
ENV DJANGO_SETTINGS_MODULE=pulse_backend.settings
RUN python manage.py collectstatic --noinput

# Expose port
EXPOSE 8000

# Start command for production (Gunicorn + Uvicorn workers)
CMD gunicorn pulse_backend.asgi:application --get-asgi-application --bind 0.0.0.0:$PORT --worker-class uvicorn.workers.UvicornWorker --workers 4 --threads 4 --timeout 120
