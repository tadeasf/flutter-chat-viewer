FROM ghcr.io/cirruslabs/flutter:latest

# Install dhttpd
RUN flutter pub global activate dhttpd
ENV PATH="$PATH:/root/.pub-cache/bin"

# Set up working directory
WORKDIR /app

# Copy the Flutter project
COPY . .

# API key is compiled in with --dart-define
ARG X_API_KEY
# Get dependencies and build
RUN flutter pub get
RUN flutter build web --release --dart-define=API_KEY=$X_API_KEY

# Expose port for the web server
EXPOSE 8664

# Run dhttpd server, binding to all interfaces
CMD ["dhttpd", "--path", "build/web", "--port", "8664", "--host", "0.0.0.0"]
