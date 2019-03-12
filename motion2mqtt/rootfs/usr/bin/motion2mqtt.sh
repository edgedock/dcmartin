#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

## initialize service output ASAP
touch "${TMPDIR}/${SERVICE_LABEL}.json"

SERVICES_JSON='[{"name":"cpu","url":"http://cpu"}]'

if [ -z "${MOTION_DEVICE_NAME:-}" ] || [ "${MOTION_DEVICE_NAME}" == 'default' ]; then
  if [ -z "${HZN_DEVICE_ID}" ]; then
    IPADDR=$(hostname -i | awk '{ print $1 }' | awk -F\. '{ printf("%03d%03d%03d%03d\n", $1, $2, $3, $4) }')
    MOTION_DEVICE_NAME="$(hostname)-${IPADDR}"
  else
    MOTION_DEVICE_NAME="${HZN_DEVICE_ID}"
  fi
fi

CONFIG='{"date":'$(date +%s)',"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"db":"'${MOTION_DEVICE_DB}'","name":"'${MOTION_DEVICE_NAME}'","timezone":"'$MOTION_TIMEZONE'","mqtt":{"host":"'${MOTION_MQTT_HOST}'","port":'${MOTION_MQTT_PORT}',"username":"'${MOTION_MQTT_USERNAME}'","password":"'${MOTION_MQTT_PASSWORD}'"},"motion":{"post_pictures":"'${MOTION_POST_PICTURES}'","locate_mode":"'${MOTION_LOCATE_MODE}'","event_gap":'${MOTION_EVENT_GAP}',"framerate":'${MOTION_FRAMERATE}',"threshold":'${MOTION_THRESHOLD}',"threshold_tune":'${MOTION_THRESHOLD_TUNE}',"noise_level":'${MOTION_NOISE_LEVEL}',"noise_tune":'${MOTION_NOISE_TUNE}',"log_level":'${MOTION_LOG_LEVEL}',"log_type":"'${MOTION_LOG_TYPE}'"}}'

if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- config: ${CONFIG}" &> /dev/stderr; fi

## services consumed
SERVICES=$(echo "${SERVICES_JSON}" | jq -r '.[]|.name')
CONFIG=$(echo "${CONFIG}" | jq '.services=['$(echo "${SERVICES}" | fmt | sed 's| |","|g' | sed 's|\(.*\)|"\1"|')']')
if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- SERVICES: ${SERVICES}" &> /dev/stderr; fi

## timezone
ZONEINFO="/usr/share/zoneinfo/${MOTION_TIMEZONE}"
if [ -e "${ZONEINFO}" ]; then
  cp "${ZONEINFO}" /etc/localtime
  if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- zoneinfo: ${ZONEINFO}" &> /dev/stderr; fi
else
  echo "+++ WARN $0 $$ -- cannot locate time zone information: ${ZONEINFO}" &> /dev/stderr
fi

###
### MOTION
### 

source /usr/bin/motion-init.sh
source /usr/bin/motion-start.sh

###
### FUNCTIONS
###

## update services functions
service_update() {
  OUTPUT_FILE=${1}
  OUTPUT=$(mktemp)
  echo '{}' > "${OUTPUT}"
  for S in ${SERVICES}; do
    URL=$(echo "${SERVICES_JSON}" | jq -r '.[]|select(.name=="'${S}'").url')
    TEMPFILE=$(mktemp)
    if [ ! -z "${URL}" ]; then
      curl -fsSL "${URL}" -o ${TEMPFILE} 2> /dev/null 
    fi
    TEMPOUT=$(mktemp)
    echo '{"'${S}'":' > ${TEMPOUT}
    if [ ! -s "${TEMPFILE:-}" ]; then
      echo -n 'null' >> ${TEMPOUT}
    else
      jq -c '.'"${S}" ${TEMPFILE} >> ${TEMPOUT}
    fi
    rm -f ${TEMPFILE}
    echo '}' >> ${TEMPOUT}
    jq -s add "${TEMPOUT}" "${OUTPUT}" > "${OUTPUT}.$$" && mv -f "${OUTPUT}.$$" "${OUTPUT}"
    rm -f ${TEMPOUT}
  done
  jq -s add "${OUTPUT}" "${OUTPUT_FILE}" > "${OUTPUT}.$$" && mv -f "${OUTPUT}.$$" "${OUTPUT_FILE}"
  rm -f "${OUTPUT}"
}

## update service output
update_output() {
  OUTPUT_FILE="${1}"
  service_update ${OUTPUT_FILE}
  TEMPFILE=$(mktemp)
  jq '.pid='$(motion_pid)'|.date='$(date +%s) "${OUTPUT_FILE}" > "${TEMPFILE}" && mv -f "${TEMPFILE}" "${OUTPUT_FILE}"
  cp -f "${OUTPUT_FILE}" "${TMPDIR}/${SERVICE_LABEL}.json"
}

###
### MAIN
###

## initialize motion
motion_init

## start motion
PID=$(motion_start)

## initialize
OUTPUT_FILE="${TMPDIR}/${SERVICE_LABEL}.$$.json"

## initialize service output
echo "${CONFIG}" > "${OUTPUT_FILE}"

## forever
while true; do 
  # update output
  update_output ${OUTPUT_FILE}

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
	      TEMPFILE=$(mktemp)
	      jq '.motion.image='"${OUT}" "${OUTPUT_FILE}" > "${TEMPFILE}" && mv -f "${TEMPFILE}" "${OUTPUT_FILE}"
	      IMAGE_PATH="${FULLPATH%.*}.jpg"
	      if [ -s "${IMAGE_PATH}" ]; then
		IMG_B64_FILE="${TMPDIR}/${IMAGE_PATH##*/}"; IMG_B64_FILE="${IMG_B64_FILE%.*}.b64"
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
	    TEMPFILE=$(mktemp)
	    jq '.motion.event='"${OUT}" "${OUTPUT_FILE}" > "${TEMPFILE}" && mv -f "${TEMPFILE}" "${OUTPUT_FILE}"
	    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- EVENT: updated ${OUTPUT_FILE} with event JSON:" $(echo "${OUT}" | jq -c) &> /dev/stderr; fi
	    # check for GIF
	    IMAGE_PATH="${FULLPATH%.*}.gif"
	    if [ -s "${IMAGE_PATH}" ]; then
	      GIF_B64_FILE="${TMPDIR}/${IMAGE_PATH##*/}"; GIF_B64_FILE="${GIF_B64_FILE%.*}.b64"
	      if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- EVENT: found GIF: ${IMAGE_PATH}; creating ${GIF_B64_FILE}" &> /dev/stderr; fi
	      base64 -w 0 "${IMAGE_PATH}" | sed -e 's|\(.*\)|{"motion":{"event":{"base64":"\1"}}}|' > "${GIF_B64_FILE}"
	    fi
	    rm -f "${IMAGE_PATH}"
	    # find posted picture
	    POSTED_IMAGE_JSON=$(jq -r '.image?' "${FULLPATH}")
	    if [ ! -z "${POSTED_IMAGE_JSON}" ] && [ "${POSTED_IMAGE_JSON}" != 'null' ]; then
	      PID=$(echo "${POSTED_IMAGE_JSON}" | jq -r '.id?')
	      if [ ! -z "${PID}" ] && [ "${PID}" != 'null' ]; then
		IMAGE_PATH="${FULLPATH%/*}/${PID}.jpg"
		if [ -s  "${IMAGE_PATH}" ]; then
		  IMG_B64_FILE="${TMPDIR}/${IMAGE_PATH##*/}"; IMG_B64_FILE="${IMG_B64_FILE%.*}.b64"
		  base64 -w 0 "${IMAGE_PATH}" | sed -e 's|\(.*\)|{"motion":{"image":{"base64":"\1"}}}|' > "${IMG_B64_FILE}"
		fi
	      fi
	      rm -f "${IMAGE_PATH}"
	      # update output to posted image
	      TEMPFILE=$(mktemp)
	      jq '.motion.image='"${POSTED_IMAGE_JSON}" "${OUTPUT_FILE}" > "${TEMPFILE}" && mv -f "${TEMPFILE}" "${OUTPUT_FILE}"
	    fi
	    # cleanup
	    find "${FULLPATH%/*}" -name "${FULLPATH%.*}*" -print | xargs rm -f
	  fi
	  ;;
	*)
	  if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- ${FULLPATH}; continuing..." &> /dev/stderr; fi
	  continue
	  ;;
      esac
    else
      if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- timeout" &> /dev/stderr; fi
    fi
    # merge image base64 iff exists
    if [ ! -z "${IMG_B64_FILE:-}" ] && [ -s "${IMG_B64_FILE}" ]; then
      if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- found ${IMG_B64_FILE}" &> /dev/stderr; fi
      TEMPFILE=$(mktemp)
      jq -s 'reduce .[] as $item ({}; . * $item)' "${OUTPUT_FILE}" "${IMG_B64_FILE}" > "${TEMPFILE}" && mv "${TEMPFILE}" "${OUTPUT_FILE}"
      rm -f "${IMG_B64_FILE}"
      IMG_B64_FILE=
    fi
    # merge GIF base64 iff exists
    if [ ! -z "${GIF_B64_FILE:-}" ] && [ -s "${GIF_B64_FILE}" ]; then
    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- found ${GIF_B64_FILE}" &> /dev/stderr; fi
      TEMPFILE=$(mktemp)
      jq -s 'reduce .[] as $item ({}; . * $item)' "${OUTPUT_FILE}" "${GIF_B64_FILE}" > "${TEMPFILE}" && mv "${TEMPFILE}" "${OUTPUT_FILE}"
      rm -f "${GIF_B64_FILE}"
      GIF_B64_FILE=
    fi
    # update output
    update_output ${OUTPUT_FILE}
  done 
done

exit 1
