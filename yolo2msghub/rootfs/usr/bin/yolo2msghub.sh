#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

JSON='[{"name": "yolo", "url": "http://yolo:80" },{"name": "hal", "url": "http://hal:80" },{"name":"cpu","url":"http://cpu:80"},{"name":"wan","url":"http://wan:80"}]'

CONFIG='{"log_level":"'${LOG_LEVEL}'","debug":"'${DEBUG}'","services":'${JSON}'}'
echo "${CONFIG}" > ${TMP}/${SERVICE_LABEL}.json

SERVICES=$(echo "${JSON}" | jq -r '.[]|.name')

while true; do

  # make output
  OUTPUT=$(echo "${CONFIG}" | jq '.date='$(date +%s))
  for S in $SERVICES; do
    URL=$(echo "${JSON}" | jq -r '.[]|select(.name=="'${S}'").url')
    if [ ! -z "${URL}" ]; then
      OUT=$(curl -sSL "${URL}" 2> /dev/null | jq '.'"${S}")
    fi
    if [ -z "${OUT:-}" ]; then
      OUT='null'
    fi
    OUTPUT=$(echo "${OUTPUT:-}" | jq '.'"${S}"'='"${OUT}")
  done

  echo "${OUTPUT}" > "${TMP}/${SERVICE_LABEL}.json"

  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- output: ${OUTPUT}" &> /dev/stderr; fi

  # send output
  if [ $(command -v kafkacat) ] && [ ! -z "${YOLO2MSGHUB_BROKER}" ] && [ ! -z "${YOLO2MSGHUB_APIKEY}" ]; then
    echo "${OUTPUT}" \
      | kafkacat \
          -P \
          -b "${YOLO2MSGHUB_BROKER}" \
          -X api.version.request=true \
          -X security.protocol=sasl_ssl \
          -X sasl.mechanisms=PLAIN \
          -X sasl.username=iamapikey \
          -X sasl.password="${YOLO2MSGHUB_APIKEY}" \
          -t "${SERVICE_LABEL}/${HZN_DEVICE_ID}"
  else
    echo "+++ WARN $0 $$ -- kafka invalid" &> /dev/stderr
  fi

  if [ "${DEBUG:-}" == 'true' ]; then sleep 300; fi

done

