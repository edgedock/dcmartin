#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

JSON='[{"name":"cpu","url":"http://cpu"}]'

if [ -z "${MOTION_DEVICE_NAME:-}" ]; then
  if [ -z "${HZN_DEVICE_ID}" ]; then
    IPADDR=$(hostname -i | awk '{ print $1 }' | awk -F\. '{ printf("%03d%03d%03d%03d\n", $1, $2, $3, $4) }')
    MOTION_DEVICE_NAME="$(hostname)-${IPADDR}"
  else
    MOTION_DEVICE_NAME="${HZN_DEVICE_ID}"
  fi
fi

CONFIG='{"date":'$(date +%s)',"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"db":"'${MOTION_DEVICE_DB}'","name":"'${MOTION_DEVICE_NAME}'","timezone":"'$MOTION_TIMEZONE'","mqtt":{"host":"'${MOTION_MQTT_HOST}'","port":"'${MOTION_MQTT_PORT}'","username":"'${MOTION_MQTT_USERNAME}'","password":"'${MOTION_MQTT_PASSWORD}'"},"motion":{"post":"'${MOTION_POST_PICTURES}'"},"period":'${MOTION_PERIOD}'}' 
if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- config: ${CONFIG}" 2> /dev/stderr; fi

## services consumed
SERVICES=$(echo "${JSON}" | jq -r '.[]|.name')
CONFIG=$(echo "${CONFIG}" | jq '.services=['$(echo "${SERVICES}" | fmt | sed 's| |","|g' | sed 's|\(.*\)|"\1"|')']')
if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- SERVICES: ${SERVICES}" 2> /dev/stderr; fi

## initialize service output ASAP
echo "${CONFIG}" > "${TMP}/${SERVICE_LABEL}.json"

ZONEINFO="/usr/share/zoneinfo/${MOTION_TIMEZONE}"
if [ -e "${ZONEINFO}" ]; then
  cp "${ZONEINFO}" /etc/localtime
  if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- zoneinfo: ${ZONEINFO}" 2> /dev/stderr; fi
else
  echo "+++ WARN $0 $$ -- cannot locate time zone information: ${ZONEINFO}" &> /dev/stderr
fi

###
### MOTION
### 

start_motion() {
  DIR=/var/lib/motion
  rm -fr "${DIR}"
  mkdir -p "${TMP}/${0##*/}"
  ln -s "${TMP}/${0##*/}" "${DIR}"
  # start motion
  CMD=$(command -v motion)
  if [ -z "${CMD}" ]; then echo "*** ERROR $0 $$ -- cannot find motion executable; exiting" &> /dev/stderr; fi
  ${CMD} -n -b ${MOTION_LOG_LEVEL} -k ${MOTION_LOG_TYPE} -c /etc/motion/motion.conf -l /dev/stderr &
  # get pid
  PID=$(ps | awk '{ print $1, $4 }' | grep "${CMD}" | awk '{ print $1 }' | head -1)
  if [ -z "${PID}" ]; then PID=0; fi
  # add PID to CONFIG
  CONFIG=$(echo "${CONFIG}" | jq '.pid='"${PID}")
  if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- PID: ${PID}" 2> /dev/stderr; fi
}


###
### FUNCTIONS
###

## update services functions
update_services() {
  # get time
  SECONDS=$(date +%s)
  # merge services
  if [ ${SECONDS} -gt ${WHEN} ]; then
    OUTPUT='{}'
    for S in $SERVICES; do
      URL=$(echo "${JSON}" | jq -r '.[]|select(.name=="'${S}'").url')
      if [ ! -z "${URL}" ]; then
        OUT=$(curl -fsSL "${URL}" 2> /dev/null | jq '.'"${S}")
      fi
      if [ -z "${OUT:-}" ]; then
        OUT='null'
      fi
      if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- ${S} = ${OUT}" &> /dev/stderr; fi
      OUTPUT=$(echo "${OUTPUT:-}" | jq '.'"${S}"'='"${OUT}")
    done
    echo "${OUTPUT}" > ${TMP}/$$ 
    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- collected services:" $(jq -c '.' "${TMP}/$$") &> /dev/stderr; fi
    jq -s 'reduce .[] as $item ({}; . * $item)' "${OUTPUT_FILE}" "${TMP}/$$" > "${OUTPUT_FILE}.$$" && mv -f "${OUTPUT_FILE}.$$" "${OUTPUT_FILE}"
    rm -f "${TMP}/$$"
    WHEN=$((SECONDS+MOTION_PERIOD))
  else
    if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- skipping services" &> /dev/stderr; fi
  fi
}

## update service output
update_output() {
  update_services
  jq '.date='$(date +%s) "${OUTPUT_FILE}" > "${TMP}/$$" && mv -f "${TMP}/$$" "${OUTPUT_FILE}"
  jq '.' "${OUTPUT_FILE}" > "${TMP}/${SERVICE_LABEL}.json"
}

###
### MAIN
###

## start motion
start_motion

## initialize
WHEN=0
SECONDS=$(date +%s)
DATE=$(echo "${SECONDS} / ${MOTION_PERIOD} * ${MOTION_PERIOD}" | bc)
OUTPUT_FILE="${TMP}/${SERVICE_LABEL}.${DATE}.json"
echo "${CONFIG}" > "${OUTPUT_FILE}"

## forever
while true; do 
  # update output
  update_output
  # wait (forever) on changes in ${DIR}
  inotifywait -m -r -e close_write --format '%w%f' "${DIR}" | while read FULLPATH; do
    if [ ! -z "${FULLPATH}" ]; then 
      # process updates
      case "${FULLPATH##*/}" in
	*-*-*.json)
	  if [ -s "${FULLPATH}" ]; then
	    OUT=$(jq '.' "${FULLPATH}")
	    if [ -z "${OUT}" ]; then OUT='null'; fi
	    # don't update always
	    if [ "${MOTION_POST_PICTURES}" == 'all' ]; then
	      jq '.motion.image='"${OUT}" "${OUTPUT_FILE}" > "${OUTPUT_FILE}.$$" && mv -f "${OUTPUT_FILE}.$$" "${OUTPUT_FILE}"
	      IMAGE_PATH="${FULLPATH%.*}.jpg"
	      if [ -s "${IMAGE_PATH}" ]; then
		IMG_B64_FILE="${TMP}/${IMAGE_PATH##*/}"; IMG_B64_FILE="${IMG_B64_FILE%.*}.b64"
		base64 -w 0 "${IMAGE_PATH}" | sed -e 's|\(.*\)|{"motion":{"image":{"base64":"\1"}}}|' > "${IMG_B64_FILE}"
	      fi
	    fi
	  else
	    echo "+++ WARN $0 $$ -- no content in ${FULLPATH}; continuing..." &> /dev/stderr
            continue
	  fi
	  if [ "${MOTION_POST_PICTURES}" != 'all' ]; then 
	    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- ${FULLPATH}: posting ONLY ${MOTION_POST_PICTURES} picture; continuing..." &> /dev/stderr; fi
	    continue
          fi
	  ;;
	*-*.json)
	  if [ -s "${FULLPATH}" ]; then
	    OUT=$(jq '.' "${FULLPATH}")
	    if [ -z "${OUT}" ]; then OUT='null'; fi
	    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- EVENT:" $(echo "${OUT}" | jq -c .) &> /dev/stderr; fi
	  else
	    echo "+++ WARN $0 $$ -- EVENT: no content in ${FULLPATH}" &> /dev/stderr
	    continue
	  fi
	  # test for end
	  IMAGES=$(jq -r '.images[]?' "${FULLPATH}")
	  if [ -z "${IMAGES}" ] || [ "${IMAGES}" == 'null' ]; then 
	    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- ${FULLPATH}: EVENT start; continuing..." &> /dev/stderr; fi
            continue
	  else
	    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- ${FULLPATH}: EVENT end" &> /dev/stderr; fi
	    # update event
	    jq '.motion.event='"${OUT}" "${OUTPUT_FILE}" > "${OUTPUT_FILE}.$$" && mv -f "${OUTPUT_FILE}.$$" "${OUTPUT_FILE}"
	    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- EVENT: updated ${OUTPUT_FILE} with event JSON:" $(echo "${OUT}" | jq -c) &> /dev/stderr; fi
	    # check for GIF
	    IMAGE_PATH="${FULLPATH%.*}.gif"
	    if [ -s "${IMAGE_PATH}" ]; then
	      GIF_B64_FILE="${TMP}/${IMAGE_PATH##*/}"; GIF_B64_FILE="${GIF_B64_FILE%.*}.b64"
	      if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- EVENT: found GIF: ${IMAGE_PATH}; creating ${GIF_B64_FILE}" &> /dev/stderr; fi
	      base64 -w 0 "${IMAGE_PATH}" | sed -e 's|\(.*\)|{"motion":{"event":{"base64":"\1"}}}|' > "${GIF_B64_FILE}"
	    fi
	    # find posted picture
	    POSTED_IMAGE_JSON=$(jq -r '.image?' "${FULLPATH}")
	    if [ ! -z "${POSTED_IMAGE_JSON}" ] && [ "${POSTED_IMAGE_JSON}" != 'null' ]; then
	      PID=$(echo "${POSTED_IMAGE_JSON}" | jq -r '.id?')
	      if [ ! -z "${PID}" ] && [ "${PID}" != 'null' ]; then
		IMAGE_PATH="${FULLPATH%/*}/${PID}.jpg"
		if [ -s  "${IMAGE_PATH}" ]; then
		  IMG_B64_FILE="${TMP}/${IMAGE_PATH##*/}"; IMG_B64_FILE="${IMG_B64_FILE%.*}.b64"
		  base64 -w 0 "${IMAGE_PATH}" | sed -e 's|\(.*\)|{"motion":{"image":{"base64":"\1"}}}|' > "${IMG_B64_FILE}"
		fi
	      fi
	      rm -f "${IMAGE_PATH}"
	      # update output to posted image
	      jq '.motion.image='"${POSTED_IMAGE_JSON}" "${OUTPUT_FILE}" > "${OUTPUT_FILE}.$$" && mv -f "${OUTPUT_FILE}.$$" "${OUTPUT_FILE}"
	    fi
	    # cleanup
	    for I in ${IMAGES}; do
	      IP="${FULLPATH%/*}/${I}.jpg"
	      if [ -e "${IP}" ]; then 
		rm -f "${IP}" "${IP%%.*}.json"
	      else
		echo "+++ WARN $0 $$ -- no file at ${IP}" &> /dev/stderr
	      fi
	    done
	    rm -f "${FULLPATH}"
	  fi
	  ;;
	*)
	  if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- ${FULLPATH}; continuing..." &> /dev/stderr; fi
	  continue
	  ;;
      esac
    else
      if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- timeout" 2> /dev/stderr; fi
    fi
    # merge image base64 iff exists
    if [ ! -z "${IMG_B64_FILE:-}" ] && [ -s "${IMG_B64_FILE}" ]; then
      if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- found ${IMG_B64_FILE}" &> /dev/stderr; fi
      jq -s 'reduce .[] as $item ({}; . * $item)' "${OUTPUT_FILE}" "${IMG_B64_FILE}" > "${IMG_B64_FILE}.$$" && mv "${IMG_B64_FILE}.$$" "${OUTPUT_FILE}"
      rm -f "${IMG_B64_FILE}"
      IMG_B64_FILE=
    fi
    # merge GIF base64 iff exists
    if [ ! -z "${GIF_B64_FILE:-}" ] && [ -s "${GIF_B64_FILE}" ]; then
    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- found ${GIF_B64_FILE}" &> /dev/stderr; fi
      jq -s 'reduce .[] as $item ({}; . * $item)' "${OUTPUT_FILE}" "${GIF_B64_FILE}" > "${GIF_B64_FILE}.$$" && mv "${GIF_B64_FILE}.$$" "${OUTPUT_FILE}"
      rm -f "${GIF_B64_FILE}"
      GIF_B64_FILE=
    fi
    # update output
    update_output
  # done while reading from inotify
  done 
# done forever
done 

exit 1
