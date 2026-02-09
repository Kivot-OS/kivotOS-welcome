#!/bin/bash
set -e

# === CONFIG ===
PKG_NAME="kivot-welcome-bin"
PKG_VER="1.0.3"
PKG_REL="1"
ARCH="amd64"
MAINTAINER="minhmc2007 <quangminh21072010@gmail.com>"
DESC="KivotOS Welcome App (Binary)"
# =================

ROOT_DIR="$(dirname "$(realpath "$0")")/.."
cd "$ROOT_DIR"

echo "[1/5] Compiling Flutter Project..."
if [ ! -f "pubspec.yaml" ]; then
    echo "Error: pubspec.yaml not found"
    exit 1
fi

flutter pub get
flutter build linux --release

BUILD_OUTPUT="build/linux/x64/release/bundle"
if [ ! -d "$BUILD_OUTPUT" ]; then
    echo "Build output not found"
    exit 1
fi

echo "[2/5] Preparing Debian package structure..."
cd dist
rm -rf deb pkg *.deb

PKGDIR="pkg/${PKG_NAME}_${PKG_VER}-${PKG_REL}_${ARCH}"

mkdir -p \
  "$PKGDIR/DEBIAN" \
  "$PKGDIR/opt/bal-welcome" \
  "$PKGDIR/usr/bin"

echo "[3/5] Copying binaries..."
cp -r "../$BUILD_OUTPUT/"* "$PKGDIR/opt/bal-welcome/"

cd "$PKGDIR/opt/bal-welcome"

# Standardize binary name
if [ -f "bal-welcome" ]; then
    mv bal-welcome bal_welcome
elif [ -f "welcome_app" ]; then
    mv welcome_app bal_welcome
fi

if [ ! -f "bal_welcome" ]; then
    echo "CRITICAL: binary not found"
    ls -l
    exit 1
fi

chmod 755 bal_welcome

# Symlink
ln -s /opt/bal-welcome/bal_welcome "$PKGDIR/usr/bin/bal-welcome"

cd ../../..

echo "[4/5] Generating DEBIAN/control..."
cat <<EOF > "$PKGDIR/DEBIAN/control"
Package: $PKG_NAME
Version: $PKG_VER-$PKG_REL
Section: utils
Priority: optional
Architecture: $ARCH
Depends: gtk3, mpv, libappindicator3-1
Maintainer: $MAINTAINER
Description: $DESC
EOF

echo "[5/5] Building .deb package..."
dpkg-deb --build "$PKGDIR"

mv pkg/*.deb .

echo "Success!"
ls -lh *.deb
