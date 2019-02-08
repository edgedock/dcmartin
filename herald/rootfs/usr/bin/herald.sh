#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

if [ -z "${HERALD_PERIOD}" ]; then HERALD_PERIOD=60; fi

CONFIG='{"date":'$(date +%s)',"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"period":'${HERALD_PERIOD}'}'
echo "${CONFIG}" > ${TMP}/${SERVICE_LABEL}.json

python /usr/bin/discovery.py &

while true; do
  DATE=$(date +%s)
  OUTPUT="${CONFIG}"

  if [ -z "${FOUND}" ]; then FOUND=null; fi
  OUTPUT=$(echo "${OUTPUT}" | jq '.found='${FOUND})

  # output
  echo "${OUTPUT}" | jq '.date='$(date +%s) > "${TMP}/$$"
  mv -f "${TMP}/$$" "${TMP}/${SERVICE_LABEL}.json"
  # wait for ..
  SLEEP=$((HERALD_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SLEEP} > 0 ]; then
    sleep ${SLEEP}
  fi
done
