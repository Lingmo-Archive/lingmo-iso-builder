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

make_iso_image() {
    grub-mkimage -o "${workdir}/core.img" -O i386-pc -C xz --prefix=/boot/grub biosdisk iso9660 normal
    cat /usr/lib/grub/i386-pc/cdboot.img "${workdir}/core.img" >"${isoroot}/boot/grub/grub_eltorito"

    grub-mkstandalone -O i386-efi \
        --compress="xz" \
        --locales="" \
        --themes="" \
        --fonts="" \
        --output="${isoroot}/EFI/BOOT/BOOTIA32.EFI" \
        "boot/grub/grub.cfg=$(dirname "$0")/grub-embed.cfg"

    grub-mkstandalone -O x86_64-efi \
        --compress="xz" \
        --locales="" \
        --themes="" \
        --fonts="" \
        --output="${isoroot}/EFI/BOOT/BOOTx64.EFI" \
        "boot/grub/grub.cfg=$(dirname "$0")/grub-embed.cfg"

    mkfs.fat -C -n EFIBOOT efiboot.img 8192
    mmd -i efiboot.img ::/EFI ::/EFI/BOOT
    mcopy -vi efiboot.img \
        "${isoroot}/EFI/BOOT/BOOTIA32.EFI" \
        "${isoroot}/EFI/BOOT/BOOTx64.EFI" \  ::/EFI/BOOT/

    xorriso \
        -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        --mbr-force-bootable -partition_offset 16 \
        -joliet -joliet-long -rational-rock \
        --grub2-boot-info \
        --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
        -eltorito-boot \
        boot/grub/grub_eltorito \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --eltorito-catalog boot/grub/boot.cat \
        -eltorito-alt-boot \
        -e --interval:appended_partition_2:all:: \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -append_partition 2 C12A7328-F81F-11D2-BA4B-00A0C93EC93B efiboot.img \
        -output "${isofile}" \
        "${isoroot}"
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
    bash linux-lts linux-firmware acpi
)
"${workdir}/apk" \
    -X https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/ \
    -U --allow-untrusted -p "${workdir}/rootfs" --initdb add alpine-base "${extra_packages[@]}"
cp "$(dirname "$0")/chroot.sh" "${workdir}/rootfs"

log "Entering chroot"
arch-chroot "${workdir}/rootfs" /chroot.sh

du -sh "${workdir}/rootfs"

log "Making SquashFS image"
mksquashfs "${workdir}/rootfs" "${workdir}/rootfs.squashfs" -comp xz -Xbcj x86 -b 1M -Xdict-size 1M
du -h "${workdir}/rootfs.squashfs"

log "Making ISO image"
isofile="$(dirname "$0")/lingmo-installer-$(uname -m)-$(date +%Y.%m.%d).iso"
isoroot="${workdir}/isoroot"
mkdir -pv "${isoroot}/boot/grub"
cp -v "$(dirname "$0")/grub.cfg" "${isoroot}/boot/grub"
make_iso_image
du -h "$(dirname "$0")/*.iso"

log "Done!"
