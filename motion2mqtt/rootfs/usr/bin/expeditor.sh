#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

if [ -z "${SERVICE_LABEL}" ]; then echo "*** ERROR $0 $$ -- no service label: ${SERVICE_LABEL}" &> /dev/stderr; exit 1; fi

if [ -z "${1}" ] || [ -z "${2}" ]; then echo "*** ERROR $0 $$ -- usage: $0 <service-file-json> <response-file-json>" &> /dev/stderr; exit 1; fi
 
SERVICE_FILE="${1}"
RESPONSE_FILE="${2}"

while true; do
  if [ -s "${SERVICE_FILE}" ]; then 
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- found ${SERVICE_FILE}" $(jq -c '.' "${SERVICE_FILE}") &> /dev/stderr; fi
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- found ${RESPONSE_FILE}" $(jq -c '.' "${RESPONSE_FILE}") &> /dev/stderr; fi
    jq -c '.' "${SERVICE_FILE}" | sed -e 's|\(.*\)|{"'"${SERVICE_LABEL}"'": \1}|' > "${TMP}/$$"
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- created ${TMP}/$$" $(jq -c '.' "${TMP}/$$") &> /dev/stderr; fi
    jq -s add "${RESPONSE_FILE}" "${TMP}/$$" > "${RESPONSE_FILE}.$$" 
    if [ -s "${RESPONSE_FILE}.$$" ]; then
      mv -f "${RESPONSE_FILE}.$$" "${RESPONSE_FILE}"
      if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- updated ${RESPONSE_FILE}" $(jq -c '.' "${RESPONSE_FILE}") &> /dev/stderr; fi
    else
      if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- jq add failed" &> /dev/stderr; fi
    fi
    rm -f "${TMP}/$$"
  fi
  inotifywait -m -r -e close_write --format '%w%f' "${SERVICE_FILE}"
done
