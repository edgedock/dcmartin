ARG BUILD_FROM=dcmartin/base-ubuntu

FROM $BUILD_FROM

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    TERM="xterm"

ARG BUILD_ARCH=
 
RUN apt-get update && apt-get install -q -y --no-install-recommends \
  gnupg

RUN apt-get update \
  \
  && ARCH="${BUILD_ARCH}" \
  && if [ "${BUILD_ARCH}" = "aarch64" ]; then ARCH="arm64"; fi \
  && if [ "${BUILD_ARCH}" = "x86_64" ]; then ARCH="amd64"; fi \
  \
  && HORIZON_CLI="2.20.0" \
  && HORIZON_URL="http://pkg.bluehorizon.network/linux/ubuntu/pool/main/h/horizon/horizon-cli" \
  && HORIZON_PKG="${HORIZON_URL}_${HORIZON_CLI}~ppa~ubuntu.xenial_${ARCH}.deb" \
  && curl -fsSL -o /tmp/horizon-cli.deb  "${HORIZON_PKG}" \
  && dpkg --install /tmp/horizon-cli.deb

RUN apt-get update -y \
  && rm -fr \
      /tmp/* \
      /var/{cache,log}/* \
      /var/lib/apt/lists/*

# Copy rootfs
COPY rootfs /

CMD [ "/usr/bin/run.sh" ]

# Build arguments
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

# Labels
LABEL \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date="${BUILD_DATE}" \
    org.label-schema.name="base-alpine" \
    org.label-schema.description="base alpine container" \
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/master/base-alpine/" \
    org.label-schema.vcs-ref="${BUILD_REF}" \
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
