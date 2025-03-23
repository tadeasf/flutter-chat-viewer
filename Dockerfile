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

# Create or modify index.html with the environment variable
RUN mkdir -p web && \
    if [ -f web/index.html ]; then \
      # If the file already exists, add the script tag before the closing head tag
      sed -i '/<\/head>/i \  <script>\n    // Define FLUTTER_ENV globally so it\'s accessible from Dart\n    window.FLUTTER_ENV = {\n      "X_API_KEY": "'$X_API_KEY'"\n    };\n    // Also expose a function to get the API key directly\n    window.getFlutterApiKey = function() {\n      return "'$X_API_KEY'";\n    };\n  </script>' web/index.html && \
      # Add mobile web app capability
      sed -i 's/<meta name="apple-mobile-web-app-capable" content="yes">/<meta name="apple-mobile-web-app-capable" content="yes">\n  <meta name="mobile-web-app-capable" content="yes">/' web/index.html; \
    else \
      # Create a minimal index.html if it doesn't exist
      echo '<!DOCTYPE html>\n<html>\n<head>\n  <base href="$FLUTTER_BASE_HREF">\n  <meta charset="UTF-8">\n  <meta content="IE=Edge" http-equiv="X-UA-Compatible">\n  <meta name="description" content="Meta Elysia">\n  <meta name="apple-mobile-web-app-capable" content="yes">\n  <meta name="mobile-web-app-capable" content="yes">\n  <script>\n    // Define FLUTTER_ENV globally so it\'s accessible from Dart\n    window.FLUTTER_ENV = {\n      "X_API_KEY": "'$X_API_KEY'"\n    };\n    // Also expose a function to get the API key directly\n    window.getFlutterApiKey = function() {\n      return "'$X_API_KEY'";\n    };\n  </script>\n</head>\n<body>\n  <script src="main.dart.js" type="application/javascript"></script>\n</body>\n</html>' > web/index.html; \
    fi

# Fix manifest.json colors if it exists
RUN if [ -f web/manifest.json ]; then \
      sed -i 's/"theme_color": "#hexcode"/"theme_color": "#42a5f5"/g' web/manifest.json && \
      sed -i 's/"background_color": "#hexcode"/"background_color": "#42a5f5"/g' web/manifest.json; \
    else \
      # Create a minimal manifest.json if it doesn't exist
      echo '{\n  "name": "Meta Elysia",\n  "short_name": "Meta Elysia",\n  "start_url": ".",\n  "display": "standalone",\n  "background_color": "#42a5f5",\n  "theme_color": "#42a5f5",\n  "description": "A Flutter chat viewer application",\n  "orientation": "portrait",\n  "prefer_related_applications": false\n}' > web/manifest.json; \
    fi

# Get dependencies and build
RUN flutter pub get
RUN flutter build web --release

# Expose port for the web server
EXPOSE 8664

# Run dhttpd server, binding to all interfaces
CMD ["dhttpd", "--path", "build/web", "--port", "8664", "--host", "0.0.0.0"]
