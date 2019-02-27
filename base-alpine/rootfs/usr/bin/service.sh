#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

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

# get pid
if [ ! -z "${SERVICE_LABEL:-}" ]; then
  CMD=$(command -v "${SERVICE_LABEL:-}.sh")
  if [ ! -z "${CMD}" ]; then
    PID=$(ps | grep "${CMD}" | grep -v grep | awk '{ print $1 }' | head -1)
  fi
  if [ -z "${PID:-}" ]; then PID=0; fi
  BODY=$(echo "${BODY}" | jq '.pid='"${PID}")
else
  echo "*** ERROR $0 $$ -- no SERVICE_LABEL; exiting" 2> /dev/stderr
  exit 1
fi

RESPONSE_FILE="${TMP}/${0##*/}.${SERVICE_LABEL}.json"
echo "${HZN}" > "${RESPONSE_FILE}"

SERVICE_FILE="${TMP}/${SERVICE_LABEL}.json"
if [ -s "${SERVICE_FILE}" ]; then 
  TSF="${TMP}/${0##*/}.${SERVICE_LABEL}.$$"
  echo '{"'${SERVICE_LABEL}'":' > "${TSF}"
  cat "${SERVICE_FILE}" >> "${TSF}"
  echo '}' >> "${TSF}"
  jq -s add "${TSF}" "${RESPONSE_FILE}" > "${TMP}/$$.$$" && mv -f "${TMP}/$$.$$" "${RESPONSE_FILE}"
  rm -f "${TSF}"
fi

SIZ=$(wc -c "${RESPONSE_FILE}" | awk '{ print $1 }')

echo "HTTP/1.1 200 OK"
echo "Content-Type: application/json; charset=ISO-8859-1"
echo "Content-length: ${SIZ}" 
echo "Access-Control-Allow-Origin: *"
echo ""
cat "${RESPONSE_FILE}"
