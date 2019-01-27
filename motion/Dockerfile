ARG BUILD_FROM=alpine:3.8

FROM $BUILD_FROM

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    TERM="xterm"

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
  bash \
  bc \
  coreutils \
  curl \
  dateutils \
  ffmpeg@edge \
  findutils \
  gawk \
  git \
  imagemagick \
  jq \
  mosquitto-clients \
  motion@edge \
  socat \
  tcsh

# Copy root file-system
COPY rootfs /

CMD [ "/usr/bin/run.sh" ]

# Build arugments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

# Labels
LABEL \
    com.github.open-horizon.name="MOTION" \
    com.github.open-horizon.description="Provide motion as-a-service on /dev/video0" \ 
    com.github.open-horizon.arch="${BUILD_ARCH}" \
    com.github.open-horizon.type="service" \
    com.github.open-horizon.version="${BUILD_VERSION}" \
    maintainer="David C Martin <github@dcmartin.com>"
