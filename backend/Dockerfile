# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set environment variables
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

# Run collectstatic during build (Baked into image)
# We set dummy environment variables because settings.py runs during collectstatic
RUN SECRET_KEY=build_secret DATABASE_URL=sqlite:///db.sqlite3 python manage.py collectstatic --noinput --clear

# Start command is managed by railway.json
