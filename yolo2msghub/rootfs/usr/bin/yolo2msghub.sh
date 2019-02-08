#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

JSON='[{"name": "yolo", "url": "http://yolo" },{"name": "hal", "url": "http://hal" },{"name":"cpu","url":"http://cpu"},{"name":"wan","url":"http://wan"}]'

# OPTIONS
OPTIONS='{"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"services":'${JSON}',"period":'${YOLO2MSGHUB_PERIOD}'}'
echo "${OPTIONS}" > ${TMP}/${SERVICE_LABEL}.json

# make topic
TOPIC=$(curl -sSL -H 'Content-Type: application/json' -H "X-Auth-Token: ${YOLO2MSGHUB_APIKEY}" "${YOLO2MSGHUB_ADMIN_URL}/admin/topics" -d '{"name":"'${SERVICE_LABEL}'"}')
if [ "$(echo "${TOPIC}" | jq '.errorCode!=null')" == 'true' ]; then
  echo "+++ WARN $0 $$ -- topic ${SERVICE_LABEL} message:" $(echo "${TOPIC}" | jq -r '.errorMessage') &> /dev/stderr
fi

# Horizon CONFIG
if [ -z "${HZN}" ]; then
  echo "*** ERROR $0 $$ -- environment HZN is unset; exiting" &> /dev/stderr
  exit 1
fi

# do all SERVICES forever
SERVICES=$(echo "${JSON}" | jq -r '.[]|.name')
while true; do
  DATE=$(date +%s)
  # make output
  OUTPUT="${OPTIONS}"
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
  OUTPUT=$(echo "${OUTPUT}" | jq '.date='$(date +%s))

  echo "${OUTPUT}" > "${TMP}/$$"
  mv -f "${TMP}/$$" "${TMP}/${SERVICE_LABEL}.json"

  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- output: ${OUTPUT}" &> /dev/stderr; fi

  # send via kafka
  if [ $(command -v kafkacat) ] && [ ! -z "${YOLO2MSGHUB_BROKER}" ] && [ ! -z "${YOLO2MSGHUB_APIKEY}" ]; then
    echo "${HZN}" | jq -c '.'${SERVICE_LABEL}'='"${OUTPUT}" \
      | kafkacat \
          -P \
          -b "${YOLO2MSGHUB_BROKER}" \
          -X api.version.request=true \
          -X security.protocol=sasl_ssl \
          -X sasl.mechanisms=PLAIN \
          -X sasl.username=${YOLO2MSGHUB_APIKEY:0:16}\
          -X sasl.password="${YOLO2MSGHUB_APIKEY:16}" \
          -t "${SERVICE_LABEL}"
  else
    echo "+++ WARN $0 $$ -- kafka invalid" &> /dev/stderr
  fi
  # wait for ..
  SLEEP=$((YOLO2MSGHUB_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SLEEP} > 0 ]; then
    sleep ${SLEEP}
  fi
done

