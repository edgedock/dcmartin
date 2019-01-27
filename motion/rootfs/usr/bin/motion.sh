#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

if [ -z "${MOTION_LOG_LEVEL:-}" ]; then MOTION_LOG_LEVEL=2; fi
if [ -z "${MOTION_LOG_TYPE:-}" ]; then MOTION_LOG_TYPE="all"; fi

ZONEINFO="/usr/share/zoneinfo/${MOTION_TIMEZONE}"
if [ -e "${ZONEINFO}" ]; then
  cp "${ZONEINFO}" /etc/localtime
else
  echo "+++ WARN $0 $$ -- cannot locate time zone information: ${ZONEINFO}" &> /dev/stderr
fi

echo '{"timezone": "'$MOTION_TIMEZONE'"}' > ${TMP}/${HZN_PATTERN}.json

mkdir -p ${TMP}/motion
ln -s ${TMP}/motion /var/lib/motion 

# start motion
motion -b -n ${MOTION_LOG_LEVEL} -k ${MOTION_LOG_TYPE} -c /etc/motion/motion.conf -l /dev/stderr
