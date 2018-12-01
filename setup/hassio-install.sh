#!/bin/bash
if [[ $(whoami) != "root" ]]; then
  echo "Run as root"
  exit 1
fi
wget -qO - https://raw.githubusercontent.com/home-assistant/hassio-build/master/install/hassio_install > ./hassio_install.sh
chmod 755 ./hassio_install.sh

ARCH=$(uname -m)

# ARM Machine types
#    intel-nuc
#    odroid-c2
#    odroid-xu
#    orangepi-prime
#    qemuarm
#    qemuarm-64
#    qemux86
#    qemux86-64
#    raspberrypi
#    raspberrypi2
#    raspberrypi3
#    raspberrypi3-64
#    tinker

# test architecture options
case $ARCH in
    "i386" | "i686" | "x86_64")
        ARGS=""
    ;;
    "arm")
        ARGS="-m raspberrypi"
    ;;
    "armv6l")
        ARGS="-m raspberrypi2"
    ;;
    "armv7l")
        ARGS="-m raspberrypi3"
    ;;
    "aarch64")
        ARGS="-m aarch64"
    ;;
    *)
        echo "[Error] $ARCH unsupported by this script"
        exit 1
    ;;
esac

# install pre-requisites
echo "[Info] installing pre-requisites"
for CMD in \
    apparmor-utils \
    apt-transport-https \
    avahi-daemon \
    ca-certificates \
    curl \
    dbus \
    jq \
    network-manager \
    socat \
    software-properties-common \
; do
  echo "+++ Installing ${CMD}" >&2
  apt install -y ${CMD} >> apt.log 2>&1
done

# install hassio
echo "[Info] installing HASSIO with ${ARGS}"
./hassio_install.sh ${ARGS} >> hassio_install.log 2>&1

# copy configuration 
# GITHUB_DIR="https://raw.githubusercontent.com/dcmartin/hassio-addons/master/horizon/rootfs/root/config"
# CONFIG_DIR="/usr/share/hassio/homeassistant"
# echo "[Info] copying YAML into ${CONFIG_DIR} from ${GITHUB_DIR}"
# curl -sL "${GITHUB_DIR}/configuration.yaml" -o "${CONFIG_DIR}/configuration.yaml"
# curl -sL "${GITHUB_DIR}/automations.yaml" -o "${CONFIG_DIR}/automations.yaml"
# curl -sL "${GITHUB_DIR}/ui-lovelace.yaml" -o "${CONFIG_DIR}/ui-lovelace.yaml"
# curl -sL "${GITHUB_DIR}/groups.yaml" -o "${CONFIG_DIR}/groups.yaml"

