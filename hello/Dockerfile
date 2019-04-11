FROM ubuntu:bionic
RUN apt-get update && apt-get install -qq -y socat curl
COPY rootfs /
CMD ["/usr/bin/run.sh"]
