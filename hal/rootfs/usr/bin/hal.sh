#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

if [ -z "${HAL_PERIOD:-}" ]; then HAL_PERIOD=300; fi
CONFIG='{"date":'$(date +%s)',"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"period":'${HAL_PERIOD}'}'
echo "${CONFIG}" > ${TMP}/${SERVICE_LABEL}.json

while true; do
  DATE=$(date +%s)
  OUTPUT="${CONFIG}"

  for ls in lshw lsusb lscpu lspci lsblk; do
    OUT="$(${ls}.sh | jq '.'${ls}'?')"
    if [ ${DEBUG:-} == 'true' ]; then echo "${ls} == ${OUT}" &> /dev/stderr; fi
    if [ -z "${OUT:-}" ]; then OUT=null; fi
    OUTPUT=$(echo "$OUTPUT" | jq '.'${ls}'='"${OUT}")
    if [ ${DEBUG:-} == 'true' ]; then echo "OUTPUT == ${OUTPUT}" &> /dev/stderr; fi
  done

  echo "${OUTPUT}" | jq '.date='$(date +%s) > "${TMP}/$$"
  mv -f "${TMP}/$$" "${TMP}/${SERVICE_LABEL}.json"
  # wait for ..
  SECONDS=$((HAL_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi
done
