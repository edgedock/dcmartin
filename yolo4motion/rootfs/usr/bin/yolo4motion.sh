#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

# temporary image and output
JPG="${TMP}/image.$$.jpg"
OUT="${TMP}/image.$$.out"

if [ -z "${YOLO_ENTITY:-}" ]; then YOLO_ENTITY=all; fi
if [ -z "${YOLO_THRESHOLD:-}" ]; then YOLO_THRESHOLD=0.25; fi
if [ -z "${YOLO4MOTION_INTERVAL:-}" ]; then YOLO4MOTION_INTERVAL=500; fi
if [ -z "${YOLO_SCALE:-}" ]; then YOLO_SCALE="320x240"; fi
if [ -z "${YOLO4MOTION_GROUP:-}" ]; then YOLO4MOTION_GROUP='motion'; fi
if [ -z "${YOLO4MOTION_DEVICE:-}" ]; then YOLO4MOTION_DEVICE='+'; fi
if [ -z "${YOLO4MOTION_CAMERA:-}" ]; then YOLO4MOTION_CAMERA='+'; fi
if [ -z "${YOLO4MOTION_TOPIC:-}" ]; then YOLO4MOTION_TOPIC="${YOLO4MOTION_GROUP}/${YOLO4MOTION_DEVICE}/${YOLO4MOTION_CAMERA}"; fi
if [ -z "${YOLO4MOTION_TOPIC_EVENT:-}" ]; then YOLO4MOTION_TOPIC_EVENT='event/end'; fi
if [ -z "${YOLO4MOTION_TOPIC_IMAGE:-}" ]; then YOLO4MOTION_TOPIC_IMAGE='image'; fi

if [ -z "${DARKNET:-}" ]; then DARKNET="/darknet"; else echo "** WARNING: DARKNET from environment: ${DARKNET}" &> /dev/stderr; fi

CONFIG='{"log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-}',"date":'$(date +%s)',"host":"'${YOLO4MOTION_HOST}'","topic":"'${YOLO4MOTION_TOPIC}'","entity":"'${YOLO_ENTITY}'","threshold":'${YOLO_THRESHOLD}'}'
echo "${CONFIG}" > ${TMP}/${SERVICE_LABEL}.json

cd ${DARKNET}

# get names of entities that can be detected
YOLO_NAMES="data/coco.names"
if [ -s "${YOLO_NAMES}" ]; then
  NAMES=$(cat "${YOLO_NAMES}")
fi
if [ -z "${NAMES:-}" ]; then NAMES=person; fi

JSON=
for name in ${NAMES}; do
  if [ -z "${JSON:-}" ]; then JSON='['; else JSON="${JSON}"','; fi
  JSON="${JSON}"'"'"${name}"'"'
done
if [ -z "${JSON}" ]; then JSON='null'; else JSON="${JSON}"']'; fi
CONFIG=$(echo "${CONFIG}" | jq '.names='"${JSON}")

# update service status
echo "${CONFIG}" | jq '.date='$(date +%s) > ${TMP}/$$
mv -f ${TMP}/$$ ${TMP}/${SERVICE_LABEL}.json

if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- listening to ${YOLO4MOTION_HOST} on topic: ${YOLO4MOTION_TOPIC}/${YOLO4MOTION_TOPIC_EVENT}" &> /dev/stderr; fi

PAYLOAD="${TMP}/${0##*/}.$(($(date +%s%N)/1000000)).jpg" 

# listen forever
mosquitto_sub -h "${YOLO4MOTION_HOST}" -t "${YOLO4MOTION_TOPIC}/${YOLO4MOTION_TOPIC_EVENT}" | while read; do
  if [ -z "${REPLY}" ]; then continue; fi
  DEVICE=$(echo "${REPLY}" | jq -r '.device')
  CAMERA=$(echo "${REPLY}" | jq -r '.camera')
  if [ -z "${DEVICE}" ] || [ -z "${CAMERA}" ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- invalid event; continuing:" $(echo "${REPLY}" | jq -c '.') &> /dev/stderr; fi
    continue
  fi
  # initiate output
  OUTPUT=$(echo "${CONFIG}" | jq '.event='"${REPLY}")

  ## MOCK or NOT
  if [ "${YOLO4MOTION_USE_MOCK:-}" == 'true' ]; then 
    TOPIC="mock"
    MOCKS=( dog giraffe kite personx4 eagle horses person scream )
    if [ -z "${MOCK_COUNT}" ]; then MOCK_COUNT=1; else MOCK_COUNT=$((MOCK_COUNT+1)); fi
    MOCK_INDEX=$((MOCK_COUNT % ${#MOCKS[@]}))
    MOCK="${MOCKS[${MOCK_INDEX}]}"
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- using mock data" &> /dev/stderr; fi
    cp -f "data/${MOCK}.jpg" ${PAYLOAD}
    # update output to be mock
    OUTPUT=$(echo "${OUTPUT}" | jq '.mock="'${MOCK}'"')
  else 
    # build image topic
    TOPIC="${YOLO4MOTION_GROUP}/${DEVICE}/${CAMERA}/${YOLO4MOTION_TOPIC_IMAGE}"
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- listening to ${YOLO4MOTION_HOST} on topic: ${TOPIC}" &> /dev/stderr; fi
    # get image
    mosquitto_sub -C 1 -h "${YOLO4MOTION_HOST}" -t "${TOPIC}"  > "${PAYLOAD}"
  fi

  # scale image
  convert -scale "${YOLO_SCALE}" "${PAYLOAD}" "${JPG}"
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- JPEG: ${JPG}; size:" $(wc -c "${JPG}" | awk '{ print $1 }') &> /dev/stderr; fi

  # get image information
  INFO=$(identify "${JPG}" | awk '{ printf("{\"type\":\"%s\",\"size\":\"%s\",\"bps\":\"%s\",\"color\":\"%s\"}", $2, $3, $5, $6) }' | jq -c '.')
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- INFO: ${INFO}" &> /dev/stderr; fi

  ## do YOLO (tiny)
  ./darknet detector test cfg/voc.data cfg/yolov2-tiny-voc.cfg yolov2-tiny-voc.weights "${JPG}" -thresh "${YOLO_THRESHOLD}" > "${OUT}" 2> "${TMP}/darknet.$$.out"
  # extract processing time in seconds
  TIME=$(cat "${OUT}" | egrep "Predicted" | sed 's/.*Predicted in \([^ ]*\).*/\1/')
  if [ -z "${TIME}" ]; then TIME=0; fi
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- TIME: ${TIME}" &> /dev/stderr; fi

  if [ ! -s "${OUT}" ]; then 
    echo "+++ WARN $0 $$ -- no output: ${OUT}; continuing" &> /dev/stderr
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- darknet failed:" $(cat "${TMP}/darknet.$$.out") &> /dev/stderr; fi
    continue
  fi

  TOTAL=0
  case ${YOLO_ENTITY} in
    all)
      # find entities in output
      cat "${OUT}" | tr '\n' '\t' | sed 's/.*Predicted in \([^ ]*\) seconds. */time: \1/' | tr '\t' '\n' | tail +2 > "${OUT}.$$"
      FOUND=$(cat "${OUT}.$$" | awk -F: '{ print $1 }' | sort | uniq)
      if [ ! -z "${FOUND}" ]; then
        if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- detected:" $(echo "${FOUND}" | fmt -1000) &> /dev/stderr; fi
	JSON=
	for F in ${FOUND}; do
	  if [ -z "${JSON:-}" ]; then JSON='['; else JSON="${JSON}"','; fi
	  C=$(egrep '^'"${F}" "${OUT}.$$" | wc -l | awk '{ print $1 }')
	  COUNT='{"entity":"'"${F}"'","count":'${C}'}'
	  JSON="${JSON}""${COUNT}"
	  TOTAL=$((TOTAL+C))
	done
	rm -f "${OUT}.$$" 
	if [ -z "${JSON}" ]; then JSON='null'; else JSON="${JSON}"']'; fi
	DETECTED="${JSON}"
      else
        if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- detected nothing; TOPIC: ${TOPIC:-}" &> /dev/stderr; fi
	DETECTED='null'
	continue
      fi
      ;;
    *)
      # count single entity
      C=$(egrep '^'"${YOLO_ENTITY}" "${OUT}" | wc -l | awk '{ print $1 }')
      COUNT='{"entity":"'"${YOLO_ENTITY}"'","count":'${C}'}'
      TOTAL=$((TOTAL+C))
      DETECTED='['"${COUNT}"']'
      ;;
  esac

  # send annotated image back to MQTT
  TOPIC="${YOLO4MOTION_GROUP}/${DEVICE}/${CAMERA}/${YOLO4MOTION_TOPIC_IMAGE}/${YOLO_ENTITY}"
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- publishing to ${YOLO4MOTION_HOST} on topic: ${TOPIC}" &> /dev/stderr; fi
  mosquitto_pub -h "${YOLO4MOTION_HOST}" -t "${TOPIC}" -f predictions.jpg

  # capture annotated image as BASE64 encoded string
  IMAGE="${TMP}/predictions.$$.json"
  echo -n '{"image":"' > "${IMAGE}"
  base64 -w 0 -i predictions.jpg >> "${IMAGE}"
  echo '"}' >> "${IMAGE}"


  rm -f "${JPG}" "${OUT}" predictions.jpg

  # make it atomic
  PAYLOAD="${TMP}/${0##*/}.$(($(date +%s%N)/1000000)).json" 
  echo "${OUTPUT}" | jq '.date='$(date +%s)'|.time='${TIME}'|.info='${INFO}'|.detected='${DETECTED}'|.entity="'${YOLO_ENTITY}'"|.count='${TOTAL}'|.scale="'${YOLO_SCALE}'"' > "${PAYLOAD}"

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
