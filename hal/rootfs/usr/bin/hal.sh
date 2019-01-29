#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

if [ -z "${HAL_PERIOD:-}" ]; then HAL_PERIOD=60; fi
CONFIG='{"log_level":"'${LOG_LEVEL}'","debug":"'${DEBUG}'","date":'$(date +%s)',"period":'${HAL_PERIOD}'}'
echo "${CONFIG}" > ${TMP}/${SERVICE_LABEL}.json

while true; do
  OUTPUT="${CONFIG}"
  for ls in lshw lsusb lscpu lspci lsblk; do
    OUT="$(${ls}.sh | jq '.'${ls}'?')"
    if [ ${DEBUG:-} == 'true' ]; then echo "${ls} == ${OUT}" &> /dev/stderr; fi
    if [ -z "${OUT:-}" ]; then OUT=null; fi
    OUTPUT=$(echo "$OUTPUT" | jq '.'${ls}'='"${OUT}")
    if [ ${DEBUG:-} == 'true' ]; then echo "OUTPUT == ${OUTPUT}" &> /dev/stderr; fi
  done
  echo "${OUTPUT}" > "${TMP}/${SERVICE_LABEL}.json"
  sleep ${HAL_PERIOD}
done
