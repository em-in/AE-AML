# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2011-present AlexELEC (http://alexelec.in.ua)

PKG_NAME="device-trees-amlogic"
PKG_VERSION="97c2f60"
PKG_SHA256="2b39d4977151c7e2d2254c2e798ec342d07c917699ea0584b59c31be8c8ff1ca"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/AlexELEC/device-trees-amlogic"
PKG_URL="$PKG_SITE/archive/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Device trees for Amlogic devices."
PKG_IS_KERNEL_PKG="yes"
PKG_TOOLCHAIN="manual"

make_target() {
  # Enter kernel directory
  pushd $BUILD/linux-$(kernel_version) > /dev/null

  # Device trees already present in kernel tree we want to include
  EXTRA_TREES=( \
                gxbb_p201 gxl_p212_1g gxl_p212_2g gxl_p281_1g \
                gxm_q200_2g gxm_q201_1g gxm_q201_2g gxl_p231_1g_m8s_dvb\
	      )

  # Add trees to the list
  for f in ${EXTRA_TREES[@]}; do
    DTB_LIST="$DTB_LIST $f.dtb"
  done

  # Copy all device trees to kernel source folder and create a list
  cp -f $PKG_BUILD/*.dts* arch/$TARGET_KERNEL_ARCH/boot/dts/amlogic/
  for f in $PKG_BUILD/*.dts; do
    DTB_NAME="$(basename $f .dts).dtb"
    DTB_LIST="$DTB_LIST $DTB_NAME"
  done

  # Compile device trees
  kernel_make $DTB_LIST
  cp arch/$TARGET_KERNEL_ARCH/boot/dts/amlogic/*.dtb $PKG_BUILD

  popd > /dev/null
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/share/bootloader/device_trees
  cp -a $PKG_BUILD/*.dtb $INSTALL/usr/share/bootloader/device_trees
}
