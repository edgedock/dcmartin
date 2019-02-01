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

# Copy root file-system
COPY rootfs /

# Build arguments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

# Labels
LABEL \
    com.github.open-horizon.name="BASE" \
    com.github.open-horizon.description="base container" \ 
    com.github.open-horizon.arch="${BUILD_ARCH}" \
    com.github.open-horizon.type="service" \
    com.github.open-horizon.version="${BUILD_VERSION}" \
    maintainer="David C Martin <github@dcmartin.com>"
