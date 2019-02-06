ARG BUILD_FROM=ubuntu:bionic

FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apt-get update 

RUN apt-get install -q -y --no-install-recommends \
  curl \
  socat \
  ca-certificates \
  kafkacat \
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
    com.github.dcmartin.open-horizon.name="YOLO2MSGHUB" \
    com.github.dcmartin.open-horizon.description="Send YOLO to IBM MessageHub" \ 
    com.github.dcmartin.open-horizon.arch="${BUILD_ARCH}" \
    com.github.dcmartin.open-horizon.type="pattern" \
    com.github.dcmartin.open-horizon.version="${BUILD_VERSION}" \
    maintainer="David C Martin <github@dcmartin.com>"
