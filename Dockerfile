FROM dart:stable

# Install dhttpd
RUN dart pub global activate dhttpd

# Add pub cache bin to PATH
ENV PATH="$PATH:/root/.pub-cache/bin"

# Set up working directory
WORKDIR /app

# Copy only the built web app
COPY build/web /app/build/web

# Expose port for the web server
EXPOSE 8664

# Run dhttpd server
CMD ["dhttpd", "--path", "build/web", "--port", "8664"]
