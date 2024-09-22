#!/usr/bin/env bash
set -e
umask 0022
export LC_ALL="C.UTF-8"

workdir=$(mktemp -d lingmoiso.XXXXXXXXXX -p /tmp)

log() {
    echo "$(printf "\033[92m")==>$(printf "\033[0m")" "${@}"
}

get_apk_download_link() {
    curl -L https://gitlab.alpinelinux.org/api/v4/projects/alpine%2Fapk-tools/releases/permalink/latest |
        jq -r ".assets.links[] | select(.name | contains(\"$(arch)\")) | .url"
}

if [ $UID -ne 0 ]; then
    echo "Must be root"
    exit 1
fi

log "Getting apk-tools"
curl -Lo "${workdir}/apk" "$(get_apk_download_link)"
chmod +x "${workdir}/apk"

log "Building rootfs"
extra_packages=(
    bash linux-lts linux-firmware-none acpi
)
"${workdir}/apk" \
    -X https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/ \
    -U --allow-untrusted -p "${workdir}/rootfs" --initdb add alpine-base "${extra_packages[@]}"
cp "$(dirname "$0")/chroot.sh" "${workdir}/rootfs"

log "Entering chroot"
arch-chroot "${workdir}/rootfs" /chroot.sh

rootfs_size=$(du -sh "${workdir}/rootfs" | awk '{print $1}')
log "RootFS size: ${rootfs_size}"
