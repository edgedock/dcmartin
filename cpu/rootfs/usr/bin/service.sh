#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

# Get the currect CPU consumption, then construct the HTTP response message
HEADERS="Content-Type: application/json; charset=ISO-8859-1"

# ALPINE
IPADDR=$(hostname -i | awk '{ print $1 }' | awk -F\. '{ printf("%03d%03d%03d%03d\n", $1, $2, $3, $4) }')

HOSTNAME="$(hostname)-${IPADDR}"
BODY='{"hostname":"'${HOSTNAME}'","org":"'${HZN_ORGANIZATION:-null}'","pattern":"'${HZN_PATTERN:-null}'","device":"'${HZN_DEVICE_ID:-null}'"}'

IPADDR=$(hostname -i | awk '{ print $1 }' | awk -F\. '{ printf("%03d%03d%03d%03d\n", $1, $2, $3, $4) }')
HOSTNAME="$(hostname)-${IPADDR}"

BODY='{"hostname":"'${HOSTNAME}'","org":"'${HZN_ORGANIZATION:-null}'","pattern":"'${HZN_PATTERN:-null}'","device":"'${HZN_DEVICE_ID:-null}'"}'

if [ ! -z "${HZN_PATTERN:-}" ]; then
  PID=$(ps | grep "${HZN_PATTERN:-}.sh" | grep -v grep | awk '{ print $1 }')
  if [ -z "${PID}" ]; then PID=0; fi
  BODY=$(echo "${BODY}" | jq '.pid='"${PID}")
fi

if [ -s ${TMP}/${HZN_PATTERN}.json ]; then OUT=$(jq '.' ${TMP}/${HZN_PATTERN}.json); else OUT='null'; fi
BODY=$(echo "${BODY}" | jq '.'${HZN_PATTERN}'='"${OUT}")

HTTP="HTTP/1.1 200 OK\r\n${HEADERS}\r\n\r\n${BODY}\r\n"

# Emit the HTTP response
echo -e $HTTP
