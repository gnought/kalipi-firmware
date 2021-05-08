#!/bin/bash -e

export ARCH
export CROSS_COMPILE

git fetch --all
if [ -n "$1" ]; then
	FIRMWARE_COMMIT="$1"
else
	FIRMWARE_COMMIT="$(git rev-parse upstream/stable)"
fi

git checkout stable
git merge "$FIRMWARE_COMMIT" --no-edit
git checkout debian
git merge stable --no-edit -Xtheirs

DATE="$(git show -s --format=%ct "$FIRMWARE_COMMIT")"
RELEASE="$(date -d "@$DATE" -u +1.%Y%m%d)"
DEBVER="${RELEASE}-1"

KERNEL_COMMIT="$(cat extra/git_hash)"
(
	echo "Downloading linux (${KERNEL_COMMIT})..."
	cd linux
	git fetch
	git checkout "$KERNEL_COMMIT"
	if ! [ -f "../../raspberrypi-firmware_${RELEASE}.orig-linux.tar.xz" ]; then
		echo "Compressing linux..."
		git archive --format=tar --prefix=linux/ HEAD | xz -T0 > "../../raspberrypi-firmware_${RELEASE}.orig-linux.tar.xz"
	fi
)

(cd debian; ./gen_bootloader_postinst_preinst.sh)
dch "firmware as of ${FIRMWARE_COMMIT}"
dch -v "$DEBVER" -D buster --force-distribution "$(cut -f 1 -d'+' extra/uname_string)"
git commit -a -m "$RELEASE release"
git tag "$RELEASE" "$FIRMWARE_COMMIT"

gbp buildpackage -us -uc -sa -aarmhf
git clean -xdf
