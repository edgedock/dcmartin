#!/bin/bash
if [[ $(whoami) != "root" ]]; then
  echo "Run as root"
  exit 1
fi
curl -sL https://raw.githubusercontent.com/home-assistant/hassio-build/master/install/hassio_install > ./hassio_install.sh
chmod 755 ./hassio_install.sh

ARCH=$(uname -m)

# Generate hardware options
case $ARCH in
    "arm" | "armv7l" | "armv6l")
        ARGS="-m armhf"
    ;;
    "aarch64")
        ARGS="-m aarch64"
    ;;
esac

# install pre-requisites
apt install -y \
    apparmor-utils \
    apt-transport-https \
    avahi-daemon \
    ca-certificates \
    curl \
    dbus \
    jq \
    network-manager \
    socat \
    software-properties-common 

bash ./hassio_install.sh ${ARGS:-}

