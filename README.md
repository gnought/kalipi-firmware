This repository contains pre-compiled binaries of the current Kali-Pi 
kernel and modules, userspace libraries, and bootloader/GPU firmware.

A rough guide to this repository and the licences covering its contents is 
below (check the appropriate directories for more specific licence details):

* boot:
    * start*.elf, fixup*.dat and bootcode.bin are the GPU firmwares and
    bootloader. Their licence is described in `boot/LICENCE.broadcom`.
    * The dtbs, overlays and associated README are built from Linux kernel
    sources, released under the GPL (see `boot/COPYING.linux`)
* documentation/ilcomponents: OpenMax IL documentation (`boot/LICENCE.broadcom`)
* extra: Reference to the kernel version for the builds (`boot/COPYING.linux`),
  and dt-blob.dts (`boot/LICENCE.broadcom`)
* hardfp/opt/vc: userspace VideoCoreIV libraries built for the armv6 hardfp ABI
  (`opt/vc/LICENCE`)
* opt/vc: includes userspace libraries for the VideCoreIV - EGL/GLES/OpenVG 
  etc. (`opt/vc/LICENCE`)
