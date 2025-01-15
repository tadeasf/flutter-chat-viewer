#!/bin/bash

# Function to show spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function to log errors
log_error() {
    local build_type=$1
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local log_file="/Users/tadeasfort/flutter_chat_viewer_build_fail_${build_type}_${timestamp}.log"
    cat > "$log_file"
    echo "Build failed. Log saved to: $log_file"
}

echo "🧹 Cleaning Flutter project..."
flutter clean > /dev/null 2>&1 & spinner $!

echo "📦 Getting dependencies..."
flutter pub get > /dev/null 2>&1 & spinner $!

echo "⬆️  Upgrading dependencies..."
flutter pub upgrade > /dev/null 2>&1 & spinner $!

echo "🏗️  Building release APK..."
if ! flutter build apk --release > /tmp/apk_build.log 2>&1; then
    cat /tmp/apk_build.log | log_error "apk"
    APK_SUCCESS=false
else
    APK_SUCCESS=true
    echo "✅ APK build successful!"
fi

echo "🏗️  Building release macOS app..."
if ! flutter build macos --release > /tmp/macos_build.log 2>&1; then
    cat /tmp/macos_build.log | log_error "macos"
    MACOS_SUCCESS=false
else
    MACOS_SUCCESS=true
    echo "✅ macOS build successful!"
fi

# Copy successful builds to Desktop
if [ "$APK_SUCCESS" = true ]; then
    cp build/app/outputs/flutter-apk/app-release.apk "/Users/tadeasfort/Desktop/meta-chat-viewer_release.apk"
    echo "📱 Release APK copied to Desktop"
fi

if [ "$MACOS_SUCCESS" = true ]; then
    cp -r build/macos/Build/Products/Release/*.app "/Users/tadeasfort/Desktop/Meta Elysia.app"
    echo "🖥️  Release macOS app copied to Desktop"
fi

if [ "$APK_SUCCESS" = true ] || [ "$MACOS_SUCCESS" = true ]; then
    echo "✨ Build process completed with some successes!"
else
    echo "❌ Build process failed completely"
    exit 1
fi
