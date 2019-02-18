#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

if [ -z "${SERVICE_LABEL}" ]; then echo "*** ERROR $0 $$ -- no service label: ${SERVICE_LABEL}" &> /dev/stderr; exit 1; fi

if [ -z "${1}" ] || [ -z "${2}" ]; then echo "*** ERROR $0 $$ -- usage: $0 <service-file> <response-file>" &> /dev/stderr; exit 1; fi
 
SERVICE_FILE="${1}"
RESPONSE_FILE="${2}"

while [ ! -e "${SERVICE_FILE}" ]; do
  echo "+++ WARN -- $0 $$ -- no ${SERVICE_FILE}; waiting" &> /dev/stderr; fi
  sleep 1
done

RESPONSE_TEMPLATE="${TMP}/${0##*/}.${RESPONSE_FILE##*/}.$$"
jq -c '.' "${RESPONSE_FILE}" > "${RESPONSE_TEMPLATE}"
if [ $? != 0 ]; then
  echo "*** ERROR -- $0 $$ -- <response-file> ${RESPONSE_FILE} not valid JSON; exiting" &> /dev/stderr; fi
  exit 1
fi

if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- ${SERVICE_FILE}" &> /dev/stderr; fi

inotifywait -m -e close_write --format '%w%f' "${SERVICE_FILE}" | while read FULLPATH; do
  if [ "${FULLPATH}" != "${SERVICE_FILE}" ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- ${FULLPATH} is not ${SERVICE_FILE}" &> /dev/stderr; fi
    continue
  fi
  if [ -s "${SERVICE_FILE}" ]; then 
    TSF="${TMP}/${0##*/}.${SERVICE_LABEL}.$$"
    echo '{"'${SERVICE_LABEL}'":' > "${TSF}"
    cat "${SERVICE_FILE}" >> "${TSF}"
    echo '}' >> "${TSF}"
    jq -s add "${TSF}" "${RESPONSE_TEMPLATE}" > "${RESPONSE_TEMPLATE}.$$" && mv -f "${RESPONSE_TEMPLATE}.$$" "${RESPONSE_FILE}"
    rm -f "${TSF}"
  fi
done
