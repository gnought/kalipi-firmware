#!/bin/sh

if ! [ -d ../boot ]; then
  printf "Can't find boot dir. Run from debian subdir\n"
  exit 1
fi

version="$(cut -f 3 -d ' ' ../extra/uname_string | tr -d +)"

NEW_SIZE="$(du -cm ../boot/*.dtb ../boot/kernel*.img ../boot/COPYING.linux ../boot/overlays/* ../boot/start*.elf ../boot/fixup*.dat ../boot/LICENCE.broadcom | tail -n1 | cut -f1)"

printf "#!/bin/sh -e\n\n" | tee raspberrypi-kernel.postinst | tee raspberrypi-bootloader.postinst | tee raspberrypi-kernel.preinst > raspberrypi-bootloader.preinst

cat <<EOF | tee -a raspberrypi-kernel.postinst >> raspberrypi-bootloader.postinst
get_file_list() {
  cat /var/lib/dpkg/info/raspberrypi-kernel.md5sums /var/lib/dpkg/info/raspberrypi-kernel.md5sums 2> /dev/null | awk '/ boot/ {print "/"\$2}'
}

get_filtered_file_list() {
  for file in \$(get_file_list); do
    if [ -f "\$file" ]; then
      echo "\$file"
    fi
  done
}

get_available_space() {
  INSTALLED_SPACE="\$(get_filtered_file_list | xargs -r du -cm 2> /dev/null | tail -n1 | cut -f1)"
  FREE_SPACE="\$(df -m /boot | awk 'NR==2 {print \$4}')"
  echo \$(( INSTALLED_SPACE + FREE_SPACE ))
}

is_pifour() {
  grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]11[0-9a-fA-F]$" /proc/cpuinfo
  return \$?
}

if [ "\$(get_available_space)" -lt "$NEW_SIZE" ]; then
  echo "You do not have enough space in /boot to install this package."
  SKIP_FILES=1
  if is_pifour; then
    SKIP_PI4=0
    echo "Only adding Pi 4 support"
  else
    SKIP_PI4=1
    echo "Skipping Pi 4 support"
  fi
fi

EOF

printf "mkdir -p /usr/share/rpikernelhack\n" >> raspberrypi-bootloader.preinst
printf "mkdir -p /usr/share/rpikernelhack/overlays\n" >> raspberrypi-kernel.preinst
printf "mkdir -p /boot/overlays\n" >> raspberrypi-kernel.preinst

cat <<EOF | tee -a raspberrypi-kernel.postinst >> raspberrypi-bootloader.postinst
if [ "\$SKIP_FILES" != "1" ] || [ "\${SKIP_PI4}" = "1" ]; then
EOF
for FN in ../boot/kernel.img ../boot/kernel7.img; do
  if [ -f "$FN" ]; then
    FN=${FN#../boot/}
    cat << EOF >> raspberrypi-kernel.postinst
  if [ -f /usr/share/rpikernelhack/$FN ]; then
    rm -f /boot/$FN
    dpkg-divert --package rpikernelhack --rename --remove /boot/$FN
    sync
  fi
EOF
  fi
  printf "dpkg-divert --package rpikernelhack --rename --divert /usr/share/rpikernelhack/%s /boot/%s\n" "$FN" "$FN" >> raspberrypi-kernel.preinst
done
for FN in ../boot/start.elf ../boot/start_*.elf ../boot/fixup.dat ../boot/fixup_*.dat ../boot/*.bin; do
  if [ -f "$FN" ]; then
    FN=${FN#../boot/}
    cat << EOF >> raspberrypi-bootloader.postinst
  if [ -f /usr/share/rpikernelhack/$FN ]; then
    rm -f /boot/$FN
    dpkg-divert --package rpikernelhack --rename --remove /boot/$FN
    sync
  fi
EOF
  printf "dpkg-divert --package rpikernelhack --rename --divert /usr/share/rpikernelhack/%s /boot/%s\n" "$FN" "$FN" >> raspberrypi-bootloader.preinst
  fi
done

cat <<EOF | tee -a raspberrypi-kernel.postinst >> raspberrypi-bootloader.postinst
fi

if [ "\$SKIP_FILES" != "1" ] || [ "\${SKIP_PI4}" = "0" ]; then
EOF
for FN in ../boot/kernel7l.img ../boot/kernel8.img; do
  if [ -f "$FN" ]; then
    FN=${FN#../boot/}
    cat << EOF >> raspberrypi-kernel.postinst
  if [ -f /usr/share/rpikernelhack/$FN ]; then
    rm -f /boot/$FN
    dpkg-divert --package rpikernelhack --rename --remove /boot/$FN
    sync
  fi
EOF
  fi
  printf "dpkg-divert --package rpikernelhack --rename --divert /usr/share/rpikernelhack/%s /boot/%s\n" "$FN" "$FN" >> raspberrypi-kernel.preinst
done
for FN in ../boot/start4*.elf ../boot/fixup4*.dat; do
  if [ -f "$FN" ]; then
    FN=${FN#../boot/}
    cat << EOF >> raspberrypi-bootloader.postinst
  if [ -f /usr/share/rpikernelhack/$FN ]; then
    rm -f /boot/$FN
    dpkg-divert --package rpikernelhack --rename --remove /boot/$FN
    sync
  fi
EOF
  printf "dpkg-divert --package rpikernelhack --rename --divert /usr/share/rpikernelhack/%s /boot/%s\n" "$FN" "$FN" >> raspberrypi-bootloader.preinst
  fi
done
cat <<EOF | tee -a raspberrypi-kernel.postinst >> raspberrypi-bootloader.postinst
fi

EOF

for FN in ../boot/*.dtb ../boot/COPYING.linux ../boot/overlays/*; do
  if [ -f "$FN" ]; then
    FN=${FN#../boot/}
    cat << EOF >> raspberrypi-kernel.postinst
if [ -f /usr/share/rpikernelhack/$FN ]; then
  rm -f /boot/$FN
  dpkg-divert --package rpikernelhack --rename --remove /boot/$FN
  sync
fi
EOF
  printf "dpkg-divert --package rpikernelhack --rename --divert /usr/share/rpikernelhack/%s /boot/%s\n" "$FN" "$FN" >> raspberrypi-kernel.preinst
  fi
done

for FN in ../boot/LICENCE.broadcom; do
  if [ -f "$FN" ]; then
    FN=${FN#../boot/}
    cat << EOF >> raspberrypi-bootloader.postinst
if [ -f /usr/share/rpikernelhack/$FN ]; then
  rm -f /boot/$FN
  dpkg-divert --package rpikernelhack --rename --remove /boot/$FN
  sync
fi
EOF
  printf "dpkg-divert --package rpikernelhack --rename --divert /usr/share/rpikernelhack/%s /boot/%s\n" "$FN" "$FN" >> raspberrypi-bootloader.preinst
  fi
done

cat <<EOF >> raspberrypi-kernel.preinst
if [ -f /etc/default/raspberrypi-kernel ]; then
  . /etc/default/raspberrypi-kernel
  INITRD=\${INITRD:-"No"}
  export INITRD
  RPI_INITRD=\${RPI_INITRD:-"No"}
  export RPI_INITRD
fi
if [ -d "/etc/kernel/preinst.d" ]; then
  run-parts -v --report --exit-on-error --arg=${version}+ --arg=/boot/kernel.img /etc/kernel/preinst.d
  run-parts -v --report --exit-on-error --arg=${version}-v7+ --arg=/boot/kernel7.img /etc/kernel/preinst.d
  run-parts -v --report --exit-on-error --arg=${version}-v7l+ --arg=/boot/kernel7l.img /etc/kernel/preinst.d
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8.img /etc/kernel/preinst.d
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
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8.img /etc/kernel/preinst.d/${version}-v8+
fi
EOF

cat <<EOF >> raspberrypi-kernel.postinst
if [ -f /etc/default/raspberrypi-kernel ]; then
  . /etc/default/raspberrypi-kernel
  INITRD=\${INITRD:-"No"}
  export INITRD
  RPI_INITRD=\${RPI_INITRD:-"No"}
  export RPI_INITRD

fi
if [ -d "/etc/kernel/postinst.d" ]; then
  run-parts -v --report --exit-on-error --arg=${version}+ --arg=/boot/kernel.img /etc/kernel/postinst.d
  run-parts -v --report --exit-on-error --arg=${version}-v7+ --arg=/boot/kernel7.img /etc/kernel/postinst.d
  run-parts -v --report --exit-on-error --arg=${version}-v7l+ --arg=/boot/kernel7l.img /etc/kernel/postinst.d
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8.img /etc/kernel/postinst.d
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
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8.img /etc/kernel/postinst.d/${version}-v8+
fi
EOF

cat <<EOF >> raspberrypi-kernel.postinst
if [ -d /usr/share/rpikernelhack/overlays ]; then
  rmdir --ignore-fail-on-non-empty /usr/share/rpikernelhack/overlays
fi
EOF

cat <<EOF | tee -a raspberrypi-kernel.postinst >> raspberrypi-bootloader.postinst
if [ -d /usr/share/rpikernelhack ]; then
  rmdir --ignore-fail-on-non-empty /usr/share/rpikernelhack
fi
EOF

printf "#DEBHELPER#\n" | tee -a raspberrypi-kernel.postinst | tee -a raspberrypi-bootloader.postinst | tee -a raspberrypi-kernel.preinst >> raspberrypi-bootloader.preinst

printf "#!/bin/sh\n" > raspberrypi-kernel.prerm
printf "#!/bin/sh\n" > raspberrypi-kernel.postrm
printf "#!/bin/sh\n" > raspberrypi-kernel-headers.postinst

cat <<EOF >> raspberrypi-kernel.prerm
if [ -f /etc/default/raspberrypi-kernel ]; then
  . /etc/default/raspberrypi-kernel
  INITRD=\${INITRD:-"No"}
  export INITRD
  RPI_INITRD=\${RPI_INITRD:-"No"}
  export RPI_INITRD

fi
if [ -d "/etc/kernel/prerm.d" ]; then
  run-parts -v --report --exit-on-error --arg=${version}+ --arg=/boot/kernel.img /etc/kernel/prerm.d
  run-parts -v --report --exit-on-error --arg=${version}-v7+ --arg=/boot/kernel7.img /etc/kernel/prerm.d
  run-parts -v --report --exit-on-error --arg=${version}-v7l+ --arg=/boot/kernel7l.img /etc/kernel/prerm.d
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8.img /etc/kernel/prerm.d
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
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8.img /etc/kernel/prerm.d/${version}-v8+
fi
EOF

cat <<EOF >> raspberrypi-kernel.postrm
if [ -f /etc/default/raspberrypi-kernel ]; then
  . /etc/default/raspberrypi-kernel
  INITRD=\${INITRD:-"No"}
  export INITRD
  RPI_INITRD=\${RPI_INITRD:-"No"}
  export RPI_INITRD

fi
if [ -d "/etc/kernel/postrm.d" ]; then
  run-parts -v --report --exit-on-error --arg=${version}+ --arg=/boot/kernel.img /etc/kernel/postrm.d
  run-parts -v --report --exit-on-error --arg=${version}-v7+ --arg=/boot/kernel7.img /etc/kernel/postrm.d
  run-parts -v --report --exit-on-error --arg=${version}-v7l+ --arg=/boot/kernel7l.img /etc/kernel/postrm.d
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8.img /etc/kernel/postrm.d
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
  run-parts -v --report --exit-on-error --arg=${version}-v8+ --arg=/boot/kernel8.img /etc/kernel/postrm.d/${version}-v8+
fi
EOF

cat <<EOF >> raspberrypi-kernel-headers.postinst
if [ -f /etc/default/raspberrypi-kernel ]; then
  . /etc/default/raspberrypi-kernel
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
EOF

printf "#DEBHELPER#\n" >> raspberrypi-kernel.prerm
printf "#DEBHELPER#\n" >> raspberrypi-kernel.postrm
printf "#DEBHELPER#\n" >> raspberrypi-kernel-headers.postinst
