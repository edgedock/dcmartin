#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

if [ -z "${CPU_INTERVAL}" ]; then CPU_INTERVAL=1; fi
if [ -z "${CPU_PERIOD}" ]; then CPU_PERIOD=60; fi

CONFIG='{"date":'$(date +%s)',"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"period":'${CPU_PERIOD}',"interval":'${CPU_INTERVAL}'}'
echo "${CONFIG}" > ${TMPDIR}/${SERVICE_LABEL}.json

while true; do
  DATE=$(date +%s)
  OUTPUT="${CONFIG}"

  # https://github.com/Leo-G/DevopsWiki/wiki/How-Linux-CPU-Usage-Time-and-Percentage-is-calculated
  RAW=$(grep -iE '^cpu ' /proc/stat)
  CT1=$(echo "${RAW}" | awk '{ printf("%d",$2+$3+$4+$5+$6+$7+$8+$9) }')
  CI1=$(echo "${RAW}" | awk '{ printf("%d",$5+$6) }')
  sleep ${CPU_INTERVAL}
  RAW=$(grep -iE '^cpu ' /proc/stat)
  CT2=$(echo "${RAW}" | awk '{ printf("%d",$2+$3+$4+$5+$6+$7+$8+$9) }')
  CI2=$(echo "${RAW}" | awk '{ printf("%d",$5+$6) }')

  PERCENT=$(echo "scale=2; 100 * (($CT2 - $CT1) - ($CI2 - $CI1)) / ($CT2 - $CT1)" | bc -l)
  if [ -z "${PERCENT}" ]; then PERCENT=null; fi
  OUTPUT=$(echo "${OUTPUT}" | jq '.percent='${PERCENT})

  # output
  echo "${OUTPUT}" | jq '.date='$(date +%s) > "${TMPDIR}/$$"
  mv -f "${TMPDIR}/$$" "${TMPDIR}/${SERVICE_LABEL}.json"
  # wait for ..
  SECONDS=$((CPU_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi
done
