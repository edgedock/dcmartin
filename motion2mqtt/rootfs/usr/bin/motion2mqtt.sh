#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

## initialize service output ASAP
touch "${TMPDIR}/${SERVICE_LABEL}.json"

#SERVICES_JSON='[ {"name":"cpu","url":"http://cpu"}, {"name":"mqtt","url":"http://mqtt"}, {"name":"yolo4motion","url":"http://yolo4motion"} ]'
SERVICES_JSON='[ {"name":"cpu","url":"http://cpu"}, {"name":"mqtt","url":"http://mqtt"} ]'

if [ -z "${MOTION_DEVICE:-}" ] || [ "${MOTION_DEVICE}" == 'default' ]; then
  if [ -z "${HZN_DEVICE_ID}" ]; then
    IPADDR=$(hostname -i | awk '{ print $1 }' | awk -F\. '{ printf("%03d%03d%03d%03d\n", $1, $2, $3, $4) }')
    export MOTION_DEVICE="$(hostname)-${IPADDR}"
  else
    export MOTION_DEVICE="${HZN_DEVICE_ID}"
  fi
fi

CONFIG='{"log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-false}',"services":'${SERVICES_JSON:-null}',"group":"'${MOTION_GROUP:-}'","name":"'${MOTION_DEVICE:-}'","timezone":"'$MOTION_TIMEZONE'","period":'${MOTION_PERIOD:-}',"mqtt":{"host":"'${MQTT_HOST:-}'","port":'${MQTT_PORT:-1883}',"username":"'${MQTT_USERNAME:-}'","password":"'${MQTT_PASSWORD:-}'"},"motion":{"post_pictures":"'${MOTION_POST_PICTURES:-best}'","locate_mode":"'${MOTION_LOCATE_MODE:-off}'","event_gap":'${MOTION_EVENT_GAP:-60}',"framerate":'${MOTION_FRAMERATE:-5}',"threshold":'${MOTION_THRESHOLD:-5000}',"threshold_tune":'${MOTION_THRESHOLD_TUNE:-false}',"noise_level":'${MOTION_NOISE_LEVEL:-0}',"noise_tune":'${MOTION_NOISE_TUNE:-false}',"log_level":'${MOTION_LOG_LEVEL:-9}',"log_type":"'${MOTION_LOG_TYPE:-all}'"}}'

if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- config: ${CONFIG}" &> /dev/stderr; fi

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
    jq -s 'reduce .[] as $item ({}; . * $item)' "${OUTPUT_FILE}" "${REQSVCS_OUTPUT_FILE}" > "${TEMP_FILE}"
    # jq -s add "${OUTPUT_FILE}" "${REQSVCS_OUTPUT_FILE}" > "${TEMP_FILE}"
  fi
  rm -f "${REQSVCS_OUTPUT_FILE}"
  if [ -s "${TEMP_FILE}" ]; then
    if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- added required services" &> /dev/stderr; fi
    jq '.pid='$(motion_pid)'|.date='$(date +%s) "${TEMP_FILE}" > "${TEMP_FILE}.$$" && mv -f "${TEMP_FILE}.$$" "${TEMP_FILE}"
  else
    if [ "${DEBUG}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- update_output: update failed" &> /dev/stderr; fi
    echo '{"pid":'$(motion_pid)',"date":'$(date +%s)'}' > "${TEMP_FILE}"
  fi
  SERVICE_OUTPUT_FILE="${TMPDIR}/${SERVICE_LABEL}.json"
  mv -f "${TEMP_FILE}" "${SERVICE_OUTPUT_FILE}"
}

###
### MAIN
###

## initialize motion
motion_init

## start motion
motion_start
if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- motion started; PID:" $(motion_pid) &> /dev/stderr; fi

## initialize
OUTPUT_FILE="${TMPDIR}/${SERVICE_LABEL}.$$.json"

## initialize service output
echo "${CONFIG}" | jq -c '.date='$(date +%s) > ${OUTPUT_FILE}
if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- initializing output:" $(jq -c '.' ${OUTPUT_FILE}) &> /dev/stderr; fi

## forever
while true; do 
  # update output
  update_output ${OUTPUT_FILE}
  if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- waiting on directory: ${DIR}" &> /dev/stderr; fi
  # wait (forever) on changes in ${DIR}
  inotifywait -m -r -e close_write --format '%w%f' "${DIR}" | while read FULLPATH; do
    if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- inotifywait ${FULLPATH}" &> /dev/stderr; fi
    if [ ! -z "${FULLPATH}" ]; then 
      # process updates
      case "${FULLPATH##*/}" in
	*-*-*.json)
	  if [ -s "${FULLPATH}" ]; then
	    OUT=$(jq '.' "${FULLPATH}")
	    if [ -z "${OUT}" ]; then OUT='null'; fi
	    # don't update always
	    if [ "${MOTION_POST_PICTURES}" == 'all' ]; then
	      TEMP_FILE=$(mktemp)
	      jq '.motion.image='"${OUT}" "${OUTPUT_FILE}" > "${TEMP_FILE}" && mv -f "${TEMP_FILE}" "${OUTPUT_FILE}"
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
	    TEMP_FILE=$(mktemp)
	    jq '.motion.event='"${OUT}" "${OUTPUT_FILE}" > "${TEMP_FILE}" && mv -f "${TEMP_FILE}" "${OUTPUT_FILE}"
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
	      TEMP_FILE=$(mktemp)
	      jq '.motion.image='"${POSTED_IMAGE_JSON}" "${OUTPUT_FILE}" > "${TEMP_FILE}" && mv -f "${TEMP_FILE}" "${OUTPUT_FILE}"
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
      TEMP_FILE=$(mktemp)
      jq -s 'reduce .[] as $item ({}; . * $item)' "${OUTPUT_FILE}" "${IMG_B64_FILE}" > "${TEMP_FILE}" && mv "${TEMP_FILE}" "${OUTPUT_FILE}"
      rm -f "${IMG_B64_FILE}"
      IMG_B64_FILE=
    fi
    # merge GIF base64 iff exists
    if [ ! -z "${GIF_B64_FILE:-}" ] && [ -s "${GIF_B64_FILE}" ]; then
    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- found ${GIF_B64_FILE}" &> /dev/stderr; fi
      TEMP_FILE=$(mktemp)
      jq -s 'reduce .[] as $item ({}; . * $item)' "${OUTPUT_FILE}" "${GIF_B64_FILE}" > "${TEMP_FILE}" && mv "${TEMP_FILE}" "${OUTPUT_FILE}"
      rm -f "${GIF_B64_FILE}"
      GIF_B64_FILE=
    fi
    # update output
    update_output ${OUTPUT_FILE}
  done 
done

exit 1
