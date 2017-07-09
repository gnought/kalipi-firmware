#!/bin/bash -e
KERNEL_COMMIT="rpi-4.9.24-re4son"
FIRMWARE_COMMIT="cb0b0ad6d11ddd251327303a97ba26a43e6b5b4b"   #4.9.24
export DEBFULLNAME=Re4son
export DEBEMAIL=re4son@whitedome.com.au

copy_files (){
    destdir=headers/usr/src/linux-headers-$version
    mkdir -p "$destdir"
    mkdir -p headers/lib/modules/$version
    rsync -aHAX \
	--files-from=<(cd linux; find -name Makefile\* -o -name Kconfig\* -o -name \*.pl) linux/ $destdir/
    rsync -aHAX \
	--files-from=<(cd linux; find arch/arm/include include scripts -type f) linux/ $destdir/
    rsync -aHAX \
	--files-from=<(cd linux; find arch/arm -name module.lds -o -name Kbuild.platforms -o -name Platform) linux/ $destdir/
    rsync -aHAX \
	--files-from=<(cd linux; find `find arch/arm -name include -o -name scripts -type d` -type f) linux/ $destdir/
    rsync -aHAX \
	--files-from=<(cd linux; find arch/arm/include Module.symvers .config include scripts -type f) linux/ $destdir/
    ln -sf "/usr/src/linux-headers-$version" "headers/lib/modules/$version/build"

}

git fetch --all
##if [ -n "$1" ]; then
##	FIRMWARE_COMMIT="$1"
##else
##	FIRMWARE_COMMIT="`git rev-parse upstream/stable`"
##fi

git checkout stable
git merge $FIRMWARE_COMMIT --no-edit
##git checkout $FIRMWARE_COMMIT
cp -f ../firmware-extra/* ./extra/
git add extra --all
git commit -m "Update extra" || echo "Extra not updated"

DATE="`git show -s --format=%ct $FIRMWARE_COMMIT`"
DEBVER="`date -d @$DATE -u +Re4son.%Y%m%d-1`"
RELEASE="`date -d @$DATE -u +Re4son.%Y%m%d`"

##KERNEL_COMMIT="`cat extra/git_hash`"

echo "Downloading linux (${KERNEL_COMMIT})..."
rm linux -rf
mkdir linux -p
##wget -qO- https://github.com/raspberrypi/linux/archive/${KERNEL_COMMIT}.tar.gz | tar xz -C linux --strip-components=1
wget -qO- https://github.com/Re4son/re4son-raspberrypi-linux/archive/${KERNEL_COMMIT}.tar.gz | tar xz -C linux --strip-components=1

echo Updating files...
echo "+" > linux/.scmversion
rm -rf headers

version="`cat extra/uname_string7 | cut -d ' ' -f 3`"
(cd linux; make distclean re4son_pi2_defconfig modules_prepare)
cp extra/Module7.symvers linux/Module.symvers
copy_files

version="`cat extra/uname_string | cut -d ' ' -f 3`"
(cd linux; make distclean re4son_pi1_defconfig modules_prepare)
cp extra/Module.symvers linux/Module.symvers
copy_files
(cd linux; make distclean)

find headers -name .gitignore -delete
git add headers --all
git commit -m "Update headers" || echo "Headers not updated"
git tag ${RELEASE}-headers
rm -rf linux

git checkout debian-re4son
git merge stable --no-edit -Xtheirs

(cd debian; ./gen_bootloader_postinst_preinst.sh)
dch -v $DEBVER -D jessie --force-distribution "firmware as of ${FIRMWARE_COMMIT}"
git commit -a -m "$RELEASE release"
git tag $RELEASE $FIRMWARE_COMMIT

gbp buildpackage -us -uc -sa -S
git clean -xdf
