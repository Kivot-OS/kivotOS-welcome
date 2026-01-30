#!/bin/bash
set -e

# === CONFIG ===
PKG_NAME="bal-welcome-bin"
PKG_VER="1.0.0"
PKG_REL="1"
# ==============

# 1. Navigate to Project Root
ROOT_DIR="$(dirname "$(realpath "$0")")/.."
cd "$ROOT_DIR"

echo "[1/4] Compiling Flutter Project..."
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found in $(pwd)"
    exit 1
fi

flutter pub get
flutter build linux --release

# Verify build success
BUILD_OUTPUT="build/linux/x64/release/bundle"
if [ ! -d "$BUILD_OUTPUT" ]; then
    echo "❌ Error: Build output not found at $BUILD_OUTPUT"
    exit 1
fi

echo "[2/4] Preparing dist directory..."
cd dist

# Clean up previous runs
rm -rf src/ pkg/ *.pkg.tar.zst src_bundle/ PKGBUILD

# Create staging directory
mkdir -p src/bundle

# Copy EVERYTHING (binary, lib/, data/) to staging
echo "-> Copying binaries and libs to staging..."
cp -r "../$BUILD_OUTPUT/"* src/bundle/

echo "[3/4] Generating PKGBUILD..."
cat <<EOF > PKGBUILD
# Maintainer: minhmc2007 <quangminh21072010@gmail.com>
pkgname=$PKG_NAME
pkgver=$PKG_VER
pkgrel=$PKG_REL
pkgdesc="Blue Archive Linux Welcome App (Binary)"
arch=('x86_64')
url="https://github.com/minhmc2007/bal-welcome"
license=('GPL3')
provides=('bal-welcome')
conflicts=('bal-welcome')
depends=('gtk3' 'mpv' 'libappindicator-gtk3')
options=('!strip')

package() {
    local install_dir="\$pkgdir/opt/bal-welcome"

    install -d "\$install_dir"
    install -d "\$pkgdir/usr/bin"

    # 1. Copy ALL files (binary, lib/, data/) preserving attributes
    # The 'lib/' folder is crucial for Flutter apps!
    cp -a "\$srcdir/bundle/"* "\$install_dir/"

    # 2. Rename 'welcome_app' (default Flutter name) to 'bal_welcome'
    if [ -f "\$install_dir/welcome_app" ]; then
        mv "\$install_dir/welcome_app" "\$install_dir/bal_welcome"
    fi

    # 3. Create symlink
    ln -s "/opt/bal-welcome/bal_welcome" "\$pkgdir/usr/bin/bal-welcome"

    # 4. Set permissions
    chmod 755 "\$install_dir/bal_welcome"
}
EOF

echo "[4/4] Building Arch Package..."
# -e: Do not extract (we manually staged files)
# -f: Overwrite existing package
makepkg -ef

echo "[5/5] Cleaning up intermediate files..."
# Remove the source staging, the unzipped package folder, and the PKGBUILD
rm -rf src/ pkg/ PKGBUILD src_bundle/

echo "✅ Success! Final package located in dist/"
ls -lh *.pkg.tar.zst
