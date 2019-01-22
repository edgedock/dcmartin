ARG BUILD_FROM=ubuntu:bionic

FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apt-get update && apt-get install -q -y --no-install-recommends \
  curl \
  build-essential \
  socat \
  fswebcam \
  jq \
  git

# Copy rootts
COPY rootfs /

CMD [ "/usr/bin/run.sh" ]

# Build darknet
RUN \
    cd /darknet \
    \
    && make

# Build arugments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

# Labels
LABEL \
    com.github.open-horizon.name="YOLO" \
    com.github.open-horizon.description="Provide YOLO as-a-service on /dev/video0" \ 
    com.github.open-horizon.arch="${BUILD_ARCH}" \
    com.github.open-horizon.type="service" \
    com.github.open-horizon.version="${BUILD_VERSION}" \
    maintainer="David C Martin <github@dcmartin.com>"
