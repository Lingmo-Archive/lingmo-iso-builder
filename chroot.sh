#!/usr/bin/env bash
set -e

log() {
    echo "$(printf "\033[94m")  ->$(printf "\033[0m")" "${@}"
}

log "Setting up DNS"
cat >/etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

log "Installing base packages"

cat >/etc/apk/repositories <<EOF
https://dl-cdn.alpinelinux.org/alpine/latest-stable/main
https://dl-cdn.alpinelinux.org/alpine/latest-stable/community
EOF

community_packages=(
    dracut
)
apk add "${community_packages[@]}"

log "Setting up services"

sysinit_services=(devfs dmesg mdev hwdrivers)
boot_services=(hwclock modules sysctl hostname bootmisc syslog networking seedrng swap)
default_services=(crond acpid)
shutdown_services=(mount-ro killprocs savecache)

for service in "${sysinit_services[@]}"; do
    rc-update add "$service" sysinit
done

for service in "${boot_services[@]}"; do
    rc-update add "$service" boot
done

for service in "${default_services[@]}"; do
    rc-update add "$service" default
done

for service in "${shutdown_services[@]}"; do
    rc-update add "$service" shutdown
done
