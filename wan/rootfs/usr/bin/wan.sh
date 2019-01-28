#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

if [ -z "${WAN_PERIOD}" ]; then WAN_PERIOD=1800; fi

CONFIG='{"log_level":"'${LOG_LEVEL}'","debug":"'${DEBUG}'","date":'$(date +%s)',"period":'${WAN_PERIOD}'}' 
echo "${CONFIG}" > ${TMP}/${HZN_PATTERN}.json

while true; do

  SPEEDTEST=$(speedtest --json)
  if [ -z "${SPEEDTEST}" ]; then SPEEDTEST=null; fi

  echo "${CONFIG}" | jq '.date='$(date +%s)'|.speedtest='"${SPEEDTEST}" > "${TMP}/${HZN_PATTERN}.json"
  sleep ${WAN_PERIOD}
done
