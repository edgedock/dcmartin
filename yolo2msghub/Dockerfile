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
    && apk add --no-cache \
  	bash \
  	bc \
  	curl \
  	dateutils \
  	jq \
	socat \
  	mosquitto-clients \
  	tcsh \
    \
    && rm -f -r \
        /tmp/*

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
    com.github.dcmartin.open-horizon.name="YOLO2MSGHUB" \
    com.github.dcmartin.open-horizon.description="Send YOLO to Kafka" \ 
    com.github.dcmartin.open-horizon.arch="${BUILD_ARCH}" \
    com.github.dcmartin.open-horizon.type="pattern" \
    com.github.dcmartin.open-horizon.version=${BUILD_VERSION} \
    maintainer="David C Martin <github@dcmartin.com>"
