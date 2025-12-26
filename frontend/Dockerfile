# Stage 1: Build
FROM debian:latest AS build-env

# Install dependencies
RUN apt-get update && apt-get install -y curl git wget unzip python3

# Clone Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Build Flutter Web
RUN flutter config --enable-web
RUN flutter doctor

WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --release

# Stage 2: Serve
FROM nginx:stable-alpine

# Copy built assets
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Use shell form to allow environment variable expansion in Nginx config
CMD ["/bin/sh", "-c", "sed -i 's/${PORT}/'\"$PORT\"'/g' /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
