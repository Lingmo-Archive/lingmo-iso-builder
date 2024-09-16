# lingmo-iso-builder
LingmoOS installation ISO image builder.

## Build
```console
# pacman -Syu archiso git grub
$ git clone --depth 1 https://github.com/LingmoOS/lingmo-iso-builder
$ cd lingmo-iso-builder
# mkarchiso -v profile
```
Find the ISO file in `out/` after building.
