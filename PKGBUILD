# Maintainer: Your Name <your.email@example.com>
pkgname=meta-elysia
pkgver=2.3.19
pkgrel=1
pkgdesc="A Flutter project for viewing and managing chat messages"
arch=('x86_64')
url="https://github.com/yourusername/meta-elysia"
license=('custom')
depends=('gtk3' 'libglvnd')
makedepends=()
source=("local://meta-elysia")
sha256sums=('SKIP')

package() {
  # Create directories
  mkdir -p "${pkgdir}/usr/local/bin"
  mkdir -p "${pkgdir}/usr/local/lib/meta-elysia"
  mkdir -p "${pkgdir}/usr/local/share/applications"
  mkdir -p "${pkgdir}/usr/local/share/icons"

  # Copy application files
  cp -r "${srcdir}/build/linux/x64/release/bundle/"* "${pkgdir}/usr/local/lib/meta-elysia/"

  # Create executable script
  cat > "${pkgdir}/usr/local/bin/meta-elysia" << EOF
#!/bin/bash
cd /usr/local/lib/meta-elysia
./meta_elysia "\$@"
EOF
  chmod +x "${pkgdir}/usr/local/bin/meta-elysia"

  # Copy desktop file
  install -Dm644 "${srcdir}/meta-elysia.desktop" "${pkgdir}/usr/local/share/applications/meta-elysia.desktop"

  # Copy icon if available
  if [ -f "${srcdir}/assets/icon/app_icon.png" ]; then
    install -Dm644 "${srcdir}/assets/icon/app_icon.png" "${pkgdir}/usr/local/share/icons/meta-elysia.png"
  fi
} 