#!/usr/bin/env bash
set -e
export LC_ALL="C.UTF-8"

log(){
    echo "[$(tput setaf 14)INFO$(tput sgr0)] ${@}"
}

if [ $UID -ne 0 ];then
    echo "Must be root"
    exit
fi

log "Getting apk-tools"
wget $(curl -L https://gitlab.alpinelinux.org/api/v4/projects/alpine%2Fapk-tools/releases/permalink/latest | jq -r ".assets.links[] | select(.name | contains(\"$(uname -m)\")) | .url")
chmod +x apk.static

log "Building rootfs"
./apk.static --arch $(arch) -X http://dl-cdn.alpinelinux.org/alpine/latest-stable/main/ -U --allow-untrusted --root /tmp/target --initdb add alpine-base
