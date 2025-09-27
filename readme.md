# wolfLab playground



## pack compiled elf

* [using crosstool ng](./crosstool/readme.md)

## pack rootfs tools with app

why : You need a portable, drop-in userspace that “just runs” anywhere.

* [using buildroot demo](./buildroot/readme.md)
* [using openwrt demo](./openwrt/readme.md) with mosul
* [alphine](./alphne/readme.md) with mosul mini rootfs if uClibc isn’t mandatory 

for both option ship img with 
```
Privileged: sudo chroot rootfs /bin/bash
Unprivileged: proot -R rootfs /bin/bash
```
 
 
## package one or a few binaries

port your ELF plus all its shared libs (uClibc, ld-uClibc.so, etc)

ship 1–3 tools, not a shell environment

* [Patchelf](patchelf/readme.md) 
* static busybox
* StaticX 


## ?
packs Build a closure and export a relocatable tarball with a launch script (guix pack, nix bundle)