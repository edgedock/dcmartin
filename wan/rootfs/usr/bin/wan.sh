#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

if [ -z "${WAN_PERIOD}" ]; then WAN_PERIOD=1800; fi

while true; do

  SPEEDTEST=$(speedtest --json)
  if [ -z "${SPEEDTEST}" ]; then SPEEDTEST=null; fi

  echo '{"date":'$(date +%s)',"speedtest":'${SPEEDTEST}'}' > "${TMP}/${HZN_PATTERN}.json"
  sleep ${WAN_PERIOD}
done
