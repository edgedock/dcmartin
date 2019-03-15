#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

if [ -z "${HAL_PERIOD:-}" ]; then HAL_PERIOD=300; fi
CONFIG='{"date":'$(date +%s)',"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"period":'${HAL_PERIOD}'}'
echo "${CONFIG}" > ${TMPDIR}/${SERVICE_LABEL}.json

while true; do
  DATE=$(date +%s)
  OUTPUT="${CONFIG}"

  for ls in lshw lsusb lscpu lspci lsblk lsdf; do
    OUT="$(${ls}.sh | jq '.'${ls}'?')"
    if [ ${DEBUG:-} == 'true' ]; then echo "${ls} == ${OUT}" &> /dev/stderr; fi
    if [ -z "${OUT:-}" ]; then OUT=null; fi
    OUTPUT=$(echo "$OUTPUT" | jq '.'${ls}'='"${OUT}")
    if [ ${DEBUG:-} == 'true' ]; then echo "OUTPUT == ${OUTPUT}" &> /dev/stderr; fi
  done

  echo "${OUTPUT}" | jq '.date='$(date +%s) > "${TMPDIR}/$$"
  mv -f "${TMPDIR}/$$" "${TMPDIR}/${SERVICE_LABEL}.json"
  # wait for ..
  SECONDS=$((HAL_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi
done
