#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

# hzn config
if [ ! -z "${HZN}" ]; then
  BODY="${HZN}"
else
  echo "*** ERROR $0 $$ -- environment HZN unset; exiting" 2> /dev/stderr
  exit 1
fi

# git pid
if [ ! -z "${SERVICE_LABEL:-}" ]; then
  PID=$(ps | grep "${SERVICE_LABEL:-}.sh" | grep -v grep | awk '{ print $1 }' | head -1)
  if [ -z "${PID}" ]; then PID=0; fi
  BODY=$(echo "${BODY}" | jq '.pid='"${PID}")
else
  echo "*** ERROR $0 $$ -- no SERVICE_LABEL; exiting" 2> /dev/stderr
  exit 1
fi

if [ -s ${TMP}/${SERVICE_LABEL}.json ]; then OUT=$(jq '.' ${TMP}/${SERVICE_LABEL}.json); else OUT='null'; fi
BODY=$(echo "${BODY}" | jq '.'${SERVICE_LABEL}'='"${OUT}")

HEADERS="Content-Type: application/json; charset=ISO-8859-1"
HTTP="HTTP/1.1 200 OK\r\n${HEADERS}\r\n\r\n${BODY}\r\n"

# Emit the HTTP response
echo -e $HTTP
