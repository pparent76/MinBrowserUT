#!/bin/bash
set -e  # Exit immediately on error
if [ "$UNCONFINED" = "true" ]; then
echo "WARNING: building unconfined!"
fi


lsb_release -a
# ========================
# PROJECT CONFIGURATION
# ========================
PROJECT_NAME="min"
INSTALL_DIR="${BUILD_DIR}/install"


  
  

# ===================================
# STEP 5: BUILD THE FAKE xdg-open
# ===================================
echo "[5/8] Building fake xdg-open ..."
cp -r ${ROOT}/utils/xdg-open/ ${BUILD_DIR}/
cd ${BUILD_DIR}/xdg-open/
mkdir -p build
cd build
cmake ..
make
mkdir -p $INSTALL_DIR/bin/

# =================================================
# STEP 6: Downloading maliit-inputcontext-gtk3
# =================================================
echo "[6/8] Building maliit-inputcontext-gtk3 and download dependencies..."

cd ${BUILD_DIR}
apt download libhybris-utils:arm64
mv libhybris-utils_*.deb libhybris-utils.deb
# URLs des paquets .deb
URL1="http://launchpadlibrarian.net/599174154/libxdo3_3.20160805.1-5_arm64.deb"
URL2="http://launchpadlibrarian.net/723291297/libmaliit-glib2_2.3.0-4build5_arm64.deb"
URL3="https://github.com/minbrowser/min/releases/download/v1.35.2/min-1.35.2-arm64.deb"
XDOTOOL_URL="http://launchpadlibrarian.net/599174155/xdotool_3.20160805.1-5_arm64.deb"

# Téléchargement des fichiers .deb
wget -q "$URL1" -O "${BUILD_DIR}/pkg1.deb"
wget -q "$URL2" -O "${BUILD_DIR}/pkg2.deb"
wget -q "$URL3" -O "${BUILD_DIR}/pkg3.deb"

wget -q "$XDOTOOL_URL" -O "${BUILD_DIR}/xdotool.deb"

# Extraction des paquets
cd "${BUILD_DIR}"
for PKG in pkg1.deb pkg2.deb pkg3.deb xdotool.deb libhybris-utils.deb; do
    rm -rvf "${PKG%.deb}_extract_chsdjksd" || true
    mkdir "${PKG%.deb}_extract_chsdjksd"
    dpkg-deb -x "$PKG" "${PKG%.deb}_extract_chsdjksd"
done

# Copie des fichiers du dossier /lib/ de chaque paquet
rm -rvf $INSTALL_DIR/lib
mkdir -p "$INSTALL_DIR/lib/aarch64-linux-gnu/gtk-3.0/3.0.0/immodules/"
for DIR in *_extract_chsdjksd; do
    if [ -d "$DIR/usr/lib/aarch64-linux-gnu/" ]; then
        cp -r "$DIR/usr/lib/aarch64-linux-gnu/"* "$INSTALL_DIR/lib/aarch64-linux-gnu/"
    fi
done

cp ${ROOT}/patches/maliit-inputcontext-gtk/immodules.cache $INSTALL_DIR/lib/aarch64-linux-gnu/gtk-3.0/3.0.0/immodules/
# Copie des binaires xdotool dans bin/
mkdir -p "$INSTALL_DIR/bin"
cp *_extract_chsdjksd/usr/bin/xdotool "$INSTALL_DIR/bin/"
cp *_extract_chsdjksd/usr/bin/getprop "$INSTALL_DIR/bin/"


PKGNAME="maliit-inputcontext-gtk"
VERSION="0.99.1+git20151116.72d7576"
ORIG_URL="https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/maliit-inputcontext-gtk/0.99.1+git20151116.72d7576-3build3/maliit-inputcontext-gtk_0.99.1+git20151116.72d7576.orig.tar.xz"
DEBIAN_URL="https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/maliit-inputcontext-gtk/0.99.1+git20151116.72d7576-3build3/maliit-inputcontext-gtk_0.99.1+git20151116.72d7576-3build3.debian.tar.xz"



WORKDIR_MALIIT="${PKGNAME}-${VERSION}"
rm -rvf $WORKDIR_MALIIT/ || true
mkdir -p "$WORKDIR_MALIIT"
cd "$WORKDIR_MALIIT"



echo "📦 Téléchargement des sources..."
wget -q "$ORIG_URL" -O "${PKGNAME}_${VERSION}.orig.tar.xz"
wget -q "$DEBIAN_URL" -O "${PKGNAME}_${VERSION}.debian.tar.xz"

echo "📂 Extraction du code source original..."
tar -xf "${PKGNAME}_${VERSION}.orig.tar.xz"
SRC_DIR_MALIIT=$(tar -tf "${PKGNAME}_${VERSION}.orig.tar.xz" | head -1 | cut -d/ -f1)

echo "📂 Extraction des fichiers Debian..."
tar -xf "${PKGNAME}_${VERSION}.debian.tar.xz" -C "$SRC_DIR_MALIIT"

cd ${BUILD_DIR}/$SRC_DIR_MALIIT/maliit-inputcontext-gtk-$VERSION/
patch ${BUILD_DIR}/$SRC_DIR_MALIIT/maliit-inputcontext-gtk-$VERSION/gtk-input-context/client-gtk/client-imcontext-gtk.c  ${ROOT}/patches/maliit-inputcontext-gtk/client-imcontext-gtk.c.patch
echo "${ROOT}/patches/maliit-inputcontext-gtk/client-imcontext-gtk.c.patch"
EDITOR=true dpkg-source --commit . fix-keyboard
DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -us -uc -a arm64

cp ${BUILD_DIR}/$WORKDIR_MALIIT/maliit-inputcontext-gtk-$VERSION/builddir/gtk3/gtk-3.0/im-maliit.so $INSTALL_DIR/lib/aarch64-linux-gnu/gtk-3.0/3.0.0/immodules/


# ==============================
# STEP 6: Copying files
# ==============================  
echo "[7/8] Copying files..." 
mkdir -p "$INSTALL_DIR/opt/"
cp -r cp ${BUILD_DIR}/pkg3_extract_chsdjksd/opt/Min "$INSTALL_DIR/opt/" || true

# Copy project files
#Copy built logos
# cp ${BUILD_DIR}/icon.png "$INSTALL_DIR/"
# cp ${BUILD_DIR}/icon-splash.png "$INSTALL_DIR/"

cp ${ROOT}/min.desktop "$INSTALL_DIR/"
cp ${ROOT}/manifest.json "$INSTALL_DIR/"

cp ${BUILD_DIR}/pkg3_extract_chsdjksd/usr/share/icons/hicolor/256x256/apps/min.png "$INSTALL_DIR/icon.png"
cp ${BUILD_DIR}/pkg3_extract_chsdjksd/usr/share/icons/hicolor/256x256/apps/min.png "$INSTALL_DIR/icon-spash.png"


    cp ${ROOT}/min.apparmor "$INSTALL_DIR/"
    cp ${ROOT}/launcher.sh "$INSTALL_DIR/"

mkdir -p "$INSTALL_DIR/utils/"
cp ${ROOT}/utils/sleep.sh "$INSTALL_DIR/utils/"
cp ${ROOT}/utils/get-scale.sh "$INSTALL_DIR/utils/"

cp ${BUILD_DIR}/xdg-open/build/xdg-open $INSTALL_DIR/bin/

chmod +x $INSTALL_DIR/utils/sleep.sh
chmod +x $INSTALL_DIR/utils/get-scale.sh
chmod +x $INSTALL_DIR/launcher.sh
chmod +x $INSTALL_DIR/opt/Min/min
chmod +x $INSTALL_DIR/opt/Min/chrome_crashpad_handler


# ========================
# STEP 7: BUILD THE CLICK PACKAGE
# ========================
echo "[8/8] Building click package..."
# click build "$INSTALL_DIR"

echo "✅ Preparation done, building the .click package."
 
