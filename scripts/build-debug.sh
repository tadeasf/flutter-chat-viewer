#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Function to show spinner
spinner() {
    local pid=$1
    local delay=0.1
    local chars="⣾⣽⣻⢿⡿⣟⣯⣷"
    while kill -0 $pid 2>/dev/null; do
        printf "\r${CYAN}%s${RESET}" "${chars:i++%${#chars}:1}"
        sleep $delay
    done
    printf "\r"
}

# Function to log errors
log_error() {
    local build_type=$1
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local log_file="${HOME}/flutter_chat_viewer_build_fail_${build_type}_${timestamp}.log"
    cat > "$log_file"
    echo -e "${RED}Build failed. Log saved to: $log_file${RESET}"
}

# Add this function at the beginning with other functions
print_separator() {
    local max_length=50  # Adjust this based on your terminal width
    printf '%*s\n' "$max_length" '' | tr ' ' '-'
}

# Platform selection
echo -e "${BLUE}Select platform to build for:${RESET}"
echo "1) Android"
echo "2) macOS"
echo "3) Linux"
read -p "Enter your choice (1-3): " platform_choice

case $platform_choice in
    1) PLATFORM="android" ;;
    2) PLATFORM="macos" ;;
    3) PLATFORM="linux" ;;
    *) echo -e "${RED}Invalid choice. Exiting.${RESET}" && exit 1 ;;
esac

# Check Java version only for Android builds
if [ "$PLATFORM" = "android" ]; then
    REQUIRED_JAVA="17.0.13"
    CURRENT_JAVA=$(java --version | head -n 1 | awk '{print $2}' | cut -d'.' -f1-3)

    if [ "$CURRENT_JAVA" != "$REQUIRED_JAVA" ]; then
        echo -e "${YELLOW}🔄 Setting Java version to $REQUIRED_JAVA...${RESET}"
        mise use java@corretto-17.0.13.11.1 > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to set Java version. Please ensure mise is installed and Java 17.0.13 is available.${RESET}"
            exit 1
        fi
        echo -e "${GREEN}✅ Java version set successfully!${RESET}"
    fi
fi

echo -e "${BLUE}🧹 Cleaning Flutter project...${RESET}"
print_separator
flutter clean > /dev/null 2>&1 & spinner $!

echo -e "${BLUE}📦 Getting dependencies...${RESET}"
print_separator
flutter pub get > /dev/null 2>&1 & spinner $!

# Build based on platform selection
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DESKTOP_DIR="${HOME}/Desktop"

case $PLATFORM in
    "android")
        echo -e "${BLUE}🏗️  Building debug APK...${RESET}"
        print_separator
        flutter build apk --debug > /tmp/build.log 2>&1 & spinner $!
        if [ $? -ne 0 ]; then
            cat /tmp/build.log | log_error "apk"
            BUILD_MESSAGE="${RED}❌ Failed - Log: ${HOME}/flutter_chat_viewer_build_fail_apk_${TIMESTAMP}.log${RESET}"
        else
            APK_PATH="${DESKTOP_DIR}/meta-chat-viewer_debug_latest.apk"
            if [ -f "$APK_PATH" ]; then
                mv "$APK_PATH" "${DESKTOP_DIR}/meta-chat-viewer_debug_deprecated_${TIMESTAMP}.apk"
            fi
            cp build/app/outputs/flutter-apk/app-debug.apk "$APK_PATH"
            BUILD_MESSAGE="${GREEN}✅ Success - Output: $APK_PATH${RESET}"
            echo -e "${GREEN}📱 Debug APK copied to Desktop${RESET}"
        fi
        ;;
    "macos")
        echo -e "${BLUE}🏗️  Building debug macOS app...${RESET}"
        print_separator
        flutter build macos --debug > /tmp/build.log 2>&1 & spinner $!
        if [ $? -ne 0 ]; then
            cat /tmp/build.log | log_error "macos"
            BUILD_MESSAGE="${RED}❌ Failed - Log: ${HOME}/flutter_chat_viewer_build_fail_macos_${TIMESTAMP}.log${RESET}"
        else
            APP_PATH="${DESKTOP_DIR}/Meta Elysia debug_latest.app"
            if [ -d "$APP_PATH" ]; then
                mv "$APP_PATH" "${DESKTOP_DIR}/Meta Elysia debug_deprecated_${TIMESTAMP}.app"
            fi
            cp -r build/macos/Build/Products/Debug/*.app "$APP_PATH"
            BUILD_MESSAGE="${GREEN}✅ Success - Output: $APP_PATH${RESET}"
            echo -e "${GREEN}🖥️  Debug macOS app copied to Desktop${RESET}"
        fi
        ;;
    "linux")
        echo -e "${BLUE}🏗️  Building debug Linux app...${RESET}"
        print_separator
        flutter build linux --debug > /tmp/build.log 2>&1 & spinner $!
        if [ $? -ne 0 ]; then
            cat /tmp/build.log | log_error "linux"
            BUILD_MESSAGE="${RED}❌ Failed - Log: ${HOME}/flutter_chat_viewer_build_fail_linux_${TIMESTAMP}.log${RESET}"
        else
            LINUX_PATH="${DESKTOP_DIR}/meta-chat-viewer_linux_debug_latest"
            if [ -d "$LINUX_PATH" ]; then
                mv "$LINUX_PATH" "${DESKTOP_DIR}/meta-chat-viewer_linux_debug_deprecated_${TIMESTAMP}"
            fi
            mkdir -p "$LINUX_PATH"
            cp -r build/linux/x64/debug/bundle/* "$LINUX_PATH"
            BUILD_MESSAGE="${GREEN}✅ Success - Output: $LINUX_PATH${RESET}"
            echo -e "${GREEN}🐧 Debug Linux app copied to Desktop${RESET}"
        fi
        ;;
esac

# Update the final output
echo -e "${MAGENTA}✨ Build process finished:${RESET}"
print_separator
echo -e "Build: $BUILD_MESSAGE"
print_separator
