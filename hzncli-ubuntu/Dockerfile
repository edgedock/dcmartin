ARG BUILD_FROM=dcmartin/base-ubuntu

FROM $BUILD_FROM

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    TERM="xterm"

ARG BUILD_ARCH=amd64
 
RUN apt-get update && apt-get install -q -y --no-install-recommends \
  ca-certificates \
  gnupg

RUN apt-get update -y 

RUN apt-get update \
  \
  && HORIZON_VER="2.20.1" \
  && HORIZON_URL="http://pkg.bluehorizon.network/linux/ubuntu/pool/main/h/horizon/horizon-cli" \
  && HORIZON_PKG="${HORIZON_URL}_${HORIZON_VER}~ppa~ubuntu.xenial_${BUILD_ARCH}.deb" \
#  && curl -sSL "http://pkg.bluehorizon.network/linux/ubuntu/pool/main/h/horizon/horizon-cli_2.21.0~ppa~ubuntu.xenial_amd64.deb" -o /tmp/horizon-cli.deb \
  && curl -sSL "${HORIZON_PKG}" -o /tmp/horizon-cli.deb \
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
    org.label-schema.build-arch="${BUILD_ARCH}" \
    org.label-schema.name="hzncli-ubuntu" \
    org.label-schema.description="horizon CLI base for ubuntu" \
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/master/hzncli-ubuntu/" \
    org.label-schema.vcs-ref="${BUILD_REF}" \
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
