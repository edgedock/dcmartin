ARG BUILD_FROM=alpine:3.8

FROM $BUILD_FROM

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    TERM="xterm"

ARG BUILD_ARCH=amd64

# Set shell
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

# Install base system
RUN \
    set -o pipefail \
    \
    && echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories \
    && echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
    && echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories \
    \
    && rm -f -r \
        /tmp/*

RUN apk add --no-cache \
  apache2 \
  apache2-utils \
  bc \
  coreutils \
  curl \
  dateutils \
  findutils \
  ffmpeg@edge \
  motion@edge \
  gawk \
  imagemagick \
  inotify-tools \
  jq \
  mosquitto-clients \
  python3 \
  tcsh \
  git

# Copy root file-system
COPY rootfs /

# environment
ENV CONFIG_PATH /data/options.json
ENV MOTION_CONF /etc/motion/motion.conf

# Ports for motion (control and stream)
EXPOSE 8080
EXPOSE 8081

CMD [ "/usr/bin/run.sh" ]

# Build arugments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="MOTION" \
    io.hass.description="Motion package as addon w/ support for image classification" \ 
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="David C Martin <github@dcmartin.com>"
