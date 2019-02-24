#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

# temporary image and output
JPG="${TMP}/image.$$.jpg"
OUT="${TMP}/image.$$.out"

# defaults for testing
if [ -z "${YOLO_PERIOD:-}" ]; then YOLO_PERIOD=0; fi
if [ -z "${YOLO_ENTITY:-}" ]; then YOLO_ENTITY=person; fi
if [ -z "${YOLO_THRESHOLD:-}" ]; then YOLO_THRESHOLD=0.25; fi
if [ -z "${YOLO_SCALE:-}" ]; then YOLO_SCALE="320x240"; fi
if [ -z "${YOLO_CONFIG}" ]; then YOLO_CONFIG="tiny"; fi
if [ -z "${DARKNET}" ]; then echo "*** ERROR -- $0 $$ -- DARKNET unspecified; set environment variable for testing"; fi

yolo_config() {
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- YOLO config: ${1}" &> /dev/stderr; fi
  case ${1} in
    tiny)
      DARKNET_WEIGHTS="http://pjreddie.com/media/files/yolov2-tiny-voc.weights"
      YOLO_WEIGHTS="${DARKNET}/yolov2-tiny-voc.weights"
      YOLO_CFG_FILE="${DARKNET}/cfg/yolov2-tiny-voc.cfg"
      YOLO_DATA="${DARKNET}/cfg/voc.data"
    ;;
    v2)
      DARKNET_WEIGHTS="https://pjreddie.com/media/files/yolov2.weights"
      YOLO_WEIGHTS="${DARKNET}/yolov2.weights"
      YOLO_CFG_FILE="${DARKNET}/cfg/yolov2.cfg"
      YOLO_DATA="${DARKNET}/cfg/coco.data"
    ;;
    v3)
      DARKNET_WEIGHTS="https://pjreddie.com/media/files/yolov3.weights"
      YOLO_WEIGHTS="${DARKNET}/yolov3.weights"
      YOLO_CFG_FILE="${DARKNET}/cfg/yolov3.cfg"
      YOLO_DATA="${DARKNET}/cfg/coco.data"
    ;;
    *)
      if [ "${DEBUG:-}" == 'true' ]; then echo "*** ERROR -- $0 $$ -- invalid YOLO_CONFIG: ${1}; exiting" &> /dev/stderr; fi
      exit 1
    ;;
  esac
    if [ ! -s "${YOLO_WEIGHTS}" ]; then
      if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- YOLO config: ${1}; updating ${YOLO_WEIGHTS} from ${DARKNET_WEIGHTS}" &> /dev/stderr; fi
      curl -m 60 -fsSL ${DARKNET_WEIGHTS} -o ${YOLO_WEIGHTS}
      if [ ! -s "${YOLO_WEIGHTS}" ]; then
        if [ "${DEBUG:-}" == 'true' ]; then echo "*** ERROR -- $0 $$ -- YOLO config: ${1}; failed to download: ${DARKNET_WEIGHTS}" &> /dev/stderr; fi
      fi
    fi
  # same for all configurations
  YOLO_NAMES="${DARKNET}/data/coco.names"
}

# configure YOLO
yolo_config ${YOLO_CONFIG}

# build configuation
CONFIG='{"log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-}',"date":'$(date +%s)',"period":'${YOLO_PERIOD}',"entity":"'${YOLO_ENTITY}'","config":"'${YOLO_CONFIG}'","threshold":'${YOLO_THRESHOLD}'}'

# update service output to configuration
echo "${CONFIG}" > ${TMP}/${SERVICE_LABEL}.json

# get names of entities that can be detected
if [ -s "${YOLO_NAMES}" ]; then
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- processing ${YOLO_NAMES}" &> /dev/stderr; fi
  NAMES='['$(awk -F'|' '{ printf("\"%s\"", $1) }' "${YOLO_NAMES}" | sed 's|""|","|g')']'
fi
if [ -z "${NAMES:-}" ]; then NAMES='["person"]'; fi
CONFIG=$(echo "${CONFIG}" | jq '.names='"${NAMES}")

# update service status
echo "${CONFIG}" | jq '.date='$(date +%s) > ${TMP}/$$
mv -f ${TMP}/$$ ${TMP}/${SERVICE_LABEL}.json

# start in darknet
cd ${DARKNET}

if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- processing images from /dev/video0 every ${YOLO_PERIOD} seconds" &> /dev/stderr; fi

while true; do
  # when we start
  DATE=$(date +%s)

  # initiate payload
  PAYLOAD="${TMP}/${0##*/}.$$.jpg"

  # capture image from /dev/video0 and grab file attributes for later use
  fswebcam --no-banner "${PAYLOAD}" &> /dev/null

  # initiate output
  OUTPUT="${CONFIG}"

  # test image 
  if [ ! -s "${PAYLOAD}" ]; then 
    MOCKS=( dog giraffe kite eagle horses person scream )
    if [ -z "${MOCK_COUNT:-}" ]; then MOCK_COUNT=0; else MOCK_COUNT=$((MOCK_COUNT+1)); fi
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- MOCK index: ${MOCK_COUNT} of ${#MOCKS[@]}" &> /dev/stderr; fi
    if [ ${MOCK_COUNT} -ge ${#MOCKS[@]} ]; then MOCK_COUNT=0; fi
    MOCK="${MOCKS[${MOCK_COUNT}]}"
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- MOCK image: ${MOCK}" &> /dev/stderr; fi
    cp -f "data/${MOCK}.jpg" ${PAYLOAD}
    # update output to be mock
    OUTPUT=$(echo "${OUTPUT}" | jq '.mock="'${MOCK}'"')
  fi

  # scale image
  if [ "${YOLO_SCALE}" != 'none' ]; then
    convert -scale "${YOLO_SCALE}" "${PAYLOAD}" "${JPG}"
  else
    mv -f "${PAYLOAD}" "${JPG}"
  fi
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- JPEG: ${JPG}; size:" $(wc -c "${JPG}" | awk '{ print $1 }') &> /dev/stderr; fi

  # get image information
  INFO=$(identify "${JPG}" | awk '{ printf("{\"type\":\"%s\",\"size\":\"%s\",\"bps\":\"%s\",\"color\":\"%s\"}", $2, $3, $5, $6) }' | jq -c '.')
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- INFO: ${INFO}" &> /dev/stderr; fi

  ## do YOLO
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- DARKNET: ./darknet detector test ${YOLO_DATA} ${YOLO_CFG_FILE} ${YOLO_WEIGHTS} ${JPG} -thresh ${YOLO_THRESHOLD}" &> /dev/stderr; fi
  ./darknet detector test "${YOLO_DATA}" "${YOLO_CFG_FILE}" "${YOLO_WEIGHTS}" "${JPG}" -thresh "${YOLO_THRESHOLD}" > "${OUT}" 2> "${TMP}/darknet.$$.out"
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
        if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- detected nothing" &> /dev/stderr; fi
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

  # capture annotated image as BASE64 encoded string
  IMAGE="${TMP}/predictions.$$.json"
  echo -n '{"image":"' > "${IMAGE}"
  base64 -w 0 -i predictions.jpg >> "${IMAGE}"
  echo '"}' >> "${IMAGE}"

  # cleanup
  rm -f "${JPG}" "${OUT}" predictions.jpg

  # initiate payload
  PAYLOAD="${TMP}/${0##*/}.$$.json"
  echo "${OUTPUT}" | jq '.date='$(date +%s)'|.time='${TIME}'|.info='${INFO}'|.detected='${DETECTED}'|.entity="'${YOLO_ENTITY}'"|.count='${TOTAL}'|.scale="'${YOLO_SCALE}'"' > "${PAYLOAD}"
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
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- sleep ${SECONDS}" &> /dev/stderr; fi
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi

done
