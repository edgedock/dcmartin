#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

JSON='[{"name": "hal", "url": "http://hal" },{"name":"cpu","url":"http://cpu"},{"name":"wan","url":"http://wan"}]'
SERVICES=$(echo "${JSON}" | jq -r '.[]|.name')

CONFIG='{"date":'$(date +%s)',"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"db":"'${MOTION_DEVICE_DB}'","name":"'${MOTION_DEVICE_NAME}'","timezone":"'$MOTION_TIMEZONE'","mqtt":{"host":"'${MOTION_MQTT_HOST}'","port":"'${MOTION_MQTT_PORT}'","username":"'${MOTION_MQTT_USERNAME}'","password":"'${MOTION_MQTT_PASSWORD}'"},"post":"'${MOTION_POST_PICTURES}'"}' 
echo "${CONFIG}" > ${TMP}/${SERVICE_LABEL}.json

if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- config: ${CONFIG}" 2> /dev/stderr; fi

ZONEINFO="/usr/share/zoneinfo/${MOTION_TIMEZONE}"
if [ -e "${ZONEINFO}" ]; then
  cp "${ZONEINFO}" /etc/localtime
  if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- zoneinfo: ${ZONEINFO}" 2> /dev/stderr; fi
else
  echo "+++ WARN $0 $$ -- cannot locate time zone information: ${ZONEINFO}" &> /dev/stderr
fi

mkdir -p ${TMP}/motion
rm -fr /var/lib/motion
ln -s ${TMP}/motion /var/lib
DIR=/var/lib/motion

# start motion
motion -d -b ${MOTION_LOG_LEVEL} -k ${MOTION_LOG_TYPE} -c /etc/motion/motion.conf -l /dev/stderr

# get pid
PID=$(ps | grep "motion" | grep -v grep | awk '{ print $1 }' | head -1)
if [ -z "${PID}" ]; then PID=0; fi
CONFIG=$(echo "${CONFIG}" | jq '.pid='"${PID}")

inotifywait -m -r -e close_write --format '%w%f' "${DIR}" | while read FULLPATH; do

  OUTPUT="${CONFIG}"

  case ${FULLPATH##*/} in
    *-*.json)
	echo "--- INFO $0 $$ -- event metadata" &> /dev/stderr
        OUTPUT=$(echo "${OUTPUT}" | jq -c '.event='$(jq -c '.' ${FULLPATH}))
	;;
    *-*.gif)
	echo "--- INFO $0 $$ -- event gif" &> /dev/stderr
        OUTPUT=$(echo "${OUTPUT}" | jq -c '.gif='$(base64 --encode -w 0 -i ${FULLPATH}))
	;;
    *-*-*.json)
	echo "--- INFO $0 $$ -- image metadata" &> /dev/stderr
        OUTPUT=$(echo "${OUTPUT}" | jq -c '.image='$(jq -c '.' ${FULLPATH}))
	;;
    *-*-*.jpg)
	echo "--- INFO $0 $$ -- image jpeg" &> /dev/stderr
        OUTPUT=$(echo "${OUTPUT}" | jq -c '.jpeg='$(base64 --encode -w 0 -i ${FULLPATH}))
	;;
    *)
  	echo "+++ WARN $0 $$ -- no match for ${FULLPATH##*/} from ${FULLPATH}" &> /dev/stderr
	;;
  esac

  for S in $SERVICES; do
    URL=$(echo "${JSON}" | jq -r '.[]|select(.name=="'${S}'").url')
    if [ ! -z "${URL}" ]; then
      OUT=$(curl -sSL "${URL}" 2> /dev/null | jq '.'"${S}")
    fi
    if [ -z "${OUT:-}" ]; then
      OUT='null'
    fi
    OUTPUT=$(echo "${OUTPUT:-}" | jq '.'"${S}"'='"${OUT}")
  done

  # output
  echo "${OUTPUT}" | jq '.date='$(date +%s) > "${TMP}/$$"
  mv -f "${TMP}/$$" "${TMP}/${SERVICE_LABEL}.json"

done
