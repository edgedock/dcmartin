#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

if [ -z "${CPU_INTERVAL}" ]; then CPU_INTERVAL=1; fi
if [ -z "${CPU_PERIOD}" ]; then CPU_PERIOD=60; fi

CONFIG='{"log_level":"'${LOG_LEVEL}'","debug":"'${DEBUG}'","date":'$(date +%s)',"period":'${CPU_PERIOD}',"interval":'${CPU_INTERVAL}'}'
echo "${CONFIG}" > ${TMP}/${SERVICE}.json

while true; do

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

  echo "${CONFIG}" | jq '.date='$(date +%s)'|.percent='${PERCENT} > "${TMP}/${SERVICE}.json"
  sleep ${CPU_PERIOD}
done
