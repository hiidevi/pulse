# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set environment variables
# Expose the port (Hint for Railway)
EXPOSE 8080

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

# Run collectstatic during build (Baked into image)
RUN SECRET_KEY=build_secret DATABASE_URL=sqlite:///db.sqlite3 python manage.py collectstatic --noinput --clear

# Railway Start Command - Fast Startup
# Migrations removed - run via Railway Release Command or manually
CMD echo "🔍 Starting Uvicorn on port ${PORT:-8080}" && \
    uvicorn pulse_backend.asgi:application \
    --host 0.0.0.0 \
    --port ${PORT:-8080} \
    --log-level info \
    --timeout-keep-alive 75
