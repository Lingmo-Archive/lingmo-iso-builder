#!/bin/sh
set -e

log(){
    echo "[CHROOT] [$(printf "\033[96m")INFO$(printf "\033[0m")]" "${@}"
}

log "Installing base packages"
setup-apkrepos -1 -c
apk update
apk add linux-lts linux-firmware-none acpi dracut

log "Setting up services"

rc-update add devfs sysinit
rc-update add dmesg sysinit
rc-update add mdev sysinit
rc-update add hwdrivers sysinit

rc-update add hwclock boot
rc-update add modules boot
rc-update add sysctl boot
rc-update add hostname boot
rc-update add bootmisc boot
rc-update add syslog boot
rc-update add networking boot
rc-update add seedrng boot
rc-update add swap boot

rc-update add crond default
rc-update add acpid default

rc-update add mount-ro shutdown
rc-update add killprocs shutdown
rc-update add savecache shutdown