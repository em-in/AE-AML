# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2017-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="kodi"
PKG_VERSION="f7242ad"
PKG_SHA256="c029a6b71fc0eed84725b5c109b02910609d3db09b62ffd7a3f89871a6bcf048"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/xbmc/xbmc"
PKG_URL="$PKG_SITE/archive/$PKG_VERSION.tar.gz"
PKG_SOURCE_NAME="kodi-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain JsonSchemaBuilder:host TexturePacker:host Python2 zlib systemd pciutils lzo pcre swig:host libass curl fontconfig fribidi tinyxml libjpeg-turbo freetype libcdio taglib libxml2 libxslt rapidjson sqlite ffmpeg crossguid giflib libdvdnav libhdhomerun libfmt lirc libfstrcmp flatbuffers:host flatbuffers"
PKG_LONGDESC="A free and open source cross-platform media player."

PKG_PATCH_DIRS="$KODI_VENDOR"

configure_package() {
  # Single threaded LTO is very slow so rely on Kodi for parallel LTO support
  if [ "$LTO_SUPPORT" = "yes" ] && ! build_with_debug; then
    PKG_KODI_USE_LTO="-DUSE_LTO=$CONCURRENCY_MAKE_LEVEL"
  fi

  get_graphicdrivers

  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET dbus"

  if [ "$PROJECT" = "Amlogic" ]; then
    PKG_PATCH_DIRS="amlogic"
  fi

  if [ "$DISPLAYSERVER" = "x11" ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libX11 libXext libdrm libXrandr"
    KODI_XORG="-DCORE_PLATFORM_NAME=x11"
  elif [ "$DISPLAYSERVER" = "weston" ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET wayland waylandpp"
    CFLAGS="$CFLAGS -DMESA_EGL_NO_X11_HEADERS"
    CXXFLAGS="$CXXFLAGS -DMESA_EGL_NO_X11_HEADERS"
    KODI_XORG="-DCORE_PLATFORM_NAME=wayland -DWAYLAND_RENDER_SYSTEM=gles"
  fi

  if [ ! "$OPENGL" = "no" ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET $OPENGL glu"
  fi

  if [ "$OPENGLES_SUPPORT" = yes ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET $OPENGLES"
  fi

  if [ "$ALSA_SUPPORT" = yes ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET alsa-lib"
    KODI_ALSA="-DENABLE_ALSA=ON"
  else
    KODI_ALSA="-DENABLE_ALSA=OFF"
 fi

  if [ "$PULSEAUDIO_SUPPORT" = yes ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET pulseaudio"
    KODI_PULSEAUDIO="-DENABLE_PULSEAUDIO=ON"
  else
    KODI_PULSEAUDIO="-DENABLE_PULSEAUDIO=OFF"
  fi

  if [ "$ESPEAK_SUPPORT" = yes ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET espeak"
  fi

  if [ "$CEC_SUPPORT" = yes ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libcec"
    KODI_CEC="-DENABLE_CEC=ON"
  else
    KODI_CEC="-DENABLE_CEC=OFF"
  fi

  if [ "$KODI_OPTICAL_SUPPORT" = yes ]; then
    KODI_OPTICAL="-DENABLE_OPTICAL=ON"
  else
    KODI_OPTICAL="-DENABLE_OPTICAL=OFF"
  fi

  if [ "$KODI_DVDCSS_SUPPORT" = yes ]; then
    KODI_DVDCSS="-DENABLE_DVDCSS=ON \
                 -DLIBDVDCSS_URL=$SOURCES/libdvdcss/libdvdcss-$(get_pkg_version libdvdcss).tar.gz"
  else
    KODI_DVDCSS="-DENABLE_DVDCSS=OFF"
  fi

  if [ "$KODI_BLURAY_SUPPORT" = yes ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libbluray"
    KODI_BLURAY="-DENABLE_BLURAY=ON"
  else
    KODI_BLURAY="-DENABLE_BLURAY=OFF"
  fi

  if [ "$AVAHI_DAEMON" = yes ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET avahi nss-mdns"
    KODI_AVAHI="-DENABLE_AVAHI=ON"
  else
    KODI_AVAHI="-DENABLE_AVAHI=OFF"
  fi

  case "$KODI_MYSQL_SUPPORT" in
    mysql)   PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET mysql"
             KODI_MYSQL="-DENABLE_MYSQLCLIENT=ON -DENABLE_MARIADBCLIENT=OFF"
             ;;
    mariadb) PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET mariadb-connector-c"
             KODI_MYSQL="-DENABLE_MARIADBCLIENT=ON -DENABLE_MYSQLCLIENT=OFF"
             ;;
    *)       KODI_MYSQL="-DENABLE_MYSQLCLIENT=OFF -DENABLE_MARIADBCLIENT=OFF"
  esac

  if [ "$KODI_AIRPLAY_SUPPORT" = yes ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libplist"
    KODI_AIRPLAY="-DENABLE_PLIST=ON"
  else
    KODI_AIRPLAY="-DENABLE_PLIST=OFF"
  fi

  if [ "$KODI_AIRTUNES_SUPPORT" = yes ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libshairplay"
    KODI_AIRTUNES="-DENABLE_AIRTUNES=ON"
  else
    KODI_AIRTUNES="-DENABLE_AIRTUNES=OFF"
  fi

  if [ "$KODI_NFS_SUPPORT" = yes ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libnfs"
    KODI_NFS="-DENABLE_NFS=ON"
  else
    KODI_NFS="-DENABLE_NFS=OFF"
  fi

  if [ "$KODI_SAMBA_SUPPORT" = yes ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET samba"
  fi

  if [ "$KODI_WEBSERVER_SUPPORT" = yes ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libmicrohttpd"
  fi

  if [ "$KODI_UPNP_SUPPORT" = yes ]; then
    KODI_UPNP="-DENABLE_UPNP=ON"
  else
    KODI_UPNP="-DENABLE_UPNP=OFF"
  fi

  if target_has_feature neon; then
    KODI_NEON="-DENABLE_NEON=ON"
  else
    KODI_NEON="-DENABLE_NEON=OFF"
  fi

  if [ "$VDPAU_SUPPORT" = "yes" -a "$DISPLAYSERVER" = "x11" ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libvdpau"
    KODI_VDPAU="-DENABLE_VDPAU=ON"
  else
    KODI_VDPAU="-DENABLE_VDPAU=OFF"
  fi

  if [ "$VAAPI_SUPPORT" = yes ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libva"
    KODI_VAAPI="-DENABLE_VAAPI=ON"
  else
    KODI_VAAPI="-DENABLE_VAAPI=OFF"
  fi

  if [ "$TARGET_ARCH" = "x86_64" ]; then
    KODI_ARCH="-DWITH_CPU=$TARGET_ARCH"
  else
    KODI_ARCH="-DWITH_ARCH=$TARGET_ARCH"
  fi

  if [ "$DEVICE" = "Slice" -o "$DEVICE" = "Slice3" ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET led_tools"
  fi

  if [ ! "$KODIPLAYER_DRIVER" = default ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET $KODIPLAYER_DRIVER libinput libxkbcommon"
    if [ "$KODIPLAYER_DRIVER" = bcm2835-driver ]; then
      KODI_PLAYER="-DCORE_PLATFORM_NAME=rbpi"
    elif [ "$KODIPLAYER_DRIVER" = mesa -o "$KODIPLAYER_DRIVER" = rkmpp ]; then
      KODI_PLAYER="-DCORE_PLATFORM_NAME=gbm -DGBM_RENDER_SYSTEM=gles"
      CFLAGS="$CFLAGS -DMESA_EGL_NO_X11_HEADERS"
      CXXFLAGS="$CXXFLAGS -DMESA_EGL_NO_X11_HEADERS"
    elif [ "$KODIPLAYER_DRIVER" = libamcodec ]; then
      KODI_PLAYER="-DCORE_PLATFORM_NAME=aml"
    fi
  fi

  KODI_LIBDVD="$KODI_DVDCSS \
               -DLIBDVDNAV_URL=$SOURCES/libdvdnav/libdvdnav-$(get_pkg_version libdvdnav).tar.gz \
               -DLIBDVDREAD_URL=$SOURCES/libdvdread/libdvdread-$(get_pkg_version libdvdread).tar.gz"

  PKG_CMAKE_OPTS_TARGET="-DNATIVEPREFIX=$TOOLCHAIN \
                         -DWITH_TEXTUREPACKER=$TOOLCHAIN/bin/TexturePacker \
                         -DWITH_JSONSCHEMABUILDER=$TOOLCHAIN/bin/JsonSchemaBuilder \
                         -DDEPENDS_PATH=$PKG_BUILD/depends \
                         -DPYTHON_EXECUTABLE=$TOOLCHAIN/bin/$PKG_PYTHON_VERSION \
                         -DPYTHON_INCLUDE_DIRS=$SYSROOT_PREFIX/usr/include/$PKG_PYTHON_VERSION \
                         -DGIT_VERSION=$PKG_VERSION \
                         -DWITH_FFMPEG=$(get_build_dir ffmpeg) \
                         -DENABLE_INTERNAL_FFMPEG=OFF \
                         -DFFMPEG_INCLUDE_DIRS=$SYSROOT_PREFIX/usr \
                         -DENABLE_INTERNAL_CROSSGUID=OFF \
                         -DENABLE_UDEV=ON \
                         -DENABLE_DBUS=ON \
                         -DENABLE_XSLT=ON \
                         -DENABLE_CCACHE=ON \
                         -DENABLE_LIRCCLIENT=ON \
                         -DENABLE_EVENTCLIENTS=ON \
                         -DENABLE_LDGOLD=ON \
                         -DENABLE_DEBUGFISSION=OFF \
                         -DENABLE_APP_AUTONAME=OFF \
                         -DENABLE_INTERNAL_FLATBUFFERS=OFF \
                         $PKG_KODI_USE_LTO \
                         $KODI_ARCH \
                         $KODI_NEON \
                         $KODI_VDPAU \
                         $KODI_VAAPI \
                         $KODI_CEC \
                         $KODI_XORG \
                         $KODI_SAMBA \
                         $KODI_NFS \
                         $KODI_LIBDVD \
                         $KODI_AVAHI \
                         $KODI_UPNP \
                         $KODI_MYSQL \
                         $KODI_AIRPLAY \
                         $KODI_AIRTUNES \
                         $KODI_OPTICAL \
                         $KODI_BLURAY \
                         $KODI_PLAYER"
}

pre_configure_target() {
  export LIBS="$LIBS -lncurses"
}

post_makeinstall_target() {
  rm -rf $INSTALL/usr/bin/kodi
  rm -rf $INSTALL/usr/bin/kodi-standalone
  rm -rf $INSTALL/usr/bin/xbmc
  rm -rf $INSTALL/usr/bin/xbmc-standalone
  rm -rf $INSTALL/usr/share/kodi/cmake
  rm -rf $INSTALL/usr/share/applications
  rm -rf $INSTALL/usr/share/icons
  rm -rf $INSTALL/usr/share/pixmaps
  rm -rf $INSTALL/usr/share/kodi/addons/skin.estouchy
  rm -rf $INSTALL/usr/share/kodi/addons/skin.estuary
  rm -rf $INSTALL/usr/share/kodi/addons/service.xbmc.versioncheck
  rm -rf $INSTALL/usr/share/kodi/addons/visualization.vortex
  rm -rf $INSTALL/usr/share/xsessions

  mkdir -p $INSTALL/usr/lib/kodi
    cp $PKG_DIR/scripts/kodi-config $INSTALL/usr/lib/kodi
    cp $PKG_DIR/scripts/kodi-safe-mode $INSTALL/usr/lib/kodi
    cp $PKG_DIR/scripts/kodi.sh $INSTALL/usr/lib/kodi

    # Configure safe mode triggers - default 3 restarts within 600 seconds/10 minutes
    sed -e "s|@KODI_MAX_RESTARTS@|${KODI_MAX_RESTARTS:-3}|g" \
        -e "s|@KODI_MAX_SECONDS@|${KODI_MAX_SECONDS:-600}|g" \
        -i $INSTALL/usr/lib/kodi/kodi.sh

  mkdir -p $INSTALL/usr/sbin
    cp $PKG_DIR/scripts/service-addon-wrapper $INSTALL/usr/sbin

  mkdir -p $INSTALL/usr/bin
    cp $PKG_DIR/scripts/kodi-remote $INSTALL/usr/bin
    cp $PKG_DIR/scripts/setwakeup.sh $INSTALL/usr/bin

  mkdir -p $INSTALL/usr/share/kodi/addons
    cp -R $PKG_DIR/config/os.alexelec $INSTALL/usr/share/kodi/addons
    sed -e "s|@OS_VERSION@|$OS_VERSION|g" -i $INSTALL/usr/share/kodi/addons/os.alexelec/addon.xml
    cp -R $PKG_DIR/config/repository.alexelec $INSTALL/usr/share/kodi/addons/$ADDON_REPO_ID
    sed -e "s|@ADDON_URL@|$ADDON_URL|g" -i $INSTALL/usr/share/kodi/addons/$ADDON_REPO_ID/addon.xml
    sed -e "s|@ADDON_REPO_ID@|$ADDON_REPO_ID|g" -i $INSTALL/usr/share/kodi/addons/$ADDON_REPO_ID/addon.xml
    sed -e "s|@ADDON_REPO_NAME@|$ADDON_REPO_NAME|g" -i $INSTALL/usr/share/kodi/addons/$ADDON_REPO_ID/addon.xml
    sed -e "s|@ADDON_REPO_VERSION@|$ADDON_REPO_VERSION|g" -i $INSTALL/usr/share/kodi/addons/$ADDON_REPO_ID/addon.xml
    cp -R $PKG_BUILD/addons/resource.language.ru_ru $INSTALL/usr/share/kodi/addons
    cp -R $PKG_BUILD/addons/script.key.layout $INSTALL/usr/share/kodi/addons

  mkdir -p $INSTALL/usr/share/kodi/config
  mkdir -p $INSTALL/usr/share/kodi/system/settings

  $PKG_DIR/scripts/xml_merge.py $PKG_DIR/config/guisettings.xml \
                                $PROJECT_DIR/$PROJECT/kodi/guisettings.xml \
                                $PROJECT_DIR/$PROJECT/devices/$DEVICE/kodi/guisettings.xml \
                                > $INSTALL/usr/share/kodi/config/guisettings.xml

  $PKG_DIR/scripts/xml_merge.py $PKG_DIR/config/sources.xml \
                                $PROJECT_DIR/$PROJECT/kodi/sources.xml \
                                $PROJECT_DIR/$PROJECT/devices/$DEVICE/kodi/sources.xml \
                                > $INSTALL/usr/share/kodi/config/sources.xml

  $PKG_DIR/scripts/xml_merge.py $PKG_DIR/config/advancedsettings.xml \
                                $PROJECT_DIR/$PROJECT/kodi/advancedsettings.xml \
                                $PROJECT_DIR/$PROJECT/devices/$DEVICE/kodi/advancedsettings.xml \
                                > $INSTALL/usr/share/kodi/system/advancedsettings.xml

  $PKG_DIR/scripts/xml_merge.py $PKG_DIR/config/appliance.xml \
                                $PROJECT_DIR/$PROJECT/kodi/appliance.xml \
                                $PROJECT_DIR/$PROJECT/devices/$DEVICE/kodi/appliance.xml \
                                > $INSTALL/usr/share/kodi/system/settings/appliance.xml

  # update addon manifest
  ADDON_MANIFEST=$INSTALL/usr/share/kodi/system/addon-manifest.xml
  xmlstarlet ed -L -d "/addons/addon[text()='service.xbmc.versioncheck']" $ADDON_MANIFEST
  xmlstarlet ed -L -d "/addons/addon[text()='skin.estouchy']" $ADDON_MANIFEST
  xmlstarlet ed -L --subnode "/addons" -t elem -n "addon" -v "os.alexelec" $ADDON_MANIFEST
  xmlstarlet ed -L --subnode "/addons" -t elem -n "addon" -v "$ADDON_REPO_ID" $ADDON_MANIFEST
  xmlstarlet ed -L --subnode "/addons" -t elem -n "addon" -v "service.alexelec.settings" $ADDON_MANIFEST
  xmlstarlet ed -L --subnode "/addons" -t elem -n "addon" -v "resource.language.ru_ru" $ADDON_MANIFEST
  xmlstarlet ed -L --subnode "/addons" -t elem -n "addon" -v "script.key.layout" $ADDON_MANIFEST

  if [ "$DRIVER_ADDONS_SUPPORT" = "yes" ]; then
    xmlstarlet ed -L --subnode "/addons" -t elem -n "addon" -v "script.program.driverselect" $ADDON_MANIFEST
  fi

  if [ "$DEVICE" = "Slice" -o "$DEVICE" = "Slice3" ]; then
    xmlstarlet ed -L --subnode "/addons" -t elem -n "addon" -v "service.slice" $ADDON_MANIFEST
  fi

  if [ -d $ROOT/addons ]; then
    mkdir -p $INSTALL/usr/share/kodi/addons
    for i in `ls $ROOT/addons | grep zip`
    do
      unzip $ROOT/addons/$i -d $INSTALL/usr/share/kodi/addons
      xmlstarlet ed -L --subnode "/addons" -t elem -n "addon" -v "`unzip -p $ROOT/addons/$i */addon.xml | awk -F= '/addon\ id=/ { print $2 }' | awk -F'"' '{ print $2 }'`" $ADDON_MANIFEST
    done
  fi

  # install addons config AE
  if [ -d $PKG_DIR/config/weather.gismeteo ]; then
      cp -R $PKG_DIR/config/weather.gismeteo $INSTALL/usr/share/kodi/config
  fi

  if [ -d $PKG_DIR/config/script.skinshortcuts ]; then
      cp -R $PKG_DIR/config/script.skinshortcuts $INSTALL/usr/share/kodi/config
  fi

  if [ -d $PKG_DIR/config/skin.aeon.nox.silvo.ae ]; then
      cp -R $PKG_DIR/config/skin.aeon.nox.silvo.ae $INSTALL/usr/share/kodi/config
  fi

  if [ -d $PKG_DIR/config/skin.arctic.zephyr.ae ]; then
      cp -R $PKG_DIR/config/skin.arctic.zephyr.ae $INSTALL/usr/share/kodi/config
  fi

  # more binaddons cross compile badness meh
  sed -e "s:INCLUDE_DIR /usr/include/kodi:INCLUDE_DIR $SYSROOT_PREFIX/usr/include/kodi:g" \
      -e "s:CMAKE_MODULE_PATH /usr/lib/kodi /usr/share/kodi/cmake:CMAKE_MODULE_PATH $SYSROOT_PREFIX/usr/share/kodi/cmake:g" \
      -i $SYSROOT_PREFIX/usr/share/kodi/cmake/KodiConfig.cmake

  if [ "$KODI_EXTRA_FONTS" = yes ]; then
    mkdir -p $INSTALL/usr/share/kodi/media/Fonts
      cp $PKG_DIR/fonts/*.ttf $INSTALL/usr/share/kodi/media/Fonts
  fi

  debug_strip $INSTALL/usr/lib/kodi/kodi.bin
}

post_install() {
  enable_service kodi.target
  enable_service kodi-autostart.service
  enable_service kodi-cleanlogs.service
  enable_service kodi-halt.service
  enable_service kodi-poweroff.service
  enable_service kodi-reboot.service
  enable_service kodi-waitonnetwork.service
  enable_service kodi.service
  enable_service kodi-lirc-suspend.service
  enable_service kodi-cleanpackagecache.service
}
