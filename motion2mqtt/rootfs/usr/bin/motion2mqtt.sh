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
if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- config: ${CONFIG}" 2> /dev/stderr; fi

## services consumed
SERVICES=$(echo "${JSON}" | jq -r '.[]|.name')
CONFIG=$(echo "${CONFIG}" | jq '.services=['$(echo "${SERVICES}" | fmt | sed 's| |","|g' | sed 's|\(.*\)|"\1"|')']')
if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- SERVICES: ${SERVICES}" 2> /dev/stderr; fi

## update
echo "${CONFIG}" > ${TMP}/${SERVICE_LABEL}.json

## update services functions
update_services() {
  OUTPUT='{}'
  for S in $SERVICES; do
      URL=$(echo "${JSON}" | jq -r '.[]|select(.name=="'${S}'").url')
      if [ ! -z "${URL}" ]; then
        OUT=$(curl -sSL "${URL}" 2> /dev/null | jq '.'"${S}")
      fi
      if [ -z "${OUT:-}" ]; then
        OUT='null'
      fi
      if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- ${S} = ${OUT}" &> /dev/stderr; fi
      OUTPUT=$(echo "${OUTPUT:-}" | jq '.'"${S}"'='"${OUT}")
  done
  echo "${OUTPUT}"
}

ZONEINFO="/usr/share/zoneinfo/${MOTION_TIMEZONE}"
if [ -e "${ZONEINFO}" ]; then
  cp "${ZONEINFO}" /etc/localtime
  if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- zoneinfo: ${ZONEINFO}" 2> /dev/stderr; fi
else
  echo "+++ WARN $0 $$ -- cannot locate time zone information: ${ZONEINFO}" &> /dev/stderr
fi

## MOTION
mkdir -p ${TMP}/motion
rm -fr /var/lib/motion
ln -s ${TMP}/motion /var/lib
# start motion
CMD=$(command -v motion)
if [ -z "${CMD}" ]; then echo "*** ERROR $0 $$ -- cannot find motion executable; exiting" &> /dev/stderr; fi
${CMD} -n -b ${MOTION_LOG_LEVEL} -k ${MOTION_LOG_TYPE} -c /etc/motion/motion.conf -l /dev/stderr &
# get pid
PID=$(ps | awk '{ print $1, $4 }' | grep "${CMD}" | awk '{ print $1 }' | head -1)
if [ -z "${PID}" ]; then PID=0; fi
# add PID to CONFIG
CONFIG=$(echo "${CONFIG}" | jq '.pid='"${PID}")
if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- PID: ${PID}" 2> /dev/stderr; fi

## update
echo "${CONFIG}" > "${TMP}/${SERVICE_LABEL}.json"

## initiate watchdog
WHEN=0


## wait on output from motion
DIR=/var/lib/motion/

OUTPUT="${CONFIG}"
OUTPUT_FILE="${TMP}/$$.output.json"
echo "${OUTPUT}" > "${OUTPUT_FILE}"

inotifywait --timeout ${MOTION_PERIOD} -m -r -e close_write --format '%w%f' "${DIR}" | while read FULLPATH; do

  if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- FULLPATH: ${FULLPATH}" 2> /dev/stderr; fi

  if [ ! -z "${FULLPATH}" ]; then
    B64_PATH=
    case "${FULLPATH##*/}" in
      *-*-*.json)
	  if [ -s "${FULLPATH}" ]; then
	    OUT=$(jq '.' "${FULLPATH}")
	    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- IMAGE:" $(echo "${OUT}" | jq -c .) &> /dev/stderr; fi
	    if [ -z "${OUT}" ]; then OUT='null'; fi
	    # OUTPUT=$(echo "${OUTPUT}" | jq '.motion.image='"${OUT}")
	    jq '.motion.image='"${OUT}" "${OUTPUT_FILE}" > "${OUTPUT_FILE}.$$" && mv -f "${OUTPUT_FILE}.$$" "${OUTPUT_FILE}"
	    IMAGE_PATH="${FULLPATH%.*}.jpg"
	    if [ -s "${IMAGE_PATH}" ]; then
	      B64_PATH="${TMP}/${IMAGE_PATH##*/}"; B64_PATH="${B64_PATH%.*}.b64"
	      base64 "${IMAGE_PATH}" | sed -e 's|\(.*\)|{"motion":{"image":{"base64":"\1"}}}|' > "${B64_PATH}"
	    fi
	  else
	    echo "+++ WARN $0 $$ -- no content in ${FULLPATH}" &> /dev/stderr
	    continue
	  fi
	  ;;
      *-*.json)
	  if [ -s "${FULLPATH}" ]; then
	    OUT=$(jq '.' "${FULLPATH}")
	    if [ -z "${OUT}" ]; then OUT='null'; fi
	    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- EVENT:" $(echo "${OUT}" | jq -c .) &> /dev/stderr; fi
	  else
	    echo "+++ WARN $0 $$ -- EVENT: no content in ${FULLPATH}" &> /dev/stderr
	    continue
	  fi
	  # test for end
	  IMAGES=$(jq -r '.images[]?' "${FULLPATH}")
	  if [ -z "${IMAGES}" ] || [ "${IMAGES}" == 'null' ]; then 
	    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- EVENT: start" &> /dev/stderr; fi
	  else
	    # update event
	    # OUTPUT=$(echo "${OUTPUT}" | jq '.motion.event='"${OUT}")
	    jq '.motion.event='"${OUT}" "${OUTPUT_FILE}" > "${OUTPUT_FILE}.$$" && mv -f "${OUTPUT_FILE}.$$" "${OUTPUT_FILE}"
	    IMAGE_PATH="${FULLPATH%.*}.jpg"
	    # check for GIF
	    IMAGE_PATH="${FULLPATH%.*}.gif"
	    if [ -s "${IMAGE_PATH}" ]; then
	      B64_PATH="${TMP}/${IMAGE_PATH##*/}"; B64_PATH="${B64_PATH%.*}.b64"
	      base64 "${IMAGE_PATH}" | sed -e 's|\(.*\)|{"motion":{"event":{"base64":"\1"}}}|' > "${B64_PATH}"
	    fi
	    # cleanup
	    for I in ${IMAGES}; do
	      IP="${FULLPATH%/*}/${I}.jpg"
	      if [ -e "${IP}" ]; then 
		if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- deleting image ${IP}" &> /dev/stderr; fi
		rm -f "${IP}" "${IP%%.*}.json"
	      else
		echo "+++ WARN $0 $$ -- no file at ${IP}" &> /dev/stderr
	      fi
	    done
	    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- EVENT: deleting JSON ${FULLPATH}" &> /dev/stderr; fi
	    rm -f "${FULLPATH}"
	  fi
	  ;;
      *)
	  if [ "${DEBUG}" == 'true' ]; then echo "--- INFO $0 $$ -- skipping: ${FULLPATH}" &> /dev/stderr; fi
	  continue
	  ;;
    esac
  fi

  # merge services
  if [ $(date '+%s') -gt ${WHEN} ]; then
    # OUTPUT="$(echo "${OUTPUT}" | jq '.*'"$(update_services)")"
    jq '.*'"$(update_services)" "${OUTPUT_FILE}" > "${OUTPUT_FILE}.$$" && mv -f "${OUTPUT_FILE}.$$" "${OUTPUT_FILE}"
    WHEN=$(($(date '+%s')+MOTION_PERIOD))
  else
    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- skipping services" &> /dev/stderr; fi
  fi

  # merge base64 iff exists
  if [ ! -z "${B64_PATH:-}" ] && [ -s "${B64_PATH}" ]; then
    jq -s add "${B64_PATH}" "${OUTPUT_FILE}" > "${B64_PATH}.$$"
    if [ -s "${B64_PATH}.$$" ];  then
      if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ successfully merged ${B64_PATH}" &> /dev/stderr; fi
      rm -f "${B64_PATH}"
      mv "${B64_PATH}.$$" "${OUTPUT_FILE}"
    else
      echo "+++ WARN $0 $$ -- failed to merge ${B64_PATH}" &> /dev/stderr
    fi
  fi

  # output
  # echo "${OUTPUT}" | jq '.date='$(date +%s) > "${TMP}/$$"
  jq '.date='$(date +%s) "${OUTPUT_FILE}" > "${TMP}/$$"
  if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- moving ${TMP}/$$ to ${TMP}/${SERVICE_LABEL}.json" &> /dev/stderr; fi
  mv -f "${TMP}/$$" "${TMP}/${SERVICE_LABEL}.json"

done
