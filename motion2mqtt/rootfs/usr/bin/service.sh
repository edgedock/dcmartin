#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

# hzn config
if [ -z "${HZN}" ]; then
  if [ ! -s "/tmp/config.json" ]; then
    echo "*** ERROR $0 $$ -- environment HZN unset; empty /tmp/config.json; exiting" &> /dev/stderr
    exit 1
  fi
  echo "+++ WARN $0 $$ -- environment HZN unset; using /tmp/config.json; continuing" &> /dev/stderr
  export HZN=$(jq '.' "/tmp/config.json")
  if [ -z "${HZN}" ]; then
    echo "*** ERROR $0 $$ -- environment HZN unset; invalid /tmp/config.json; exiting" $(cat /tmp/config.json) &> /dev/stderr
    exit 1
  fi
fi

# find dateutils
for dc in dconv dateutils.dconv; do
  DCONV=$(command -v "${dc}")
  if [ ! -z "${DCONV}" ]; then break; fi
done
if [ -z "${DCONV}" ]; then echo "*** ERROR $0 $$ -- cannot locate dateutils; exiting" &> /dev/stderr; exit 1; fi

# get pid of service
CMD=$(command -v "${SERVICE_LABEL:-}.sh")
if [ ! -z "${CMD}" ]; then
  PID=$(ps | grep "${CMD}" | grep -v grep | awk '{ print $1 }' | head -1)
fi
if [ -z "${PID:-}" ]; then PID=0; fi

# output from the service
if [ -z "${SERVICE_LABEL:-}" ]; then echo "*** ERROR $0 $$ -- no SERVICE_LABEL; exiting" &> /dev/stderr; exit 1; fi
SERVICE_OUTPUT_FILE="${TMP}/${SERVICE_LABEL}.json"

# start the response body
RESPONSE_FILE="${TMP}/${0##*/}.json"

# wait for service
WAITER='expeditor'
CMD=$(command -v "${WAITER}.sh")
if [ -z "${CMD}" ]; then echo "*** ERROR $0 $$ -- cannot locate ${WAITER}.sh; exiting" &> /dev/stderr; exit 1; fi
PID=$(ps | grep "${CMD}" | grep -v grep | awk '{ print $1 }' | head -1)
if [ -z "${PID:-}" ]; then
  echo "${HZN}" > "${RESPONSE_FILE}"
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- starting: ${CMD} ${SERVICE_OUTPUT_FILE} ${RESPONSE_FILE}" $(jq -c '.' "${RESPONSE_FILE}") &> /dev/stderr; fi
  ${CMD} "${SERVICE_OUTPUT_FILE}" "${RESPONSE_FILE}" &> /dev/stderr &
else
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- ${CMD} running; PID: ${PID}" &> /dev/stderr; fi
fi

# check on service interval
PERIOD=$(jq -r '.'"${SERVICE_LABEL}"'.period?' "${RESPONSE_FILE}")
if [ -z "${PERIOD:-}" ] || [ "${PERIOD}" == 'null' ]; then PERIOD=0; fi
DATE=$(jq -r '.'"${SERVICE_LABEL}"'.date?' "${RESPONSE_FILE}")
if [ -z "${DATE:-}" ] || [ "${DATE}" == 'null' ]; then DATE=1; fi

if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- period: ${PERIOD}; date: ${DATE}" &> /dev/stderr; fi

NOW=$(date +%s)
AGE=$((NOW - DATE))
LMD=$(echo "${DATE}" | dconv -i '%s' -f '%a, %d %b %Y %H:%M:%S %Z' 2> /dev/stderr)
SIZ=$(wc -c "${RESPONSE_FILE}" | awk '{ print $1 }')

if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- ${RESPONSE_FILE}; age: ${AGE}; size: ${SIZ}" &> /dev/stderr; fi

echo "HTTP/1.1 200 OK"
echo "Content-Type: application/json; charset=ISO-8859-1"
echo "Content-length: ${SIZ}" 
echo "Access-Control-Allow-Origin: *"
echo "Age: ${AGE}"
echo "Cache-Control: max-age=${PERIOD}"
echo "Last-Modified: ${LMD}" 
echo ""
cat "${RESPONSE_FILE}"
