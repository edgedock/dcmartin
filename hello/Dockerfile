FROM ubuntu:bionic
RUN apt-get update && apt-get install -qq -y socat
COPY rootfs /
CMD ["/usr/bin/run.sh"]
