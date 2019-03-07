#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

JSON='[{"name": "yolo", "url": "http://yolo" },{"name": "hal", "url": "http://hal" },{"name":"cpu","url":"http://cpu"},{"name":"wan","url":"http://wan"}]'

# OPTIONS
OPTIONS='{"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"services":'${JSON}',"period":'${YOLO2MSGHUB_PERIOD}'}'
echo "${OPTIONS}" > ${TMPDIR}/${SERVICE_LABEL}.json

# make topic
TOPIC=$(curl -sSL -H 'Content-Type: application/json' -H "X-Auth-Token: ${YOLO2MSGHUB_APIKEY}" "${YOLO2MSGHUB_ADMIN_URL}/admin/topics" -d '{"name":"'${SERVICE_LABEL}'"}')
if [ "$(echo "${TOPIC}" | jq '.errorCode!=null')" == 'true' ]; then
  echo "+++ WARN $0 $$ -- topic ${SERVICE_LABEL} message:" $(echo "${TOPIC}" | jq -r '.errorMessage') &> /dev/stderr
fi

# do all SERVICES forever
SERVICES=$(echo "${JSON}" | jq -r '.[]|.name')
while true; do
  DATE=$(date +%s)
  OUTPUT=$(mktemp)
  echo ${OPTIONS} | jq '.date='$(date +%s) > ${OUTPUT}
  # process all services
  for S in $SERVICES; do
    URL=$(echo "${JSON}" | jq -r '.[]|select(.name=="'${S}'").url')
    if [ ! -z "${URL}" ]; then
      TEMP_FILE=$(mktemp)
      curl -sSL "${URL}" | jq -c '.'"${S}" > ${TEMP_FILE} 2> /dev/null
      TEMP_OUTPUT=$(mktemp)
      echo '{"'${S}'":' > ${TEMP_OUTPUT}
      if [ -s ${TEMP_FILE} ]; then
        cat ${TEMP_FILE} >> ${TEMP_OUTPUT}
      else
        echo 'null' >> ${TEMP_OUTPUT}
      fi
      echo '}' >> ${TEMP_OUTPUT}
      # add to output
      jq -s add ${TEMP_OUTPUT} ${OUTPUT} > ${OUTPUT}.$$ && mv -f ${OUTPUT}.$$ ${OUTPUT}
      # cleanup
      rm -f ${TEMP_FILE} ${TEMP_OUTPUT}
    fi
  done

  # update output with current date
  mv -f "${OUTPUT}" "${TMPDIR}/${SERVICE_LABEL}.json"

  # send via kafka
  if [ $(command -v kafkacat) ] && [ ! -z "${YOLO2MSGHUB_BROKER}" ] && [ ! -z "${YOLO2MSGHUB_APIKEY}" ]; then
      PAYLOAD=$(mktemp)
      echo "${HZN}" > ${PAYLOAD}
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

