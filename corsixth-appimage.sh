#!/bin/bash
## NOTE: Not suitable for use on Corsix-TH versions prior to v0.68.0!!
# Initialise
repo_url="https://github.com/CorsixTH/CorsixTH.git"
echo "Would you like to specify a branch or tag?"
echo "e.g. v0.69.0, or leave blank to create an appimage from master"
read -r ver

# Install packages
sudo apt-get install -y \
    build-essential cmake doxygen ffmpeg git graphviz libavfilter-dev libavformat-dev \
    libavutil-dev libavcodec-dev libavdevice-dev libcurl4-openssl-dev libfreetype-dev libflac++-dev \
    liblua5.4-dev libmikmod-dev libmpg123-dev libogg-dev libpostproc-dev libsdl2-dev libsdl2-mixer-dev \
    libswresample-dev libswscale-dev libvorbis-dev lua-filesystem luarocks lua-sec lua-socket \
    libwhereami-dev wget

## Clone repo
# Check the branch specified exists
if ! (git ls-remote --exit-code --heads "$repo_url" "$ver" || git ls-remote --exit-code --tags "$repo_url" "$ver") &> /dev/null; then
  echo "Error: '$ver' is neither a branch nor a tag in $repo_url"
  exit 1
fi

# Clone with specified version set with $ver
if [ -n "$ver" ]; then
    echo "Cloning $ver..."
    git clone $repo_url --branch "$ver"
else
# Clone from master if no version set
    echo "Cloning from master..."
    git clone $repo_url
fi

if [ "$ver" = "v0.68.0" ]; then
    echo "Copying AppImage patch..."
    wget https://raw.githubusercontent.com/CorsixTH/CorsixTH/96548ac4bc9c9e83cf7c44cb038eda6958862143/CorsixTH/Src/main.cpp -O ./CorsixTH/CorsixTH/Src/main.cpp
fi

# Go to project
cd CorsixTH || exit 1

# Compile
mkdir build
cd build || exit 1
cmake \
    -DCMAKE_INSTALL_PREFIX=../AppDir/usr \
    -DCMAKE_BUILD_TYPE=Release \
    -DSEARCH_LOCAL_DATADIRS=ON \
    -DUSE_SOURCE_DATADIRS=OFF \
    ..
make -j"$(nproc)"
make install

# Get linuxdeploy
wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
chmod +x linuxdeploy-x86_64.AppImage

# Copy some deps over manually
sudo luarocks install lpeg --lua-version 5.4
mkdir -p ../AppDir/usr/share/corsix-th/socket
cp  /usr/lib/x86_64-linux-gnu/lua/5.4/lfs.so \
    /usr/local/lib/lua/5.4/lpeg.so \
    /usr/lib/x86_64-linux-gnu/lua/5.4/ssl.so \
    /usr/lib/x86_64-linux-gnu/lua/5.4/socket/* \
../AppDir/usr/share/corsix-th/
wget https://github.com/Jacalz/fluid-soundfont/raw/master/SF3/FluidR3.sf3 -P ../AppDir/usr/share/corsix-th

# Make .appimage
./linuxdeploy-x86_64.AppImage \
    --appdir ../AppDir \
    --output appimage \
    --desktop-file ../AppDir/usr/share/applications/com.corsixth.corsixth.desktop \
    --icon-file ../AppDir/usr/share/icons/hicolor/scalable/apps/corsix-th.svg \
    --library=/usr/lib/x86_64-linux-gnu/libjack.so.0 \
    --exclude-library libaom* \
    --exclude-library libasyncns* \
    --exclude-library libblkid* \
    --exclude-library libbluray* \
    --exclude-library libbrotli* \
    --exclude-library libbsd* \
    --exclude-library libbz2* \
    --exclude-library libcairo* \
    --exclude-library libcrypto* \
    --exclude-library libcurl* \
    --exclude-library libdatrie* \
    --exclude-library libdbus* \
    --exclude-library libffi* \
    --exclude-library libgallium* \
    --exclude-library libgcrypt* \
    --exclude-library libgio* \
    --exclude-library libglib* \
    --exclude-library libgme* \
    --exclude-library libgmodule* \
    --exclude-library libgnutls* \
    --exclude-library libgobject* \
    --exclude-library libgomp* \
    --exclude-library libgraphite* \
    --exclude-library libgsm* \
    --exclude-library libgssapi* \
    --exclude-library libhogweed* \
    --exclude-library libidn* \
    --exclude-library libinstpatch* \
    --exclude-library libjpeg* \
    --exclude-library libk5crypto* \
    --exclude-library libkeyutils* \
    --exclude-library libkrb5* \
    --exclude-library liblber* \
    --exclude-library libldap* \
    --exclude-library libLLVM* \
    --exclude-library liblz4* \
    --exclude-library liblzma* \
    --exclude-library libmd* \
    --exclude-library libmfx* \
    --exclude-library libmodplug* \
    --exclude-library libmount* \
    --exclude-library libnettle* \
    --exclude-library libnghttp* \
    --exclude-library libOpenCL* \
    --exclude-library libopenjp* \
    --exclude-library libp11-kit* \
    --exclude-library libpango* \
    --exclude-library libpcre* \
    --exclude-library libpgm* \
    --exclude-library libpixman* \
    --exclude-library libpng* \
    --exclude-library libpsl* \
    --exclude-library libpulse* \
    --exclude-library libreadline* \
    --exclude-library librsvg* \
    --exclude-library librtmp* \
    --exclude-library libsasl* \
    --exclude-library libselinux* \
    --exclude-library libsnappy* \
    --exclude-library libsoxr* \
    --exclude-library libspeex* \
    --exclude-library libssl* \
    --exclude-library libsystemd* \
    --exclude-library libtasn* \
    --exclude-library libthai* \
    --exclude-library libtinfo* \
    --exclude-library libudfread* \
    --exclude-library libunistring* \
    --exclude-library libva* \
    --exclude-library libvdpau* \
    --exclude-library libvorbisenc* \
    --exclude-library libwayland* \
    --exclude-library libwebp* \
    --exclude-library libX* \
    --exclude-library libxcb* \
    --exclude-library libxkbcommon* \
    --exclude-library libxvidcore* \
    --exclude-library libzmq* \
    --exclude-library libzstd* \
    --exclude-library libzvbi*

# Rename
if [ -n "$ver" ]
then
  echo "Renaming the AppImage to the version requested."
  mv CorsixTH-x86_64.AppImage CorsixTH-"$ver"-x86_64.AppImage
fi
