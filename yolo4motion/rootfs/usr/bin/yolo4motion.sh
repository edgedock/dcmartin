#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

# more defaults for testing
if [ -z "${MQTT_HOST:-}" ]; then MQTT_HOST='mqtt'; fi
if [ -z "${MQTT_PORT:-}" ]; then MQTT_PORT=1883; fi
if [ -z "${MOTION_GROUP:-}" ]; then MOTION_GROUP='motion'; fi
if [ -z "${YOLO4MOTION_DEVICE:-}" ]; then YOLO4MOTION_DEVICE='+'; fi
if [ -z "${YOLO4MOTION_CAMERA:-}" ]; then YOLO4MOTION_CAMERA='+'; fi
if [ -z "${YOLO4MOTION_TOPIC_EVENT:-}" ]; then YOLO4MOTION_TOPIC_EVENT='event/end'; fi
if [ -z "${YOLO4MOTION_TOPIC_IMAGE:-}" ]; then YOLO4MOTION_TOPIC_IMAGE='image'; fi
if [ -z "${YOLO4MOTION_TOO_OLD:-}" ]; then YOLO4MOTION_TOO_OLD=300; fi

# derived
YOLO4MOTION_TOPIC="${MOTION_GROUP}/${YOLO4MOTION_DEVICE}/${YOLO4MOTION_CAMERA}"

# MQTT
MOSQUITTO_ARGS="-h ${MQTT_HOST} -p ${MQTT_PORT}"
if [ ! -z "${MQTT_USERNAME:-}" ]; then MOSQUITTO_ARGS="${MOSQUITTO_ARGS} -u ${MQTT_USERNAME}"; fi
if [ ! -z "${MQTT_PASSWORD:-}" ]; then MOSQUITTO_ARGS="${MOSQUITTO_ARGS} -P ${MQTT_PASSWORD}"; fi

# source yolo functions
source /usr/bin/yolo-tools.sh

###
### FUNCTIONS
###

SERVICES_JSON='[{"name":"mqtt","url":"http://mqtt"}]'

## update services functions
requiredServices_update() {
  OUTPUT=${1}
  echo '{}' > "${OUTPUT}"
  SERVICES=$(echo "${SERVICES_JSON}" | jq -r '.[]|.name')
  for S in ${SERVICES}; do
    URL=$(echo "${SERVICES_JSON}" | jq -r '.[]|select(.name=="'${S}'").url')
    TEMP_FILE=$(mktemp)
    if [ ! -z "${URL}" ]; then
      curl -sSL "${URL}" | jq -c '.'"${S}" > ${TEMP_FILE} 2> /dev/null
    fi
    TEMP_OUTPUT=$(mktemp)
    echo '{"'${S}'":' > ${TEMP_OUTPUT}
    if [ -s "${TEMP_FILE:-}" ]; then
      cat ${TEMP_FILE} >> ${TEMP_OUTPUT}
    else
      echo 'null' >> ${TEMP_OUTPUT}
    fi
    rm -f ${TEMP_FILE}
    echo '}' >> ${TEMP_OUTPUT}
    jq -s add "${TEMP_OUTPUT}" "${OUTPUT}" > "${OUTPUT}.$$" && mv -f "${OUTPUT}.$$" "${OUTPUT}"
    rm -f ${TEMP_OUTPUT}
  done
  echo $?
}

## update service output
update_output() {
  OUTPUT_FILE="${1}"
  if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- update_output; OUTPUT_FILE: ${OUTPUT_FILE}" &> /dev/stderr; fi
  TEMP_FILE=$(mktemp)
  REQSVCS_OUTPUT_FILE=$(mktemp)
  if [ $(requiredServices_update ${REQSVCS_OUTPUT_FILE}) != 0 ]; then
    if [ "${DEBUG}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- requiredServices_update failed" &> /dev/stderr; fi
    jq '.' "${OUTPUT_FILE}" > "${TEMP_FILE}"
  else
    jq -s add "${REQSVCS_OUTPUT_FILE}" "${OUTPUT_FILE}" > "${TEMP_FILE}"
  fi
  rm -f "${REQSVCS_OUTPUT_FILE}"
  if [ -s "${TEMP_FILE}" ]; then
    jq '.date='$(date +%s) "${TEMP_FILE}" > "${TEMP_FILE}.$$" && mv -f "${TEMP_FILE}.$$" "${TEMP_FILE}"
  else
    if [ "${DEBUG}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- update_output: update failed" &> /dev/stderr; fi
    echo '{"date":'$(date +%s)'}' > "${TEMP_FILE}"
  fi
  SERVICE_OUTPUT_FILE="${TMPDIR}/${SERVICE_LABEL}.json"
  mv -f "${TEMP_FILE}" "${SERVICE_OUTPUT_FILE}"
}

###
### MAIN
###

# configure YOLO
CONFIG=$(yolo_init)
yolo_config ${YOLO_CONFIG}

# update service status
OUTPUT_FILE=$(mktemp)
echo "${CONFIG}" | jq '.date='$(date +%s) > ${OUTPUT_FILE}
update_output ${OUTPUT_FILE}

# start in darknet
cd ${DARKNET}

###################

if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- listening to ${MQTT_HOST} on topic: ${YOLO4MOTION_TOPIC}/${YOLO4MOTION_TOPIC_EVENT}" &> /dev/stderr; fi

# listen forever
mosquitto_sub ${MOSQUITTO_ARGS} -t "${YOLO4MOTION_TOPIC}/${YOLO4MOTION_TOPIC_EVENT}" | while read; do

  # test for null
  if [ ! -z "${REPLY}" ]; then 
    DATE=$(echo "${REPLY}" | jq -r '.date')
    NOW=$(date +%s)
    if [ $((NOW - DATE)) -gt ${YOLO4MOTION_TOO_OLD} ]; then echo "+++ WARN -- $0 $$ -- too old: ${REPLY}" &> /dev/stderr; continue; fi
    DEVICE=$(echo "${REPLY}" | jq -r '.device')
    CAMERA=$(echo "${REPLY}" | jq -r '.camera')
    if [ -z "${DEVICE}" ] || [ -z "${CAMERA}" ] || [ "${DEVICE}" == 'null' ] || [ "${CAMERA}" == 'null' ]; then
      # invalid payload
      if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- invalid event; continuing:" $(echo "${REPLY}" | jq -c '.') &> /dev/stderr; fi
      continue
    fi
  else
    # null
    continue
  fi

  # name image payload
  PAYLOAD="${TMPDIR}/${0##*/}.$$.jpg"

  ## MOCK or NOT
  if [ "${YOLO4MOTION_USE_MOCK:-}" == 'true' ]; then 
    rm -f "${PAYLOAD}"
    touch "${PAYLOAD}"
  else 
    # build image topic
    TOPIC="${MOTION_GROUP}/${DEVICE}/${CAMERA}/${YOLO4MOTION_TOPIC_IMAGE}"
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- listening to ${MQTT_HOST} on topic: ${TOPIC}" &> /dev/stderr; fi
    # get image
    mosquitto_sub ${MOSQUITTO_ARGS} -C 1 -t "${TOPIC}"  > "${PAYLOAD}"
  fi

  if [ -z "${ITERATION:-}" ]; then ITERATION=0; else ITERATION=$((ITERATION+1)); fi
  IMAGE=$(yolo_process "${PAYLOAD}" "${ITERATION}")

  # send annotated image back to MQTT
  TOPIC="${MOTION_GROUP}/${DEVICE}/${CAMERA}/${YOLO4MOTION_TOPIC_IMAGE}/${YOLO_ENTITY}"
  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- publishing to ${MQTT_HOST} on topic: ${TOPIC}" &> /dev/stderr; fi
  jq -r '.image' "${IMAGE}" | base64 --decode > "${TMPDIR}/${0##*/}.$$.jpeg"
  mosquitto_pub -r -q 2 ${MOSQUITTO_ARGS} -t "${TOPIC}" -f "${TMPDIR}/${0##*/}.$$.jpeg"
  rm -f "${TMPDIR}/${0##*/}.$$.jpeg"

  # initiate payload
  PAYLOAD="${TMPDIR}/${0##*/}.$$.json"
  echo "${CONFIG}" | jq '.date='$(date +%s)'|.entity="'${YOLO_ENTITY}'"|.scale="'${YOLO_SCALE}'"|.event='"${REPLY}" > "${PAYLOAD}"

  # add two files
  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- IMAGE: ${IMAGE}" $(jq -c '.image=(.image!=null)' ${IMAGE}) &> /dev/stderr; fi
  jq -s add "${PAYLOAD}" "${IMAGE}" > "${PAYLOAD}.$$" && mv -f "${PAYLOAD}.$$" "${PAYLOAD}"
  if [ -s "${PAYLOAD}" ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- PAYLOAD: ${PAYLOAD}:" $(jq -c '.image=(.image!=null)|.names=(.names!=null)' "${PAYLOAD}") &> /dev/stderr; fi
    # update status
    update_output "${PAYLOAD}"
    # send annotated event back to MQTT
    TOPIC="${MOTION_GROUP}/${DEVICE}/${CAMERA}/${YOLO4MOTION_TOPIC_EVENT}/${YOLO_ENTITY}"
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- publishing to ${MQTT_HOST} on topic: ${TOPIC}" &> /dev/stderr; fi
    mosquitto_pub -r -q 2 ${MOSQUITTO_ARGS} -t "${TOPIC}" -f "${TMPDIR}/${SERVICE_LABEL}.json"
  else
    if [ "${DEBUG:-}" == 'true' ]; then echo "*** ERROR -- $0 $$ -- failed to create PAYLOAD" &> /dev/stderr; fi
  fi
  rm -f "${IMAGE}"
done
