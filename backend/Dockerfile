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

# Copy and verify entrypoint
COPY backend/entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

# Run collectstatic during build (Baked into image)
RUN SECRET_KEY=build_secret DATABASE_URL=sqlite:///db.sqlite3 python manage.py collectstatic --noinput --clear

# Use entrypoint script
CMD ["/app/entrypoint.sh"]
