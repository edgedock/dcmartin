#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

JSON='[{"name": "yolo", "url": "http://yolo:80/v1/person" },{"name":"cpu","url":"http://cpu:8347/v1/cpu"},{"name":"gps","url":"http://gps:31779/v1/gps/location"}]'

SERVICES=$(echo "${JSON}" | jq -r '.[]|.name')

while true; do

  # make output
  OUTPUT='{"date":'$(date +%s)
  for SERVICE in $SERVICES; do
    URL=$(echo "${JSON}" | jq -r '.[]|select(.name=="'${SERVICE}'").url')
    if [ ! -z "${URL}" ]; then
      OUT=$(curl -fqsSL "${URL}" | jq '.'"${SERVICE}"'?')
    fi
    if [ -z "${OUT:-}" ]; then
      OUT='null'
    fi
    OUTPUT="${OUTPUT:-}"',"'${SERVICE}'":'"${OUT}"
  done
  OUTPUT="${OUTPUT}"'}'
  echo "${OUTPUT}" > "${TMP}/${HZN_PATTERN}.json"

  # send output
  if [ $(command -v kafkacat) ] && [ ! -z "${MSGHUB_BROKER}" ] && [ ! -z "${MSGHUB_APIKEY}" ]; then
    echo "${OUTPUT}" \
      | kafkacat \
          -P \
          -b "${MSGHUB_BROKER}" \
          -X api.version.request=true \
          -X security.protocol=sasl_ssl \
          -X sasl.mechanisms=PLAIN \
          -X sasl.username=iamapikey \
          -X sasl.password="${MSGHUB_APIKEY}" \
          -t "${HZN_PATTERN}/${HZN_DEVICE_ID}"
  else
    echo "+++ WARN $0 $$ -- kafka invalid; output = ${OUTPUT}" &> /dev/stderr
  fi

  # wait until 
  sleep 60

done

