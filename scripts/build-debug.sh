#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Check Java version and set if needed
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
    local log_file="/Users/tadeasfort/flutter_chat_viewer_build_fail_${build_type}_${timestamp}.log"
    cat > "$log_file"
    echo "Build failed. Log saved to: $log_file"
}

# Add this function at the beginning with other functions
print_separator() {
    local max_length=50  # Adjust this based on your terminal width
    printf '%*s\n' "$max_length" '' | tr ' ' '-'
}

echo -e "${BLUE}🧹 Cleaning Flutter project...${RESET}"
print_separator
flutter clean > /dev/null 2>&1 & spinner $!

echo -e "${BLUE}📦 Getting dependencies...${RESET}"
print_separator
flutter pub get > /dev/null 2>&1 & spinner $!

echo -e "${BLUE}⬆️  Upgrading dependencies...${RESET}"
print_separator
flutter pub upgrade > /dev/null 2>&1 & spinner $!

echo -e "${BLUE}🏗️  Building debug APK...${RESET}"
print_separator
flutter build apk --debug > /tmp/apk_build.log 2>&1 & 
spinner $!
if [ $? -ne 0 ]; then
    cat /tmp/apk_build.log | log_error "apk"
    APK_SUCCESS=false
    APK_MESSAGE="${RED}❌ Failed - Log: /Users/tadeasfort/flutter_chat_viewer_build_fail_apk_$(date +%Y%m%d_%H%M%S).log${RESET}"
else
    APK_SUCCESS=true
    APK_PATH="/Users/tadeasfort/Desktop/meta-chat-viewer_debug_latest.apk"
    APK_MESSAGE="${GREEN}✅ Success - Output: $APK_PATH${RESET}"
fi

echo -e "${BLUE}🏗️  Building debug macOS app...${RESET}"
print_separator
flutter build macos --debug > /tmp/macos_build.log 2>&1 &
spinner $!
if [ $? -ne 0 ]; then
    cat /tmp/macos_build.log | log_error "macos"
    MACOS_SUCCESS=false
    MACOS_MESSAGE="${RED}❌ Failed - Log: /Users/tadeasfort/flutter_chat_viewer_build_fail_macos_$(date +%Y%m%d_%H%M%S).log${RESET}"
else
    MACOS_SUCCESS=true
    MACOS_MESSAGE="${GREEN}✅ Success - Output: /Users/tadeasfort/Desktop/Meta Elysia debug_latest.app${RESET}"
fi

# Copy successful builds to Desktop with versioning
if [ "$APK_SUCCESS" = true ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    APK_PATH="/Users/tadeasfort/Desktop/meta-chat-viewer_debug_latest.apk"
    
    if [ -f "$APK_PATH" ]; then
        mv "$APK_PATH" "/Users/tadeasfort/Desktop/meta-chat-viewer_debug_deprecated_${TIMESTAMP}.apk"
    fi
    
    cp build/app/outputs/flutter-apk/app-debug.apk "$APK_PATH"
    echo -e "${GREEN}📱 Debug APK copied to Desktop${RESET}"
fi

if [ "$MACOS_SUCCESS" = true ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    APP_PATH="/Users/tadeasfort/Desktop/Meta Elysia debug_latest.app"
    
    if [ -d "$APP_PATH" ]; then
        mv "$APP_PATH" "/Users/tadeasfort/Desktop/Meta Elysia debug_deprecated_${TIMESTAMP}.app"
    fi
    
    cp -r build/macos/Build/Products/Debug/*.app "$APP_PATH"
    echo -e "${GREEN}🖥️  Debug macOS app copied to Desktop${RESET}"
fi

# Update the final output
echo -e "${MAGENTA}✨ Build process finished:${RESET}"
print_separator
echo -e "APK: $APK_MESSAGE"
echo -e "APP: $MACOS_MESSAGE"
print_separator
