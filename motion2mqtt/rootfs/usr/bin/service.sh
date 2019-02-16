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

BODY="${HZN}"

# git pid
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


RESPONSE="${TMP}/response.$(date +%s).json"
echo "${BODY}" > "${RESPONSE}"

SERVICE_OUTPUT_FILE="${TMP}/${SERVICE_LABEL}.json"
if [ -s "${SERVICE_OUTPUT_FILE}" ]; then 
  if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- found ${SERVICE_OUTPUT_FILE}:" $(jq -c '.' ${SERVICE_OUTPUT_FILE}) &> /dev/stderr; fi
  DATE=$(jq -r '.date' "${SERVICE_OUTPUT_FILE}")
  PERIOD=$(jq -r '.period' "${SERVICE_OUTPUT_FILE}")
  if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- date: ${DATE}; period: ${PERIOD}" &> /dev/stderr; fi
  # process service output (should only happen on change)
  jq -c '.' "${SERVICE_OUTPUT_FILE}" | sed -e 's|\(.*\)|{"'"${SERVICE_LABEL}"'": \1}|' > "${TMP}/$$"
  if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- sed" $(cat ${TMP}/$$) &> /dev/stderr; fi
  jq -s add "${RESPONSE}" "${TMP}/$$" > "${RESPONSE}.$$" && mv -f "${RESPONSE}.$$" "${RESPONSE}"
  if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- jq -s" $(jq -c '.' ${RESPONSE}) &> /dev/stderr; fi
  rm -f "${TMP}/$$"
fi

if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG $0 $$ -- processed ${RESPONSE}:" $(jq -c '.' ${RESPONSE}) &> /dev/stderr; fi

if [ -z "${PERIOD:-}" ] || [ "${PERIOD}" == 'null' ]; then PERIOD=5; fi
if [ -z "${DATE:-}" ] || [ "${DATE}" == 'null' ]; then DATE=1; fi
NOW=$(date +%s)
AGE=$((NOW - DATE))

# find dateutils
for dc in dconv dateutils.dconv; do
  dconv=$(command -v "${dc}")
  if [ ! -z "${dconv}" ]; then break; fi
done

LMD=$(echo "${DATE}" | dconv -i '%s' -f '%a, %d %b %Y %H:%M:%S %Z' 2> /dev/stderr)
SIZ=$(wc -c "${RESPONSE}" | awk '{ print $1 }')

echo "HTTP/1.1 200 OK"
echo "Content-Type: application/json; charset=ISO-8859-1"
echo "Content-length: ${SIZ}" 
echo "Access-Control-Allow-Origin: *"
echo "Age: ${AGE}"
echo "Cache-Control: max-age=${PERIOD}"
echo "Last-Modified: ${LMD}" 
echo ""
cat "${RESPONSE}"

rm -f "${RESPONSE}"
