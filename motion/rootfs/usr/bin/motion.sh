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

CONFIG='{"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"date":'$(date +%s)',"db":"'${MOTION_DEVICE_DB}'","name":"'${MOTION_DEVICE_NAME}'","timezone":"'$MOTION_TIMEZONE'","mqtt":{"host":"'${MOTION_MQTT_HOST}'","port":"'${MOTION_MQTT_PORT}'","username":"'${MOTION_MQTT_USERNAME}'","password":"'${MOTION_MQTT_PASSWORD}'"},"post":"'${MOTION_POST_PICTURES}'"}' 
echo "${CONFIG}" > ${TMP}/${SERVICE_LABEL}.json

mkdir -p ${TMP}/motion
rm -fr /var/lib/motion
ln -s ${TMP}/motion /var/lib

# start motion
motion -b -n ${MOTION_LOG_LEVEL} -k ${MOTION_LOG_TYPE} -c /etc/motion/motion.conf -l /dev/stderr
