#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

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

if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- processing images from /dev/video0 every ${YOLO_PERIOD} seconds" &> /dev/stderr; fi

while true; do
  # when we start
  DATE=$(date +%s)

  # path to image payload
  PAYLOAD="${TMP}/${0##*/}.$$.jpg"
  # capture image payload from /dev/video0
  fswebcam --no-banner "${PAYLOAD}" &> /dev/null

  # process image payload into JSON
  if [ -z "${ITERATION:-}" ]; then ITERATION=0; else ITERATION=$((ITERATION+1)); fi
  IMAGE=$(yolo_process "${PAYLOAD}" "${ITERATION}")

  # initialize output with configuration
  PAYLOAD="${TMP}/${0##*/}.$$.json"
  echo "${CONFIG}" | jq '.date='$(date +%s)'|.entity="'${YOLO_ENTITY}'"' > "${PAYLOAD}"
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- PAYLOAD: ${PAYLOAD}:" $(jq -c '.image=(.image!=null)|.names=(.names!=null)' "${PAYLOAD}") &> /dev/stderr; fi

  # add two files
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- IMAGE: ${IMAGE}" $(jq -c '.image=(.image!=null)' ${IMAGE}) &> /dev/stderr; fi
  jq -s add "${PAYLOAD}" "${IMAGE}" > "${PAYLOAD}.$$" && mv -f "${PAYLOAD}.$$" "${PAYLOAD}"
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- PAYLOAD: ${PAYLOAD}:" $(jq -c '.image=(.image!=null)|.names=(.names!=null)' "${PAYLOAD}") &> /dev/stderr; fi

  # make it atomic
  if [ -s "${PAYLOAD}" ]; then
    mv -f "${PAYLOAD}" "${TMP}/${SERVICE_LABEL}.json"
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- ${TMP}/${SERVICE_LABEL}.json:" $(jq -c '.image=(.image!=null)|.names=(.names!=null)' "${TMP}/${SERVICE_LABEL}.json") &> /dev/stderr; fi
  fi

  # wait for ..
  SECONDS=$((YOLO_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- sleep ${SECONDS}" &> /dev/stderr; fi
    sleep ${SECONDS}
  fi

done
