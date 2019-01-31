#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

if [ -z "${WAN_PERIOD}" ]; then WAN_PERIOD=1800; fi

CONFIG='{"log_level":"'${LOG_LEVEL}'","debug":"'${DEBUG}'","date":'$(date +%s)',"period":'${WAN_PERIOD}'}' 
echo "${CONFIG}" > ${TMP}/${SERVICE_LABEL}.json

while true; do
  DATE=$(date +%s)
  SPEEDTEST=$(speedtest --json)
  if [ -z "${SPEEDTEST}" ]; then SPEEDTEST=null; fi

  echo "${CONFIG}" | jq '.date='$(date +%s)'|.speedtest='"${SPEEDTEST}" > "${TMP}/${SERVICE_LABEL}.json"
  # wait for ..
  SLEEP=$((WAN_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SLEEP} > 0 ]; then
    sleep ${SLEEP}
  fi
done
