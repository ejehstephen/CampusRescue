# Official Dart Runtime
FROM dart:stable

WORKDIR /app

# Cache dependencies
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

# Copy all server sources
COPY . .
RUN dart pub get --offline

# Expose Serverpod API, Insights, and Web ports
EXPOSE 8080 8081 8082

ENTRYPOINT ["dart", "bin/main.dart", "--apply-migrations"]
