#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

JSON='[{"name": "yolo", "url": "http://yolo:80" },{"name": "hal", "url": "http://hal:80" },{"name":"cpu","url":"http://cpu:80"},{"name":"wan","url":"http://wan:80"}]'

CONFIG='{"log_level":"'${LOG_LEVEL}'","debug":"'${DEBUG}'","services":'${JSON}',"port":'${YOLO2MSGHUB_PORT}'}'
echo "${CONFIG}" > ${TMP}/${HZN_PATTERN}.json

SERVICES=$(echo "${JSON}" | jq -r '.[]|.name')

while true; do

  # make output
  OUTPUT=$(echo "${CONFIG}" | jq '.date='$(date +%s))
  for SERVICE in $SERVICES; do
    URL=$(echo "${JSON}" | jq -r '.[]|select(.name=="'${SERVICE}'").url')
    if [ ! -z "${URL}" ]; then
      OUT=$(curl -fqsSL "${URL}" | jq '.'"${SERVICE}"'?')
    fi
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- ${SERVICE} returns ${OUT}" &> /dev/stderr; fi
    if [ -z "${OUT:-}" ]; then
      OUT='null'
    fi
    OUTPUT=$(echo "${OUTPUT:-}" | jq '.'"${SERVICE}"'='"${OUT}")
  done

  echo "${OUTPUT}" > "${TMP}/${HZN_PATTERN}.json"

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
          -t "${HZN_PATTERN}/${HZN_DEVICE_ID}"
  else
    echo "+++ WARN $0 $$ -- kafka invalid" &> /dev/stderr
  fi

done

