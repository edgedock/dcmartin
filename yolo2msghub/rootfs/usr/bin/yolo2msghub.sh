#!/bin/bash

if [ -z "${MSGHUB_BROKER}" ]; then echo "*** ERROR $0 $$ -- environment variable undefined: MSGHUB_BROKER; exiting" &> /dev/stderr; exit 1; fi
if [ -z "${MSGHUB_APIKEY}" ]; then echo "*** ERROR $0 $$ -- environment variable undefined: MSGHUB_APIKEY; exiting" &> /dev/stderr; exit 1; fi

YOLO_URL="http://yolo:80/v1/person"
CPU_URL="http://cpu:8347/v1/cpu"
GPS_URL="http://gps:31779/v1/gps/location"

while true; do
  URL=${YOLO_URL} && OUT=$(curl -fqsSL "${URL}"); if [ ! -z "${OUT}" ]; then YOLO=$(echo "${OUT}" | jq); else YOLO='null'; fi
  URL=${CPU_URL} && OUT=$(curl -fqsSL "${URL}"); if [ ! -z "${OUT}" ]; then CPU=$(echo "${OUT}" | jq); else CPU='null'; fi
  URL=${GPS_URL} && OUT=$(curl -fqsSL "${URL}"); if [ ! -z "${OUT}" ]; then GPS=$(echo "${OUT}" | jq); else GPS='null'; fi

  OUTPUT='{"date":'$(date +%s)',"yolo":'${YOLO}',"cpu":'${CPU}',"gps":'${GPS}'}'
  if [ $(command -v kafkacat) ]; then
    echo "${OUTPUT}" \
      | kafkacat \
          -P \
          -b "${MSGHUB_BROKER}" \
          -X api.version.request=true \
          -X security.protocol=sasl_ssl \
          -X sasl.mechanisms=PLAIN \
          -X sasl.username=iamapikey \
          -X sasl.password="${MSGHUB_APIKEY}" \
          -t "yolo/${HZN_DEVICE_ID}"
  else
    echo "${OUTPUT}" &> /dev/stderr
  fi
done

