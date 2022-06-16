#!/bin/sh

if ! [ -d ../boot ]; then
  printf "Can't find boot dir. Run from debian subdir\n"
  exit 1
fi

version=`cat ../extra/uname_string | cut -f 3 -d ' ' | tr -d +`-Re4son

#     create kalipi-kernel preinst/postinst scripts
##    headers

###   kalipi-kernel.postinst
printf "#!/bin/sh\n" > kalipi-kernel.postinst
##printf 'for file in kernel.img \\\n            kernel7.img \\\n            kernel7l.img \\\n            kernel8-alt.img \\\n            kernel8l-alt.img \\\n            config-${version}+ \\\n            config-${version}-v7+ \\\n            config-${version}-v7l+ \\\n            config-${version}-v8+ \\\n            config-${version}-v8l+ \\\n' >> kalipi-kernel.postinst
printf 'for file in kernel.img \\\n            kernel7.img \\\n            kernel7l.img \\\n            kernel8-alt.img \\\n            kernel8l-alt.img \\\n            config-%s+ \\\n            config-%s-v7+ \\\n            config-%s-v7l+ \\\n            config-%s-v8+ \\\n            config-%s-v8l+ \\\n' "${version}" "${version}" "${version}" "${version}" "${version}" >> kalipi-kernel.postinst

###   kalipi-kernel.preinst
cat <<EOF > kalipi-kernel.preinst
#!/bin/sh

if ! grep -q boot /proc/mounts; then
    mount /boot
fi

mkdir -p /usr/share/rpikernelhack/overlays
mkdir -p /boot/overlays
# https://git.dpkg.org/cgit/dpkg/dpkg.git/commit/?id=599e3c1a9f3be8687c00b681f107e7b98bb454ae
# We have to add "--no-rename" explicitly for dpkg versions >= 1.19.1
# But this will fail for versions < 1.19.1 so we detect the version to choose the right command line below
# to be compatible with older versions as well as Raspbian and other distros
VER=\$(dpkg-query -f='\${Version}' --show dpkg)
MINVER=1.19.1
for file in kernel.img \\
            kernel7.img \\
            kernel7l.img \\
            kernel8-alt.img \\
            kernel8l-alt.img \\
            config-${version}+ \\
            config-${version}-v7+ \\
            config-${version}-v7l+ \\
            config-${version}-v8+ \\
            config-${version}-v8l+ \\
EOF


##    content

for FN in ../boot/*.dtb ../boot/COPYING.linux ../boot/overlays/*; do
  if ! [ -d "\$FN" ]; then
    FN=${FN#../boot/}
    printf "            $FN" >> kalipi-kernel.preinst
    printf ' \\\n' >> kalipi-kernel.preinst
    printf "            $FN" >> kalipi-kernel.postinst
    printf ' \\\n' >> kalipi-kernel.postinst
  fi
done


##    footer
###   kalipi-kernel.preinst
cat <<EOF >> kalipi-kernel.preinst
            ;do
    if \$(dpkg --compare-versions \$VER ge \$MINVER); then
        dpkg-divert --package rpikernelhack --divert /usr/share/rpikernelhack/\$file --no-rename /boot/\$file
    else
	dpkg-divert --package rpikernelhack --divert /usr/share/rpikernelhack/\$file /boot/\$file
    fi
done
if [ -f /etc/default/kalipi-kernel ]; then
  . /etc/default/kalipi-kernel
  INITRD=\${INITRD:-"No"}
  export INITRD
  RPI_INITRD=\${RPI_INITRD:-"No"}
  export RPI_INITRD
fi
if [ -d "/etc/kernel/preinst.d" ]; then
  run-parts -v --report --exit-on-error --arg=${version}+ --arg=/boot/kernel.img /etc/kernel/preinst.d
  run-parts -v --report --exit-on-error --arg=${version}-v7+ --arg=/boot/kernel7.img /etc/kernel/preinst.d
  run-parts -v --report --exit-on-error --arg=${version}-v7l+ --arg=/boot/kernel7l.img /etc/kernel/preinst.d
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8-alt.img /etc/kernel/preinst.d
  run-parts -v --report --exit-on-error --arg=${version}-v8l+ --arg=/boot/kernel8l-alt.img /etc/kernel/preinst.d
fi
if [ -d "/etc/kernel/preinst.d/${version}+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}+ --arg=/boot/kernel.img /etc/kernel/preinst.d/${version}+
fi
if [ -d "/etc/kernel/preinst.d/${version}-v7+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v7+ --arg=/boot/kernel7.img /etc/kernel/preinst.d/${version}-v7+
fi
if [ -d "/etc/kernel/preinst.d/${version}-v7l+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v7l+ --arg=/boot/kernel7l.img /etc/kernel/preinst.d/${version}-v7l+
fi
if [ -d "/etc/kernel/preinst.d/${version}-v8+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8-alt.img /etc/kernel/preinst.d/${version}-v8+
fi
if [ -d "/etc/kernel/preinst.d/${version}-v8l+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v8l+ --arg=/boot/kernel8l-alt.img /etc/kernel/preinst.d/${version}-v8l+
fi
EOF

###   kalipi-kernel.postinst
cat <<EOF >> kalipi-kernel.postinst
            ; do
    if [ -f /usr/share/rpikernelhack/\$file ]; then
        rm -f /boot/\$file
        dpkg-divert --package rpikernelhack --rename --remove /boot/\$file
        sync
    fi
done
if [ -f /etc/default/kalipi-kernel ]; then
  . /etc/default/kalipi-kernel
  INITRD=\${INITRD:-"No"}
  export INITRD
  RPI_INITRD=\${RPI_INITRD:-"No"}
  export RPI_INITRD
fi
if [ -d "/etc/kernel/postinst.d" ]; then
  run-parts -v --report --exit-on-error --arg=${version}+ --arg=/boot/kernel.img /etc/kernel/postinst.d
  run-parts -v --report --exit-on-error --arg=${version}-v7+ --arg=/boot/kernel7.img /etc/kernel/postinst.d
  run-parts -v --report --exit-on-error --arg=${version}-v7l+ --arg=/boot/kernel7l.img /etc/kernel/postinst.d
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8-alt.img /etc/kernel/postinst.d
  run-parts -v --report --exit-on-error --arg=${version}-v8l+ --arg=/boot/kernel8l-alt.img /etc/kernel/postinst.d
fi
if [ -d "/etc/kernel/postinst.d/${version}+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}+ --arg=/boot/kernel.img /etc/kernel/postinst.d/${version}+
fi
if [ -d "/etc/kernel/postinst.d/${version}-v7+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v7+ --arg=/boot/kernel7.img /etc/kernel/postinst.d/${version}-v7+
fi
if [ -d "/etc/kernel/postinst.d/${version}-v7l+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v7l+ --arg=/boot/kernel7l.img /etc/kernel/postinst.d/${version}-v7l+
fi
if [ -d "/etc/kernel/postinst.d/${version}-v8+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8-alt.img /etc/kernel/postinst.d/${version}-v8+
fi
if [ -d "/etc/kernel/postinst.d/${version}-v8l+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v8l+ --arg=/boot/kernel8l-alt.img /etc/kernel/postinst.d/${version}-v8l+
fi
EOF

#     Create all other installation scripts
printf "#DEBHELPER#\n" >> kalipi-kernel.postinst
printf "#DEBHELPER#\n" >> kalipi-kernel.preinst

printf "#!/bin/sh -e\n" > kalipi-bootloader.postinst
printf 'for file in \\\n' >> kalipi-bootloader.postinst
printf "#!/bin/sh -e\n" > kalipi-bootloader.preinst

printf "mkdir -p /usr/share/rpikernelhack\n" >> kalipi-bootloader.preinst

cat <<EOF >> kalipi-bootloader.preinst
if [ -f "/boot/recovery.elf" ]; then
  echo "/boot appears to be NOOBS recovery partition. Applying fix."
  rootnum=\`cat /proc/cmdline | sed -n 's|.*root=/dev/mmcblk0p\([0-9]*\).*|\1|p'\`
  if [ ! "\$rootnum" ];then
    echo "Could not determine root partition"
    exit 1
  fi
  if ! grep -qE "/dev/mmcblk0p1\s+/boot" /etc/fstab; then
    echo "Unexpected fstab entry"
    exit 1
  fi
  boot="/dev/mmcblk0p\$((rootnum-1))"
  root="/dev/mmcblk0p\${rootnum}"
  sed /etc/fstab -i -e "s|^.* / |\${root}  / |"
  sed /etc/fstab -i -e "s|^.* /boot |\${boot}  /boot |"
  umount /boot
  if [ \$? -ne 0 ]; then
    echo "Failed to umount /boot. Remount manually and run sudo apt-get install -f."
    exit 1
  else
    mount /boot
  fi
fi
# https://git.dpkg.org/cgit/dpkg/dpkg.git/commit/?id=599e3c1a9f3be8687c00b681f107e7b98bb454ae
# We have to add "--no-rename" explicitly for dpkg versions >= 1.19.1
# But this will fail for versions < 1.19.1 so we detect the version to choose the right command line below
# to be compatible with older versions as well as Raspbian and other distros
VER=\$(dpkg-query -f='\${Version}' --show dpkg)
MINVER=1.19.1
for file in \\
EOF

for FN in ../boot/*.elf ../boot/*.dat ../boot/*.bin ../boot/LICENCE.broadcom; do
  if ! [ -d "\$FN" ]; then
    FN=${FN#../boot/}
    printf "            $FN" >> kalipi-bootloader.preinst
    printf ' \\\n' >> kalipi-bootloader.preinst
    printf "            $FN" >> kalipi-bootloader.postinst
    printf ' \\\n' >> kalipi-bootloader.postinst
  fi
done

cat <<EOF >> kalipi-bootloader.preinst
            ;do
    if \$(dpkg --compare-versions \$VER ge \$MINVER); then
        dpkg-divert --package rpikernelhack --divert /usr/share/rpikernelhack/\$file --no-rename /boot/\$file
    else
	dpkg-divert --package rpikernelhack --divert /usr/share/rpikernelhack/\$file --rename /boot/\$file
    fi
done
#DEBHELPER#
EOF

cat <<EOF >> kalipi-bootloader.postinst
            ; do
    rm -f /boot/\$file
    dpkg-divert --package rpikernelhack --remove --rename /boot/\$file
    sync
done
#DEBHELPER#
EOF




printf "#!/bin/sh\n" > kalipi-kernel.prerm
printf "#!/bin/sh\n" > kalipi-kernel.postrm
printf "#!/bin/sh\n" > kalipi-kernel-headers.postinst

cat <<EOF >> kalipi-kernel.prerm
if [ -f /etc/default/kalipi-kernel ]; then
  . /etc/default/kalipi-kernel
  INITRD=\${INITRD:-"No"}
  export INITRD
  RPI_INITRD=\${RPI_INITRD:-"No"}
  export RPI_INITRD
fi
if [ -d "/etc/kernel/prerm.d" ]; then
  run-parts -v --report --exit-on-error --arg=${version}+ --arg=/boot/kernel.img /etc/kernel/prerm.d
  run-parts -v --report --exit-on-error --arg=${version}-v7+ --arg=/boot/kernel7.img /etc/kernel/prerm.d
  run-parts -v --report --exit-on-error --arg=${version}-v7l+ --arg=/boot/kernel7l.img /etc/kernel/prerm.d
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8-alt.img /etc/kernel/prerm.d
  run-parts -v --report --exit-on-error --arg=${version}-v8l+ --arg=/boot/kernel8l-alt.img /etc/kernel/prerm.d
fi
if [ -d "/etc/kernel/prerm.d/${version}+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}+ --arg=/boot/kernel.img /etc/kernel/prerm.d/${version}+
fi
if [ -d "/etc/kernel/prerm.d/${version}-v7+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v7+ --arg=/boot/kernel7.img /etc/kernel/prerm.d/${version}-v7+
fi
if [ -d "/etc/kernel/prerm.d/${version}-v7l+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v7l+ --arg=/boot/kernel7l.img /etc/kernel/prerm.d/${version}-v7l+
fi
if [ -d "/etc/kernel/prerm.d/${version}-v8+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8-alt.img /etc/kernel/prerm.d/${version}-v8+
fi
if [ -d "/etc/kernel/prerm.d/${version}-v8l+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v8l+ --arg=/boot/kernel8l-alt.img /etc/kernel/prerm.d/${version}-v8l+
fi
EOF

cat <<EOF >> kalipi-kernel.postrm
if [ -f /etc/default/kalipi-kernel ]; then
  . /etc/default/kalipi-kernel
  INITRD=\${INITRD:-"No"}
  export INITRD
  RPI_INITRD=\${RPI_INITRD:-"No"}
  export RPI_INITRD
fi
if [ -d "/etc/kernel/postrm.d" ]; then
  run-parts -v --report --exit-on-error --arg=${version}+ --arg=/boot/kernel.img /etc/kernel/postrm.d
  run-parts -v --report --exit-on-error --arg=${version}-v7+ --arg=/boot/kernel7.img /etc/kernel/postrm.d
  run-parts -v --report --exit-on-error --arg=${version}-v7l+ --arg=/boot/kernel7l.img /etc/kernel/postrm.d
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8-alt.img /etc/kernel/postrm.d
  run-parts -v --report --exit-on-error --arg=${version}-v8l+ --arg=/boot/kernel8l-alt.img /etc/kernel/postrm.d
fi
if [ -d "/etc/kernel/postrm.d/${version}+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}+ --arg=/boot/kernel.img /etc/kernel/postrm.d/${version}+
fi
if [ -d "/etc/kernel/postrm.d/${version}-v7+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v7+ --arg=/boot/kernel7.img /etc/kernel/postrm.d/${version}-v7+
fi
if [ -d "/etc/kernel/postrm.d/${version}-v7l+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v7l+ --arg=/boot/kernel7l.img /etc/kernel/postrm.d/${version}-v7l+
fi
if [ -d "/etc/kernel/postrm.d/${version}-v8+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8-alt.img /etc/kernel/postrm.d/${version}-v8+
fi
if [ -d "/etc/kernel/postrm.d/${version}-v8l+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v8l+ --arg=/boot/kernel8l-alt.img /etc/kernel/postrm.d/${version}-v8l+
fi
EOF

cat <<EOF >> kalipi-kernel-headers.postinst
if [ -f /etc/default/kalipi-kernel ]; then
  . /etc/default/kalipi-kernel
  INITRD=\${INITRD:-"No"}
  export INITRD
  RPI_INITRD=\${RPI_INITRD:-"No"}
  export RPI_INITRD
fi
if [ -d "/etc/kernel/header_postinst.d" ]; then
  run-parts -v --verbose --exit-on-error --arg=${version}+ /etc/kernel/header_postinst.d
  run-parts -v --verbose --exit-on-error --arg=${version}-v7+ /etc/kernel/header_postinst.d
  run-parts -v --verbose --exit-on-error --arg=${version}-v7l+ /etc/kernel/header_postinst.d
  run-parts -v --verbose --exit-on-error --arg=${version}-v8+ /etc/kernel/header_postinst.d
  run-parts -v --verbose --exit-on-error --arg=${version}-v8l+ /etc/kernel/header_postinst.d
fi
if [ -d "/etc/kernel/header_postinst.d/${version}+" ]; then
  run-parts -v --verbose --exit-on-error --arg=${version}+ /etc/kernel/header_postinst.d/${version}+
fi
if [ -d "/etc/kernel/header_postinst.d/${version}-v7+" ]; then
  run-parts -v --verbose --exit-on-error --arg=${version}-v7+ /etc/kernel/header_postinst.d/${version}-v7+
fi
if [ -d "/etc/kernel/header_postinst.d/${version}-v7l+" ]; then
  run-parts -v --verbose --exit-on-error --arg=${version}-v7l+ /etc/kernel/header_postinst.d/${version}-v7l+
fi
if [ -d "/etc/kernel/header_postinst.d/${version}-v8+" ]; then
  run-parts -v --verbose --exit-on-error --arg=${version}-v8+ /etc/kernel/header_postinst.d/${version}-v8+
fi
if [ -d "/etc/kernel/header_postinst.d/${version}-v8l+" ]; then
  run-parts -v --verbose --exit-on-error --arg=${version}-v8l+ /etc/kernel/header_postinst.d/${version}-v8l+
fi
EOF

printf "#DEBHELPER#\n" >> kalipi-kernel.prerm
printf "#DEBHELPER#\n" >> kalipi-kernel.postrm
printf "#DEBHELPER#\n" >> kalipi-kernel-headers.postinst

