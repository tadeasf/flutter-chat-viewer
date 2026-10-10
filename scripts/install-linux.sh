#!/usr/bin/env bash
# Build a release bundle and install it for the current user:
#   ~/.local/opt/meta-elysia                      the bundle
#   ~/.local/bin/meta-elysia                      launcher
#   ~/.local/share/applications/meta-elysia.desktop  GNOME launcher entry
#   ~/.local/share/icons/hicolor/512x512/apps/meta-elysia.png
# The API key is read from .env.json ({"API_KEY": "..."}, not in git).
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env.json ] || { echo ".env.json with API_KEY is missing" >&2; exit 1; }

flutter build linux --release --dart-define-from-file=.env.json

opt="$HOME/.local/opt/meta-elysia"
bin="$HOME/.local/bin"
apps="$HOME/.local/share/applications"
icons="$HOME/.local/share/icons/hicolor/512x512/apps"
mkdir -p "$opt" "$bin" "$apps" "$icons"

rsync -a --delete build/linux/x64/release/bundle/ "$opt/"
install -m 644 assets/icon/app_icon.png "$icons/meta-elysia.png"

cat > "$bin/meta-elysia" <<SH
#!/bin/sh
exec "$opt/meta_elysia" "\$@"
SH
chmod +x "$bin/meta-elysia"

# Same file name as the old system-wide entry, so this one takes precedence.
cat > "$apps/meta-elysia.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Meta Elysia
Comment=Viewer for archived chat conversations
Exec=$bin/meta-elysia
Icon=meta-elysia
Terminal=false
Categories=Network;Chat;
Keywords=chat;messages;archive;
StartupNotify=true
StartupWMClass=meta_elysia
DESKTOP

update-desktop-database "$apps" 2>/dev/null || true
gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
echo "Installed $(git describe --always --dirty) to $opt"
