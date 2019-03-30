#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh

###
### initialization
###

## initialize horizon
hzn_init

## configure service

SERVICES='[{"name": "hal", "url": "http://hal" },{"name":"cpu","url":"http://cpu"},{"name":"wan","url":"http://wan"}]'
CONFIG='{"date":'$(date +%s)',"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"services":'${SERVICES}',"period":'${YOLO2MSGHUB_PERIOD}'}'
echo "${CONFIG}" > ${TMPDIR}/${SERVICE_LABEL}.json

## initialize servive
service_init ${CONFIG}

###
### MAIN
###

## initial output
OUTPUT_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$.json"
echo '{"date":'$(date +%s)'}' > "${OUTPUT_FILE}"
service_update "${OUTPUT_FILE}"

# make topic
TOPIC=$(curl -sSL -H 'Content-Type: application/json' -H "X-Auth-Token: ${YOLO2MSGHUB_APIKEY}" "${YOLO2MSGHUB_ADMIN_URL}/admin/topics" -d '{"name":"'${SERVICE_LABEL}'"}')
if [ "$(echo "${TOPIC}" | jq '.errorCode!=null')" == 'true' ]; then
  echo "+++ WARN $0 $$ -- topic ${SERVICE_LABEL} message:" $(echo "${TOPIC}" | jq -r '.errorMessage') &> /dev/stderr
fi

## configure service we're sending
API='yolo'
URL="http://${API}"

while true; do
  DATE=$(date +%s)

  # get service
  PAYLOAD=$(mktemp)
  curl -sSL "${URL}" -o ${PAYLOAD} 2> /dev/null
  echo '{"date":'$(date +%s)',"'${API}'":' > ${OUTPUT_FILE}
  if [ -s "${PAYLOAD}" ]; then 
    jq '.'"${API}" ${PAYLOAD} >> ${OUTPUT_FILE}
  else
    echo 'null' >> ${OUTPUT_FILE}
  fi
  rm -f ${PAYLOAD}
  echo '}' >> ${OUTPUT_FILE}
  # output
  service_update "${OUTPUT_FILE}"

  # send via kafka
  if [ $(command -v kafkacat) ] && [ ! -z "${YOLO2MSGHUB_BROKER}" ] && [ ! -z "${YOLO2MSGHUB_APIKEY}" ]; then
      PAYLOAD=$(mktemp)
      echo "${HZN:-}" > ${PAYLOAD}
      PAYLOAD_DATA=$(mktemp)
      echo '{"date":'$(date +%s)',"'${SERVICE_LABEL}'":' > ${PAYLOAD_DATA}
      cat "${TMPDIR}/${SERVICE_LABEL}.json" >> ${PAYLOAD_DATA}
      echo '}' >> ${PAYLOAD_DATA}
      jq -s add ${PAYLOAD} ${PAYLOAD_DATA} | jq -c '.' > ${PAYLOAD}.$$ && mv -f ${PAYLOAD}.$$ ${PAYLOAD}
      if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- payload:" $(jq -c '.yolo2msghub.yolo|.image=null' ${PAYLOAD}) &> /dev/stderr; fi
      kafkacat "${PAYLOAD}" \
          -P \
          -b "${YOLO2MSGHUB_BROKER}" \
          -X api.version.request=true \
          -X security.protocol=sasl_ssl \
          -X sasl.mechanisms=PLAIN \
          -X sasl.username=${YOLO2MSGHUB_APIKEY:0:16}\
          -X sasl.password="${YOLO2MSGHUB_APIKEY:16}" \
          -t "${SERVICE_LABEL}"
      rm -f ${PAYLOAD} ${PAYLOAD_DATA}
  else
    echo "+++ WARN $0 $$ -- kafka invalid" &> /dev/stderr
  fi

  # wait for ..
  SECONDS=$((YOLO2MSGHUB_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi
done
