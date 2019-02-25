#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

# more defaults for testing
if [ -z "${YOLO4MOTION_HOST:-}" ]; then YOLO4MOTION_GROUP='localhost'; fi
if [ -z "${YOLO4MOTION_GROUP:-}" ]; then YOLO4MOTION_GROUP='motion'; fi
if [ -z "${YOLO4MOTION_DEVICE:-}" ]; then YOLO4MOTION_DEVICE='+'; fi
if [ -z "${YOLO4MOTION_CAMERA:-}" ]; then YOLO4MOTION_CAMERA='+'; fi
if [ -z "${YOLO4MOTION_TOPIC:-}" ]; then YOLO4MOTION_TOPIC="${YOLO4MOTION_GROUP}/${YOLO4MOTION_DEVICE}/${YOLO4MOTION_CAMERA}"; fi
if [ -z "${YOLO4MOTION_TOPIC_EVENT:-}" ]; then YOLO4MOTION_TOPIC_EVENT='event/end'; fi
if [ -z "${YOLO4MOTION_TOPIC_IMAGE:-}" ]; then YOLO4MOTION_TOPIC_IMAGE='image'; fi

# source yolo functions
source /usr/bin/yolo-tools.sh

# configure YOLO
CONFIG=$(yolo_init)
yolo_config ${YOLO_CONFIG}

# update service status
echo "${CONFIG}" | jq '.date='$(date +%s) > ${TMP}/$$
mv -f ${TMP}/$$ ${TMP}/${SERVICE_LABEL}.json

# start in darknet
cd ${DARKNET}

###################

if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- listening to ${YOLO4MOTION_HOST} on topic: ${YOLO4MOTION_TOPIC}/${YOLO4MOTION_TOPIC_EVENT}" &> /dev/stderr; fi

# listen forever
mosquitto_sub -h "${YOLO4MOTION_HOST}" -t "${YOLO4MOTION_TOPIC}/${YOLO4MOTION_TOPIC_EVENT}" | while read; do

  # test for null
  if [ ! -z "${REPLY}" ]; then 
    DEVICE=$(echo "${REPLY}" | jq -r '.device')
    CAMERA=$(echo "${REPLY}" | jq -r '.camera')
    if [ -z "${DEVICE}" ] || [ -z "${CAMERA}" ] || [ "${DEVICE}" == 'null' ] || [ "${CAMERA}" == 'null' ]; then
      # invalid payload
      if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- invalid event; continuing:" $(echo "${REPLY}" | jq -c '.') &> /dev/stderr; fi
      continue
    fi
  else
    # null
    continue
  fi

  # name image payload
  PAYLOAD="${TMP}/${0##*/}.$$.jpg"

  ## MOCK or NOT
  if [ "${YOLO4MOTION_USE_MOCK:-}" == 'true' ]; then 
    rm -f "${PAYLOAD}"
    touch "${PAYLOAD}"
  else 
    # build image topic
    TOPIC="${YOLO4MOTION_GROUP}/${DEVICE}/${CAMERA}/${YOLO4MOTION_TOPIC_IMAGE}"
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- listening to ${YOLO4MOTION_HOST} on topic: ${TOPIC}" &> /dev/stderr; fi
    # get image
    mosquitto_sub -C 1 -h "${YOLO4MOTION_HOST}" -t "${TOPIC}"  > "${PAYLOAD}"
  fi

  if [ -z "${ITERATION:-}" ]; then ITERATION=0; else ITERATION=$((ITERATION+1)); fi
  IMAGE=$(yolo_process "${PAYLOAD}" "${ITERATION}")

  # send annotated image back to MQTT
  TOPIC="${YOLO4MOTION_GROUP}/${DEVICE}/${CAMERA}/${YOLO4MOTION_TOPIC_IMAGE}/${YOLO_ENTITY}"
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- publishing to ${YOLO4MOTION_HOST} on topic: ${TOPIC}" &> /dev/stderr; fi
  jq -r '.image' "${IMAGE}" | base64 --decode > "${TMP}/${0##*/}.$$.jpeg"
  mosquitto_pub -h "${YOLO4MOTION_HOST}" -t "${TOPIC}" -f "${TMP}/${0##*/}.$$.jpeg"
  rm -f "${TMP}/${0##*/}.$$.jpeg"

  # initiate payload
  PAYLOAD="${TMP}/${0##*/}.$$.json"
  echo "${CONFIG}" | jq '.date='$(date +%s)'|.entity="'${YOLO_ENTITY}'"|.scale="'${YOLO_SCALE}'"|.event='"${REPLY}" > "${PAYLOAD}"

  # add two files
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- IMAGE: ${IMAGE}" $(jq -c '.image=(.image!=null)' ${IMAGE}) &> /dev/stderr; fi
  jq -s add "${PAYLOAD}" "${IMAGE}" > "${PAYLOAD}.$$" && mv -f "${PAYLOAD}.$$" "${PAYLOAD}"
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- PAYLOAD: ${PAYLOAD}:" $(jq -c '.image=(.image!=null)|.names=(.names!=null)' "${PAYLOAD}") &> /dev/stderr; fi

  if [ -s "${PAYLOAD}" ]; then
    mv -f "${PAYLOAD}" "${TMP}/${SERVICE_LABEL}.json"
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- ${TMP}/${SERVICE_LABEL}.json:" $(jq -c '.image=(.image!=null)|.names=(.names!=null)' "${TMP}/${SERVICE_LABEL}.json") &> /dev/stderr; fi

    # send annotated event back to MQTT
    TOPIC="${YOLO4MOTION_GROUP}/${DEVICE}/${CAMERA}/${YOLO4MOTION_TOPIC_EVENT}/${YOLO_ENTITY}"
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- publishing to ${YOLO4MOTION_HOST} on topic: ${TOPIC}" &> /dev/stderr; fi
    mosquitto_pub -h "${YOLO4MOTION_HOST}" -t "${TOPIC}" -f "${TMP}/${SERVICE_LABEL}.json"

  else
    if [ "${DEBUG:-}" == 'true' ]; then echo "*** ERROR $0 $$ -- failed to create PAYLOAD" &> /dev/stderr; fi
  fi
  rm -f "${IMAGE}"
done
