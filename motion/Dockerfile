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
    && apk add --no-cache --virtual .build-dependencies \
        tar=1.30-r0 \
    \
    && apk add --no-cache \
        apk-tools=2.10.1-r0 \
        bash=4.4.19-r1 \
        busybox=1.28.4-r1 \
        ca-certificates=20171114-r3 \
        curl=7.61.1-r1 \
        jq=1.6_rc1-r1 \
        musl-utils=1.1.19-r10 \
        musl=1.1.19-r10 \
        tzdata=2018f-r0 \
    \
    && if [ "${BUILD_ARCH}" = "i386" ]; then S6_ARCH="x86"; else S6_ARCH="${BUILD_ARCH}"; fi \
    \
    && curl -L -s "https://github.com/just-containers/s6-overlay/releases/download/v1.21.7.0/s6-overlay-${S6_ARCH}.tar.gz" \
        | tar zxvf - -C / \
    \
    && mkdir -p /etc/fix-attrs.d \
    && mkdir -p /etc/services.d \
    \
    && apk del --purge .build-dependencies \
    && rm -f -r \
        /tmp/*

# Entrypoint & CMD
ENTRYPOINT ["/init"]

# Build arugments
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

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

## APACHE

ARG MOTION_APACHE_CONF=/etc/apache2/httpd.conf
ARG MOTION_APACHE_HTDOCS=/var/www/localhost/htdocs
ARG MOTION_APACHE_CGIBIN=/var/www/localhost/cgi-bin
ARG MOTION_APACHE_HOST=localhost
ARG MOTION_APACHE_PORT=7999
ARG MOTION_APACHE_ADMIN=root@hassio.local

ENV MOTION_APACHE_CONF "${MOTION_APACHE_CONF}"
ENV MOTION_APACHE_HTDOCS "${MOTION_APACHE_HTDOCS}"
ENV MOTION_APACHE_CGIBIN "${MOTION_APACHE_CGIBIN}"
ENV MOTION_APACHE_HOST "${MOTION_APACHE_HOST}"
ENV MOTION_APACHE_PORT "${MOTION_APACHE_PORT}"
ENV MOTION_APACHE_ADMIN "${MOTION_APACHE_ADMIN}"

# Ports for motion (control and stream)
EXPOSE ${MOTION_APACHE_PORT}

EXPOSE 8000
EXPOSE 8090

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
