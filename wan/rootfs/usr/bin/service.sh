#!/bin/bash

### ALPINE

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

# Get the currect CPU consumption, then construct the HTTP response message
HEADERS="Content-Type: application/json; charset=ISO-8859-1"

# HOSTNAME
HOSTNAME=$(hostname -i | awk '{ print $1 }' | awk -F\. '{ printf("%03d%03d%03d%03d\n", $1, $2, $3, $4) }')
if [ ! -z "${DEBUG:-}" ]; then echo "HOSTNAME: ${HOSTNAME}" &> /dev/stderr; fi
HOSTNAME="$(hostname)-${HOSTNAME}"
if [ ! -z "${DEBUG:-}" ]; then echo "HOSTNAME: ${HOSTNAME}" &> /dev/stderr; fi
BODY='{"hostname":"'${HOSTNAME}'","org":"'${HZN_ORGANIZATION:-null}'","pattern":"'${HZN_PATTERN:-null}'","device":"'${HZN_DEVICE_ID:-null}'"}'
if [ ! -z "${DEBUG:-}" ]; then echo "BODY: ${BODY}" &> /dev/stderr; fi

# PID
if [ ! -z "${HZN_PATTERN:-}" ]; then
  PID=$(ps | grep "${HZN_PATTERN:-}.sh" | grep -v grep | awk '{ print $1 }' | head -1)
  if [ ! -z "${DEBUG:-}" ]; then echo "PID: ${PID}" &> /dev/stderr; fi
  if [ -z "${PID}" ]; then PID=null; fi
  BODY=$(echo "${BODY}" | jq '.pid='"${PID}")
fi
if [ ! -z "${DEBUG:-}" ]; then echo "BODY: ${BODY}" &> /dev/stderr; fi

# output
if [ -s ${TMP}/${HZN_PATTERN}.json ]; then OUT=$(jq '.' ${TMP}/${HZN_PATTERN}.json); else OUT='null'; fi
BODY=$(echo "${BODY}" | jq '.'${HZN_PATTERN}'='"${OUT}")
if [ ! -z "${DEBUG:-}" ]; then echo "BODY: ${BODY}" &> /dev/stderr; fi

HTTP="HTTP/1.1 200 OK\r\n${HEADERS}\r\n\r\n${BODY}\r\n"

# Emit the HTTP response
echo -e $HTTP
