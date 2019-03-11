#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

# hzn config
if [ -z "${HZN}" ]; then
  if [ ! -s "/tmp/config.json" ]; then
    echo "*** ERROR $0 $$ -- environment HZN unset; empty /tmp/config.json; exiting" 2> /dev/stderr
    exit 1
  fi
  echo "+++ WARN $0 $$ -- environment HZN unset; using /tmp/config.json; continuing" 2> /dev/stderr
  export HZN=$(jq '.' "/tmp/config.json")
  if [ -z "${HZN}" ]; then
    echo "*** ERROR $0 $$ -- environment HZN unset; invalid /tmp/config.json; exiting" $(cat /tmp/config.json) 2> /dev/stderr
    exit 1
  fi
fi

RESPONSE_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.json"
echo "${HZN}" > "${RESPONSE_FILE}"

SERVICE_FILE="${TMPDIR}/${SERVICE_LABEL}.json"
if [ -s "${SERVICE_FILE}" ]; then 
  TSF="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$"
  echo '{"'${SERVICE_LABEL}'":' > "${TSF}"
  cat "${SERVICE_FILE}" >> "${TSF}"
  echo '}' >> "${TSF}"
  jq -s add "${TSF}" "${RESPONSE_FILE}" > "${TMPDIR}/$$.$$" && mv -f "${TMPDIR}/$$.$$" "${RESPONSE_FILE}"
  rm -f "${TSF}"
fi

SIZ=$(wc -c "${RESPONSE_FILE}" | awk '{ print $1 }')

echo "HTTP/1.1 200 OK"
echo "Content-Type: application/json; charset=ISO-8859-1"
echo "Content-length: ${SIZ}" 
echo "Access-Control-Allow-Origin: *"
echo ""
cat "${RESPONSE_FILE}"
