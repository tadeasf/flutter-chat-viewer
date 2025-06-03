#!/bin/bash

# Meta Elysia Installation Script for Fedora Linux
# This script installs the Meta Elysia application bundle

set -e

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}Meta Elysia Installation Script for Fedora${NC}"
echo "This script will install Meta Elysia on your Fedora system."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}Please run as root or with sudo.${NC}"
  exit 1
fi

# Check if we're on a Fedora system
if ! command -v dnf &> /dev/null && ! command -v yum &> /dev/null; then
  echo -e "${RED}Error: This script is designed for Fedora systems with DNF or YUM package manager.${NC}"
  exit 1
fi

# Define paths
BUNDLE_PATH="$(pwd)/build/linux/x64/release/bundle"
INSTALL_DIR="/usr/local/lib/meta-elysia"
BIN_DIR="/usr/local/bin"
DESKTOP_FILE_PATH="/usr/local/share/applications"
ICON_DIR="/usr/local/share/icons/hicolor/256x256/apps"

# Check if bundle exists
if [ ! -d "$BUNDLE_PATH" ]; then
  echo -e "${RED}Error: Bundle directory not found at $BUNDLE_PATH${NC}"
  echo "Please run this script from the root of the flutter_chat_viewer project."
  echo "Make sure you have built the application first with:"
  echo -e "${BLUE}flutter build linux --release${NC}"
  exit 1
fi

# Check for required system dependencies
echo -e "${BLUE}Checking system dependencies...${NC}"
MISSING_DEPS=()

# Check for common dependencies that Flutter Linux apps need
REQUIRED_PACKAGES=("gtk3" "glib2" "libX11" "libepoxy" "desktop-file-utils")

for package in "${REQUIRED_PACKAGES[@]}"; do
  if ! rpm -q "$package" &> /dev/null; then
    MISSING_DEPS+=("$package")
  fi
done

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
  echo -e "${YELLOW}Warning: The following packages are recommended but not installed:${NC}"
  printf '%s\n' "${MISSING_DEPS[@]}"
  echo -e "${YELLOW}You can install them with:${NC}"
  echo -e "${BLUE}sudo dnf install ${MISSING_DEPS[*]}${NC}"
  echo ""
  read -p "Continue with installation anyway? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 1
  fi
fi

echo -e "${GREEN}Installing Meta Elysia...${NC}"

# Create installation directories
echo "Creating directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$DESKTOP_FILE_PATH"
mkdir -p "$ICON_DIR"
mkdir -p "/usr/local/share/icons/hicolor/scalable/apps"

# Copy bundle files
echo "Copying application files..."
cp -r "$BUNDLE_PATH/"* "$INSTALL_DIR/"

# Ensure the main executable has proper permissions
chmod +x "$INSTALL_DIR/meta_elysia"

# Create executable script
echo "Creating executable script..."
cat > "$BIN_DIR/meta-elysia" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
./meta_elysia "\$@"
EOF
chmod +x "$BIN_DIR/meta-elysia"

# Create desktop file
echo "Creating desktop entry..."
cat > "$DESKTOP_FILE_PATH/meta-elysia.desktop" << EOF
[Desktop Entry]
Name=Meta Elysia
Comment=A Flutter project for viewing and managing chat messages
Exec=$BIN_DIR/meta-elysia
Icon=meta-elysia
Terminal=false
Type=Application
Categories=Utility;Communication;Office;
StartupNotify=true
StartupWMClass=meta_elysia
MimeType=text/plain;
Keywords=chat;messages;viewer;communication;
EOF

# Copy icon if available
ICON_INSTALLED=false
if [ -f "assets/icon/app_icon.png" ]; then
  echo "Installing icon..."
  cp "assets/icon/app_icon.png" "$ICON_DIR/meta-elysia.png"
  ICON_INSTALLED=true
elif [ -f "linux/flutter/ephemeral/.plugin_symlinks/desktop_window/linux/app_icon.png" ]; then
  echo "Installing fallback icon..."
  cp "linux/flutter/ephemeral/.plugin_symlinks/desktop_window/linux/app_icon.png" "$ICON_DIR/meta-elysia.png"
  ICON_INSTALLED=true
else
  echo -e "${YELLOW}Warning: Icon file not found. No icon will be installed.${NC}"
fi

# Create uninstall script
echo "Creating uninstall script..."
cat > "$BIN_DIR/meta-elysia-uninstall" << EOF
#!/bin/bash
# Meta Elysia Uninstall Script

echo "Removing Meta Elysia..."
rm -rf "$INSTALL_DIR"
rm -f "$BIN_DIR/meta-elysia"
rm -f "$BIN_DIR/meta-elysia-uninstall"
rm -f "$DESKTOP_FILE_PATH/meta-elysia.desktop"
rm -f "$ICON_DIR/meta-elysia.png"

# Update desktop database
update-desktop-database "$DESKTOP_FILE_PATH" 2>/dev/null || true
if command -v gtk-update-icon-cache &> /dev/null; then
  gtk-update-icon-cache -f -t /usr/local/share/icons/hicolor 2>/dev/null || true
fi

echo "Meta Elysia has been uninstalled."
EOF
chmod +x "$BIN_DIR/meta-elysia-uninstall"

echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Meta Elysia has been installed to: $INSTALL_DIR"
echo "You can now run Meta Elysia by:"
echo -e "  ${BLUE}• Typing 'meta-elysia' in the terminal${NC}"
echo -e "  ${BLUE}• Finding it in your application menu under 'Communication' or 'Utilities'${NC}"
echo ""

# Update desktop database
echo "Updating desktop database..."
update-desktop-database "$DESKTOP_FILE_PATH" 2>/dev/null || true

# Update icon cache if possible
if command -v gtk-update-icon-cache &> /dev/null && [ "$ICON_INSTALLED" = true ]; then
  echo "Updating icon cache..."
  gtk-update-icon-cache -f -t /usr/local/share/icons/hicolor 2>/dev/null || true
fi

echo -e "${GREEN}Installation successful!${NC}"
echo ""
echo -e "${YELLOW}To uninstall Meta Elysia later, run:${NC}"
echo -e "${BLUE}sudo meta-elysia-uninstall${NC}"
