ARG BUILD_FROM=ubuntu:bionic

FROM $BUILD_FROM

ARG BUILD_FROM=ubuntu:bionic

ENV LANG C.UTF-8

RUN apt-get update && apt-get install -q -y --no-install-recommends \
  curl \
  socat \
  jq

# Copy rootfs
COPY rootfs /

CMD [ "/usr/bin/run.sh" ]

# Build arguments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

# Labels
LABEL \
    com.github.open-horizon.name="base-ubuntu" \
    com.github.open-horizon.description="base image for ubuntu bionic" \ 
    com.github.open-horizon.arch="${BUILD_ARCH}" \
    com.github.open-horizon.type="service" \
    com.github.open-horizon.version="${BUILD_VERSION}" \
    maintainer="David C Martin <github@dcmartin.com>"
