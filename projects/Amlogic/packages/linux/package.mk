# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2017-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="linux"
PKG_VERSION="e6b9d77"
PKG_SHA256="4d88df6d50842e4af1994faf4f2306a972b6b391dfd85f9e0c47d5b1d9fef7ff"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/AlexELEC/linux-amlogic"
PKG_URL="$PKG_SITE/archive/$PKG_VERSION.tar.gz"
PKG_SOURCE_NAME="$PKG_NAME-$LINUX-$PKG_VERSION.tar.gz"
PKG_DEPENDS_HOST="ccache:host"
PKG_DEPENDS_TARGET="toolchain cpio:host kmod:host pciutils xz:host wireless-regdb keyutils $KERNEL_EXTRA_DEPENDS_TARGET aml-dtbtools:host"
PKG_DEPENDS_INIT="toolchain"
PKG_NEED_UNPACK="$LINUX_DEPENDS"
PKG_LONGDESC="This package contains a precompiled kernel image and the modules."
PKG_IS_KERNEL_PKG="yes"
PKG_BUILD_PERF="no"

PKG_PATCH_DIRS="$LINUX"

PKG_KERNEL_CFG_FILE=$(kernel_config_path)

if [ -n "$KERNEL_LINARO_TOOLCHAIN" ]; then
  PKG_DEPENDS_HOST="$PKG_DEPENDS_HOST gcc-linaro-$KERNEL_LINARO_TOOLCHAIN:host"
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET gcc-linaro-$KERNEL_LINARO_TOOLCHAIN:host"
  HEADERS_ARCH=$TARGET_ARCH
fi

if [ "$PKG_BUILD_PERF" != "no" ] && grep -q ^CONFIG_PERF_EVENTS= $PKG_KERNEL_CFG_FILE ; then
  PKG_BUILD_PERF="yes"
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET binutils elfutils libunwind zlib openssl"
fi

if [ "$BUILD_ANDROID_BOOTIMG" = "yes" ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET mkbootimg:host"
fi

post_patch() {
  cp $PKG_KERNEL_CFG_FILE $PKG_BUILD/.config
  if [ ! "$BUILD_ANDROID_BOOTIMG" = "yes" ]; then
    sed -i -e "s|^CONFIG_INITRAMFS_SOURCE=.*$|CONFIG_INITRAMFS_SOURCE=\"$BUILD/image/initramfs.cpio\"|" $PKG_BUILD/.config
    sed -i -e '/^CONFIG_INITRAMFS_SOURCE=*./ a CONFIG_INITRAMFS_ROOT_UID=0\nCONFIG_INITRAMFS_ROOT_GID=0' $PKG_BUILD/.config
  fi

  # set default hostname based on $DISTRONAME
    sed -i -e "s|@DISTRONAME@|$DISTRONAME|g" $PKG_BUILD/.config

  # disable swap support if not enabled
  if [ ! "$SWAP_SUPPORT" = yes ]; then
    sed -i -e "s|^CONFIG_SWAP=.*$|# CONFIG_SWAP is not set|" $PKG_BUILD/.config
  fi

  # disable nfs support if not enabled
  if [ ! "$NFS_SUPPORT" = yes ]; then
    sed -i -e "s|^CONFIG_NFS_FS=.*$|# CONFIG_NFS_FS is not set|" $PKG_BUILD/.config
  fi

  # disable cifs support if not enabled
  if [ ! "$SAMBA_SUPPORT" = yes ]; then
    sed -i -e "s|^CONFIG_CIFS=.*$|# CONFIG_CIFS is not set|" $PKG_BUILD/.config
  fi

  # disable iscsi support if not enabled
  if [ ! "$ISCSI_SUPPORT" = yes ]; then
    sed -i -e "s|^CONFIG_SCSI_ISCSI_ATTRS=.*$|# CONFIG_SCSI_ISCSI_ATTRS is not set|" $PKG_BUILD/.config
    sed -i -e "s|^CONFIG_ISCSI_TCP=.*$|# CONFIG_ISCSI_TCP is not set|" $PKG_BUILD/.config
    sed -i -e "s|^CONFIG_ISCSI_BOOT_SYSFS=.*$|# CONFIG_ISCSI_BOOT_SYSFS is not set|" $PKG_BUILD/.config
    sed -i -e "s|^CONFIG_ISCSI_IBFT_FIND=.*$|# CONFIG_ISCSI_IBFT_FIND is not set|" $PKG_BUILD/.config
    sed -i -e "s|^CONFIG_ISCSI_IBFT=.*$|# CONFIG_ISCSI_IBFT is not set|" $PKG_BUILD/.config
  fi

  # install extra dts files
  for f in $PROJECT_DIR/$PROJECT/config/*-overlay.dts; do
    [ -f "$f" ] && cp -v $f $PKG_BUILD/arch/$TARGET_KERNEL_ARCH/boot/dts/overlays || true
  done
  if [ -n "$DEVICE" ]; then
    for f in $PROJECT_DIR/$PROJECT/devices/$DEVICE/config/*-overlay.dts; do
      [ -f "$f" ] && cp -v $f $PKG_BUILD/arch/$TARGET_KERNEL_ARCH/boot/dts/overlays || true
    done
  fi
}

make_host() {
  make \
    ARCH=${HEADERS_ARCH:-$TARGET_KERNEL_ARCH} \
    HOSTCC="$TOOLCHAIN/bin/host-gcc" \
    HOSTCXX="$TOOLCHAIN/bin/host-g++" \
    HOSTCFLAGS="$HOST_CFLAGS" \
    HOSTCXXFLAGS="$HOST_CXXFLAGS" \
    HOSTLDFLAGS="$HOST_LDFLAGS" \
    headers_check
}

makeinstall_host() {
  make \
    ARCH=${HEADERS_ARCH:-$TARGET_KERNEL_ARCH} \
    HOSTCC="$TOOLCHAIN/bin/host-gcc" \
    HOSTCXX="$TOOLCHAIN/bin/host-g++" \
    HOSTCFLAGS="$HOST_CFLAGS" \
    HOSTCXXFLAGS="$HOST_CXXFLAGS" \
    HOSTLDFLAGS="$HOST_LDFLAGS" \
    INSTALL_HDR_PATH=dest \
    headers_install
  mkdir -p $SYSROOT_PREFIX/usr/include
    cp -R dest/include/* $SYSROOT_PREFIX/usr/include
}

pre_make_target() {
  kernel_make oldconfig

  # regdb (backward compatability with pre-4.15 kernels)
  if grep -q ^CONFIG_CFG80211_INTERNAL_REGDB= $PKG_BUILD/.config ; then
    cp $(get_build_dir wireless-regdb)/db.txt $PKG_BUILD/net/wireless/db.txt
  fi
}

make_target() {
  kernel_make modules
  kernel_make INSTALL_MOD_PATH=$INSTALL/$(get_kernel_overlay_dir) modules_install
  rm -f $INSTALL/$(get_kernel_overlay_dir)/lib/modules/*/build
  rm -f $INSTALL/$(get_kernel_overlay_dir)/lib/modules/*/source

  if [ "$PKG_BUILD_PERF" = "yes" ] ; then
    ( cd tools/perf

      # arch specific perf build args
      case "$TARGET_ARCH" in
        aarch64)
          PERF_BUILD_ARGS="ARCH=arm64"
          ;;
        *)
          PERF_BUILD_ARGS="ARCH=$TARGET_ARCH"
          ;;
      esac

      WERROR=0 \
      NO_LIBPERL=1 \
      NO_LIBPYTHON=1 \
      NO_SLANG=1 \
      NO_GTK2=1 \
      NO_LIBNUMA=1 \
      NO_LIBAUDIT=1 \
      NO_LZMA=1 \
      NO_SDT=1 \
      LDFLAGS="$LDFLAGS -ldw -ldwfl -lebl -lelf -ldl -lz" \
      EXTRA_PERFLIBS="-lebl" \
      CROSS_COMPILE="$TARGET_PREFIX" \
      JOBS="$CONCURRENCY_MAKE_LEVEL" \
        make $PERF_BUILD_ARGS
      mkdir -p $INSTALL/usr/bin
        cp perf $INSTALL/usr/bin
    )
  fi

  ( cd $ROOT
    rm -rf $BUILD/initramfs
    $SCRIPTS/install initramfs

    if [ "$KERNEL_EXTRA_DEPENDS_TARGET" = "device-trees-amlogic" ]; then
      $SCRIPTS/clean device-trees-amlogic
      $SCRIPTS/build device-trees-amlogic
    fi
  )

  if [ "$BOOTLOADER" = "u-boot" -a -n "$KERNEL_UBOOT_EXTRA_TARGET" ]; then
    for extra_target in "$KERNEL_UBOOT_EXTRA_TARGET"; do
      kernel_make $extra_target
    done
  fi

  # the modules target is required to get a proper Module.symvers
  # file with symbols from built-in and external modules.
  # Without that it'll contain only the symbols from the kernel
  kernel_make $KERNEL_TARGET $KERNEL_MAKE_EXTRACMD modules

  if [ "$BUILD_ANDROID_BOOTIMG" = "yes" ]; then
    DTB_BLOBS=($(ls arch/$TARGET_KERNEL_ARCH/boot/dts/amlogic/*.dtb 2>/dev/null || true))
    DTB_BLOBS_COUNT="${#DTB_BLOBS[@]}"
    DTB_BLOB_OUTPUT="arch/$TARGET_KERNEL_ARCH/boot/dtb.img"
    ANDROID_BOOTIMG_SECOND="--second $DTB_BLOB_OUTPUT"

    if [ "$DTB_BLOBS_COUNT" -gt 1 ]; then
      $TOOLCHAIN/bin/dtbTool -o arch/$TARGET_KERNEL_ARCH/boot/dtb.img -p scripts/dtc/ arch/$TARGET_KERNEL_ARCH/boot/dts/amlogic/
    elif [ "$DTB_BLOBS_COUNT" -eq 1 ]; then
      cp -PR $DTB_BLOBS $DTB_BLOB_OUTPUT
    else
      ANDROID_BOOTIMG_SECOND=""
    fi

    LDFLAGS="" mkbootimg --kernel arch/$TARGET_KERNEL_ARCH/boot/$KERNEL_TARGET --ramdisk $BUILD/image/initramfs.cpio \
      $ANDROID_BOOTIMG_SECOND $ANDROID_BOOTIMG_OPTIONS --output arch/$TARGET_KERNEL_ARCH/boot/boot.img

    mv -f arch/$TARGET_KERNEL_ARCH/boot/boot.img arch/$TARGET_KERNEL_ARCH/boot/$KERNEL_TARGET

  fi
}

makeinstall_target() {
 : # none
}

make_init() {
 : # reuse make_target()
}

makeinstall_init() {
  if [ -n "$INITRAMFS_MODULES" ]; then
    mkdir -p $INSTALL/etc
    mkdir -p $INSTALL/usr/lib/modules

    for i in $INITRAMFS_MODULES; do
      module=`find .install_pkg/$(get_full_module_dir)/kernel -name $i.ko`
      if [ -n "$module" ]; then
        echo $i >> $INSTALL/etc/modules
        cp $module $INSTALL/usr/lib/modules/`basename $module`
      fi
    done
  fi

  if [ "$UVESAFB_SUPPORT" = yes ]; then
    mkdir -p $INSTALL/usr/lib/modules
      uvesafb=`find .install_pkg/$(get_full_module_dir)/kernel -name uvesafb.ko`
      cp $uvesafb $INSTALL/usr/lib/modules/`basename $uvesafb`
  fi
}

post_install() {
  mkdir -p $INSTALL/$(get_full_firmware_dir)/

  # regdb and signature is now loaded as firmware by 4.15+
    if grep -q ^CONFIG_CFG80211_REQUIRE_SIGNED_REGDB= $PKG_BUILD/.config; then
      cp $(get_build_dir wireless-regdb)/regulatory.db{,.p7s} $INSTALL/$(get_full_firmware_dir)
    fi
}
