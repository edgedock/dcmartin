#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

# Get the currect CPU consumption, then construct the HTTP response message
HEADERS="Content-Type: application/json; charset=ISO-8859-1"

IPADDR=$(hostname -I | awk '{ print $1 }' | awk -F\. '{ printf("%03d%03d%03d%03d\n", $1, $2, $3, $4) }')

HOSTNAME="$(hostname)-${IPADDR}"
BODY='{"hostname":"'${HOSTNAME}'","service":"'${SERVICE_LABEL:-null}'","device":"'${HZN_DEVICE_ID:-null}'"}'

IPADDR=$(hostname -i | awk '{ print $1 }' | awk -F\. '{ printf("%03d%03d%03d%03d\n", $1, $2, $3, $4) }')
HOSTNAME="$(hostname)-${IPADDR}"

BODY='{"hostname":"'${HOSTNAME}'","service":"'${SERVICE_LABEL:-null}'","device":"'${HZN_DEVICE_ID:-null}'"}'

if [ ! -z "${SERVICE_LABEL:-}" ]; then
  PID=$(ps | grep "${SERVICE_LABEL:-}.sh" | grep -v grep | awk '{ print $1 }' | head -1)
  if [ -z "${PID}" ]; then PID=0; fi
  BODY=$(echo "${BODY}" | jq '.pid='"${PID}")
fi

if [ -s ${TMP}/${SERVICE_LABEL}.json ]; then OUT=$(jq '.' ${TMP}/${SERVICE_LABEL}.json); else OUT='null'; fi
BODY=$(echo "${BODY}" | jq '.'${SERVICE_LABEL}'='"${OUT}")

HTTP="HTTP/1.1 200 OK\r\n${HEADERS}\r\n\r\n${BODY}\r\n"

# Emit the HTTP response
echo -e $HTTP
