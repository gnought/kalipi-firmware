#!/bin/bash -e
if ! [ -f ./debian/update.sh ]; then
  printf "Cannot find working directory. Run from from root directory:\n./debian/update.sh\n"
  exit 1
fi

old_version=`cat extra/uname_string | cut -f 3 -d ' ' | tr -d +`
UPSTREAM_BRANCH="master"
##UPSTREAM_BRANCH="stable"

git fetch --all
if [ -n "$1" ]; then
	FIRMWARE_COMMIT="$1"
else
	FIRMWARE_COMMIT="`git rev-parse upstream/$UPSTREAM_BRANCH`"
fi

git checkout $UPSTREAM_BRANCH
git merge $FIRMWARE_COMMIT --no-edit
piversion=`cat extra/uname_string | cut -f 3 -d ' ' | tr -d +`
version=`cat extra/uname_string | cut -f 3 -d ' ' | tr -d +`-Re4son
version6="$version+"
version7="$version-v7+"
version7l="$version-v7l+"
version8="$version-v8+"
version8l="$version-v8l+"
git checkout --orphan $piversion 
git add -A
git commit -am "Create $piversion Firmware"

DATE="`git show -s --format=%ct $FIRMWARE_COMMIT`"
DEBVER="`date -d @$DATE -u +%Y%m%dkali-1`"
RELEASE="`date -d @$DATE -u +%Y%m%dkali`"

KERNEL_COMMIT="`cat extra/git_hash`"


echo Cleaning up Raspberrypi firmware ...
rm -rf headers modules
rm -f extra/*symvers extra/*.map boot/*.img

echo Pulling back Kali customisations
git checkout $old_version debian
git checkout $old_version lib/firmware/brcm
git checkout $old_version boot/overlays/35-hat.dtbo
git checkout $old_version boot/overlays/4dpi-32.dtbo
git checkout $old_version boot/overlays/elecfreaks22-overlay.dtb
git checkout $old_version boot/overlays/elecfreaks22.dtbo
git checkout $old_version boot/overlays/hyperpixel-gpio-backlight.dtbo
git checkout $old_version boot/overlays/hyperpixel.dtbo
git checkout $old_version boot/overlays/hyperpixel4-touch.dtbo
git checkout $old_version boot/overlays/hyperpixel4.dtbo
git checkout $old_version boot/overlays/jbtek-overlay.dtb
git checkout $old_version boot/overlays/jbtek.dtbo
git checkout $old_version boot/overlays/sainsmart32-overlay.dtb
git checkout $old_version boot/overlays/sainsmart32.dtbo
git checkout $old_version boot/overlays/waveshare32b-overlay.dtb
git checkout $old_version boot/overlays/waveshare32b.dtbo
git checkout $old_version boot/overlays/waveshare35a-overlay.dtb
git checkout $old_version boot/overlays/waveshare35a.dtbo
git checkout $old_version boot/overlays/waveshare35b-overlay.dtb
git checkout $old_version boot/overlays/waveshare35b.dtbo


(cd debian; ./gen_bootloader_postinst_preinst.sh)
dch -v $DEBVER -D kali-rolling --force-distribution "firmware as of ${FIRMWARE_COMMIT}"
git commit -a -m "$RELEASE release"
git tag $RELEASE $FIRMWARE_COMMIT
