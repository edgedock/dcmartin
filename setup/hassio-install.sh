#!/bin/bash
if [[ $(whoami) != "root" ]]; then
  echo "Run as root"
  exit 1
fi

##
## get installation script
##

HASSIO_INSTALL="./hassio_install.sh"
HASSIO_URL="https://raw.githubusercontent.com/home-assistant/hassio-build/master/install/hassio_install"

wget -qO - "${HASSIO_URL}"  > "${HASSIO_INSTALL}"
if [ ! -s "${HASSIO_INSTALL}" ]; then
  echo "[Error] cannot access installation script at: ${HASSIO_URL}"
  exit 1
fi

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
        ARGS=
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

# install hassio
if [ -n "${ARGS}" ]; then
  echo "[Info] installing HASSIO with (${ARGS}) arguments"
else
  echo "[Info] installing HASSIO with NO arguments"
fi

bash ${HASSIO_INSTALL} ${ARGS} > hassio_install.log 2>&1
