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
echo "[1/6] Building fake xdg-open ..."
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
echo "[2/6] Building maliit-inputcontext-gtk3 and download dependencies..."


PKGNAME="maliit-inputcontext-gtk"
VERSION="0.99.1+git20151116.72d7576"
ORIG_URL="https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/maliit-inputcontext-gtk/0.99.1+git20151116.72d7576-3build3/maliit-inputcontext-gtk_0.99.1+git20151116.72d7576.orig.tar.xz"
DEBIAN_URL="https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/maliit-inputcontext-gtk/0.99.1+git20151116.72d7576-3build3/maliit-inputcontext-gtk_0.99.1+git20151116.72d7576-3build3.debian.tar.xz"



WORKDIR_MALIIT="${BUILD_DIR}/${PKGNAME}-${VERSION}"
rm -rvf $WORKDIR_MALIIT/ || true
mkdir -p "$WORKDIR_MALIIT"
cd "$WORKDIR_MALIIT"

echo "📦 Download sources..."
wget -q "$ORIG_URL" -O "${PKGNAME}_${VERSION}.orig.tar.xz"
wget -q "$DEBIAN_URL" -O "${PKGNAME}_${VERSION}.debian.tar.xz"

echo "📂 Extract original code..."
tar -xf "${PKGNAME}_${VERSION}.orig.tar.xz"
SRC_DIR_MALIIT=$(tar -tf "${PKGNAME}_${VERSION}.orig.tar.xz" | head -1 | cut -d/ -f1)

echo "📂 Extract debian files..."
tar -xf "${PKGNAME}_${VERSION}.debian.tar.xz" -C "$SRC_DIR_MALIIT"

echo "Apply patch..."
cd ${BUILD_DIR}/$SRC_DIR_MALIIT/maliit-inputcontext-gtk-$VERSION/
patch ${BUILD_DIR}/$SRC_DIR_MALIIT/maliit-inputcontext-gtk-$VERSION/gtk-input-context/client-gtk/client-imcontext-gtk.c  ${ROOT}/patches/maliit-inputcontext-gtk/client-imcontext-gtk.c.patch
echo "${ROOT}/patches/maliit-inputcontext-gtk/client-imcontext-gtk.c.patch"

echo "Compile..."
EDITOR=true dpkg-source --commit . fix-keyboard
DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -us -uc -a arm64


# =================================================
# STEP 6: Install dependencies
# =================================================
echo "[3/6] Install dependencies..."

cd ${BUILD_DIR}
DEPENDENCIES="libhybris-utils xdotool libmaliit-glib2 libxdo3 x11-utils"

for dep in $DEPENDENCIES ; do
    apt download $dep:arm64
    mv ${dep}_*.deb ${dep}.deb
    rm -rvf "${dep}.deb_extract_chsdjksd" || true
    mkdir "${dep}.deb_extract_chsdjksd"
    dpkg-deb -x "${dep}.deb" "${dep}.deb_extract_chsdjksd"
done

URL3="https://github.com/minbrowser/min/releases/download/v1.35.2/min-1.35.2-arm64.deb"

wget -q "$URL3" -O "${BUILD_DIR}/pkg3.deb"
rm -rvf "pkg3_extract_chsdjksd" || true
mkdir "pkg3_extract_chsdjksd"
dpkg-deb -x "pkg3.deb" "pkg3_extract_chsdjksd"


# ===================================
# STEP 7: BUILD QML modules
# ===================================
echo "[4/6] Building QML modules ..."
rm -rvf ${BUILD_DIR}/download-helper
cp -r ${ROOT}/utils/download-helper/ ${BUILD_DIR}/download-helper
cd ${BUILD_DIR}/download-helper/qml-download-helper-module/
mkdir build
cd build
cmake ..
cmake --build .

rm -rvf ${BUILD_DIR}/upload-helper
cp -r ${ROOT}/utils/upload-helper/ ${BUILD_DIR}/upload-helper
cd ${BUILD_DIR}/upload-helper/qml-upload-helper-module/
mkdir build
cd build
cmake ..
cmake --build .

# ==============================
# STEP 6: Copying files
# ==============================  
echo "[5/6] Copying files..." 
mkdir -p "$INSTALL_DIR/opt/"
cp -r ${BUILD_DIR}/pkg3_extract_chsdjksd/opt/Min "$INSTALL_DIR/opt/" || true

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
cp ${ROOT}/utils/mkdir.sh "$INSTALL_DIR/utils/"
cp ${ROOT}/utils/get-scale.sh "$INSTALL_DIR/utils/"
cp ${ROOT}/utils/filedialog-deamon.sh "$INSTALL_DIR/utils/"

echo "Copying libraries dependencies..."
cd ${BUILD_DIR}
# Copie des fichiers du dossier /lib/ de chaque paquet
rm -rvf $INSTALL_DIR/lib
mkdir -p "$INSTALL_DIR/lib/aarch64-linux-gnu/gtk-3.0/3.0.0/immodules/"
for DIR in *_extract_chsdjksd; do
    if [ -d "$DIR/usr/lib/aarch64-linux-gnu/" ]; then
        cp -r "$DIR/usr/lib/aarch64-linux-gnu/"* "$INSTALL_DIR/lib/aarch64-linux-gnu/"
    fi
done

echo "Copying binaries dependencies..."
mkdir -p "$INSTALL_DIR/bin"
cp *_extract_chsdjksd/usr/bin/xdotool "$INSTALL_DIR/bin/"
cp *_extract_chsdjksd/usr/bin/getprop "$INSTALL_DIR/bin/"
cp *_extract_chsdjksd/usr/bin/xprop "$INSTALL_DIR/bin/"
cp *_extract_chsdjksd/usr/bin/xev "$INSTALL_DIR/bin/"
cp ${BUILD_DIR}/xdg-open/build/xdg-open $INSTALL_DIR/bin/


chmod +x $INSTALL_DIR/utils/sleep.sh
chmod +x $INSTALL_DIR/utils/mkdir.sh
chmod +x $INSTALL_DIR/utils/get-scale.sh
chmod +x $INSTALL_DIR/launcher.sh
chmod +x $INSTALL_DIR/opt/Min/min
chmod +x $INSTALL_DIR/opt/Min/chrome_crashpad_handler
chmod +x $INSTALL_DIR/utils/filedialog-deamon.sh

mkdir $INSTALL_DIR/utils/download-helper/
cp -r ${BUILD_DIR}/download-helper/qml $INSTALL_DIR/utils/download-helper/
mkdir -p $INSTALL_DIR/utils/download-helper/Pparent/DownloadHelper
cp ${BUILD_DIR}/download-helper/qml-download-helper-module/build/libDownloadHelperPlugin.so $INSTALL_DIR/utils/download-helper/Pparent/DownloadHelper/
cp ${BUILD_DIR}/download-helper/qml-download-helper-module/qmldir $INSTALL_DIR/utils/download-helper/Pparent/DownloadHelper/

mkdir $INSTALL_DIR/utils/upload-helper/
cp -r ${BUILD_DIR}/upload-helper/qml $INSTALL_DIR/utils/upload-helper/
mkdir -p $INSTALL_DIR/utils/upload-helper/Pparent/UploadHelper
cp ${BUILD_DIR}/upload-helper/qml-upload-helper-module/build/libUploadHelperPlugin.so $INSTALL_DIR/utils/upload-helper/Pparent/UploadHelper/
cp ${BUILD_DIR}/upload-helper/qml-upload-helper-module/qmldir $INSTALL_DIR/utils/upload-helper/Pparent/UploadHelper/

echo "Copying maliit-input-context..."
cp $WORKDIR_MALIIT/maliit-inputcontext-gtk-$VERSION/builddir/gtk3/gtk-3.0/im-maliit.so $INSTALL_DIR/lib/aarch64-linux-gnu/gtk-3.0/3.0.0/immodules/

# ========================
# STEP 7: BUILD THE CLICK PACKAGE
# ========================
echo "[6/6] Building click package..."
# click build "$INSTALL_DIR"

echo "✅ Preparation done, building the .click package."
 
