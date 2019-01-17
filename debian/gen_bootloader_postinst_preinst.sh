#!/bin/sh

if ! [ -d ../boot ]; then
  printf "Can't find boot dir. Run from debian subdir\n"
  exit 1
fi

version=`cat ../extra/uname_string | cut -f 3 -d ' ' | tr -d +`-Re4son

printf "#!/bin/sh\n" > kalipi-kernel.postinst
printf "#!/bin/sh\n" > kalipi-kernel.preinst

printf "mkdir -p /usr/share/rpikernelhack/overlays\n" >> kalipi-kernel.preinst
printf "mkdir -p /boot/overlays\n" >> kalipi-kernel.preinst

for FN in ../boot/*.dtb ../boot/kernel*.img ../boot/COPYING.linux ../boot/overlays/*; do
  if ! [ -d "$FN" ]; then
    FN=${FN#../boot/}
    printf "if [ -f /usr/share/rpikernelhack/$FN ]; then\n" >> kalipi-kernel.postinst
    printf "	rm -f /boot/$FN\n" >> kalipi-kernel.postinst
    printf "	dpkg-divert --package rpikernelhack --remove --rename /boot/$FN\n" >> kalipi-kernel.postinst
    printf "	sync\n" >> kalipi-kernel.postinst
    printf "fi\n" >> kalipi-kernel.postinst

    printf "dpkg-divert --package rpikernelhack --divert /usr/share/rpikernelhack/$FN /boot/$FN\n" >> kalipi-kernel.preinst
  fi
done

cat <<EOF >> kalipi-kernel.preinst
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
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8-alt.img /etc/kernel/preinst.d
fi
if [ -d "/etc/kernel/preinst.d/${version}+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}+ --arg=/boot/kernel.img /etc/kernel/preinst.d/${version}+
fi
if [ -d "/etc/kernel/preinst.d/${version}-v7+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v7+ --arg=/boot/kernel7.img /etc/kernel/preinst.d/${version}-v7+
fi
if [ -d "/etc/kernel/preinst.d/${version}-v8+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8-alt.img /etc/kernel/preinst.d/${version}-v8+
fi
EOF

cat <<EOF >> kalipi-kernel.postinst
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
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8-alt.img /etc/kernel/postinst.d
fi
if [ -d "/etc/kernel/postinst.d/${version}+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}+ --arg=/boot/kernel.img /etc/kernel/postinst.d/${version}+
fi
if [ -d "/etc/kernel/postinst.d/${version}-v7+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v7+ --arg=/boot/kernel7.img /etc/kernel/postinst.d/${version}-v7+
fi
if [ -d "/etc/kernel/postinst.d/${version}-v8+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8-alt.img /etc/kernel/postinst.d/${version}-v8+
fi
EOF

printf "#DEBHELPER#\n" >> kalipi-kernel.postinst
printf "#DEBHELPER#\n" >> kalipi-kernel.preinst

printf "#!/bin/sh\n" > kalipi-bootloader.postinst
printf "#!/bin/sh\n" > kalipi-bootloader.preinst

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

EOF

for FN in ../boot/*.elf ../boot/*.dat ../boot/*.bin ../boot/LICENCE.broadcom; do
  if ! [ -d "$FN" ]; then
    FN=${FN#../boot/}
    printf "rm -f /boot/$FN\n" >> kalipi-bootloader.postinst
    printf "dpkg-divert --package rpikernelhack --remove --rename /boot/$FN\n" >> kalipi-bootloader.postinst
    printf "sync\n" >> kalipi-bootloader.postinst

    printf "dpkg-divert --package rpikernelhack --divert /usr/share/rpikernelhack/$FN /boot/$FN\n" >> kalipi-bootloader.preinst
  fi
done

printf "#DEBHELPER#\n" >> kalipi-bootloader.postinst
printf "#DEBHELPER#\n" >> kalipi-bootloader.preinst

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
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8-alt.img /etc/kernel/prerm.d
fi
if [ -d "/etc/kernel/prerm.d/${version}+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}+ --arg=/boot/kernel.img /etc/kernel/prerm.d/${version}+
fi
if [ -d "/etc/kernel/prerm.d/${version}-v7+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v7+ --arg=/boot/kernel7.img /etc/kernel/prerm.d/${version}-v7+
fi
if [ -d "/etc/kernel/prerm.d/${version}-v8+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8-alt.img /etc/kernel/prerm.d/${version}-v8+
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
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8-alt.img /etc/kernel/postrm.d
fi
if [ -d "/etc/kernel/postrm.d/${version}+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}+ --arg=/boot/kernel.img /etc/kernel/postrm.d/${version}+
fi
if [ -d "/etc/kernel/postrm.d/${version}-v7+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v7+ --arg=/boot/kernel7.img /etc/kernel/postrm.d/${version}-v7+
fi
if [ -d "/etc/kernel/postrm.d/${version}-v8+" ]; then
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8-alt.img /etc/kernel/postrm.d/${version}-v8+
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
  run-parts -v --verbose --exit-on-error --arg=${version}-v8+ /etc/kernel/header_postinst.d
fi

if [ -d "/etc/kernel/header_postinst.d/${version}+" ]; then
  run-parts -v --verbose --exit-on-error --arg=${version}+ /etc/kernel/header_postinst.d/${version}+
fi

if [ -d "/etc/kernel/header_postinst.d/${version}-v7+" ]; then
  run-parts -v --verbose --exit-on-error --arg=${version}-v7+ /etc/kernel/header_postinst.d/${version}-v7+
fi
if [ -d "/etc/kernel/header_postinst.d/${version}-v8+" ]; then
  run-parts -v --verbose --exit-on-error --arg=${version}-v8+ /etc/kernel/header_postinst.d/${version}-v8+
fi
EOF

printf "#DEBHELPER#\n" >> kalipi-kernel.prerm
printf "#DEBHELPER#\n" >> kalipi-kernel.postrm
printf "#DEBHELPER#\n" >> kalipi-kernel-headers.postinst
