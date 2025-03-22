FROM ghcr.io/cirruslabs/flutter:latest

# Install dhttpd
RUN flutter pub global activate dhttpd
ENV PATH="$PATH:/root/.pub-cache/bin"

# Set up working directory
WORKDIR /app

# Copy the Flutter project
COPY . .

# Remove .env from pubspec.yaml to prevent it from being bundled as an asset
RUN sed -i '/- .env/d' pubspec.yaml

# Set the API key as an environment variable
ARG X_API_KEY
ENV X_API_KEY=$X_API_KEY

# Create an index.html with the environment variable
RUN mkdir -p web && \
    if [ -f web/index.html ]; then \
      sed -i '/<\/head>/i \  <script>\n    window.FLUTTER_ENV = {\n      "X_API_KEY": "'$X_API_KEY'"\n    }\n  </script>' web/index.html; \
    fi

# Get dependencies and build
RUN flutter pub get
RUN flutter build web --release

# Expose port for the web server
EXPOSE 8664

# Run dhttpd server, binding to all interfaces
CMD ["dhttpd", "--path", "build/web", "--port", "8664", "--host", "0.0.0.0"]
