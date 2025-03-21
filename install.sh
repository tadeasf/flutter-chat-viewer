#!/bin/bash

# Meta Elysia Installation Script for Arch Linux
# This script installs the Meta Elysia application bundle

set -e

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Meta Elysia Installation Script${NC}"
echo "This script will install Meta Elysia on your system."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}Please run as root or with sudo.${NC}"
  exit 1
fi

# Define paths
BUNDLE_PATH="$(pwd)/build/linux/x64/release/bundle"
INSTALL_DIR="/usr/local/lib/meta-elysia"
BIN_DIR="/usr/local/bin"
DESKTOP_FILE_PATH="/usr/local/share/applications"
ICON_DIR="/usr/local/share/icons"

# Check if bundle exists
if [ ! -d "$BUNDLE_PATH" ]; then
  echo -e "${RED}Error: Bundle directory not found at $BUNDLE_PATH${NC}"
  echo "Please run this script from the root of the flutter_chat_viewer project."
  exit 1
fi

echo -e "${GREEN}Installing Meta Elysia...${NC}"

# Create installation directories
echo "Creating directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$DESKTOP_FILE_PATH"
mkdir -p "$ICON_DIR"

# Copy bundle files
echo "Copying application files..."
cp -r "$BUNDLE_PATH/"* "$INSTALL_DIR/"

# Create executable script
echo "Creating executable script..."
cat > "$BIN_DIR/meta-elysia" << EOF
#!/bin/bash
cd $INSTALL_DIR
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
Icon=$ICON_DIR/meta-elysia.png
Terminal=false
Type=Application
Categories=Utility;Communication;
EOF

# Copy icon if available
if [ -f "assets/icon/app_icon.png" ]; then
  echo "Installing icon..."
  cp "assets/icon/app_icon.png" "$ICON_DIR/meta-elysia.png"
else
  echo -e "${YELLOW}Warning: Icon file not found. No icon will be installed.${NC}"
fi

echo -e "${GREEN}Installation complete!${NC}"
echo "You can now run Meta Elysia from your application menu or by typing 'meta-elysia' in the terminal."

# Update desktop database
echo "Updating desktop database..."
update-desktop-database "$DESKTOP_FILE_PATH" 2>/dev/null || true

echo -e "${GREEN}Done!${NC}" 