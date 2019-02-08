#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

if [ -z "${HERALD_PERIOD}" ]; then HERALD_PERIOD=60; fi

CONFIG='{"date":'$(date +%s)',"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"period":'${HERALD_PERIOD}'}'
echo "${CONFIG}" > ${TMP}/${SERVICE_LABEL}.json

python /usr/bin/discovery.py &

# get pid
PID=$(ps | grep "discovery.py" | grep -v grep | awk '{ print $1 }' | head -1)
if [ -z "${PID}" ]; then PID=0; fi
CONFIG=$(echo "${CONFIG}" | jq '.pid='"${PID}")

URL='http://127.0.0.1:5960/v1/discovered'

while true; do
  DATE=$(date +%s)
  OUTPUT="${CONFIG}"

  DISCOVERED=$(curl -sSL "${URL}" | jq -c '.' 2> /dev/null)
  if [ -z "${DISCOVERED}" ]; then DISCOVERED=null; echo "+++ WARN $0 $$ -- no output from ${URL}; continuing"; fi
  OUTPUT=$(echo "${OUTPUT}" | jq -c '.found='"${DISCOVERED}")

  # output
  echo "${OUTPUT}" | jq '.date='$(date +%s) > "${TMP}/$$"
  mv -f "${TMP}/$$" "${TMP}/${SERVICE_LABEL}.json"
  # wait for ..
  SLEEP=$((HERALD_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SLEEP} > 0 ]; then
    sleep ${SLEEP}
  fi
done
