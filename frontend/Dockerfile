# Use an official Flutter image
FROM ghcr.io/cirruslabs/flutter:stable

# Set work directory
WORKDIR /app

# Copy pubspec and get dependencies
COPY pubspec.yaml /app/
RUN flutter pub get

# Copy project
COPY . /app/

# Basic flutter build check (can be used for CI)
RUN flutter build apk --debug
