#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh

###
### initialize
###

## initialize horizon
hzn_init

## configure service

CONFIG='{"log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-false}',"period":"'${CPU_PERIOD}'","interval":"'${CPU_INTERVAL}'","services":'"${SERVICES:-null}"'}'

## initialize servive
service_init ${CONFIG}

###
### MAIN
###

## create initial output
OUTPUT_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$.json"
echo '{"date":'$(date +%s)'}' > "${OUTPUT_FILE}"
service_update "${OUTPUT_FILE}"

# iterate forever
while true; do
  DATE=$(date +%s)
  OUTPUT=$(jq -c '.' "${OUTPUT_FILE}")

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
  echo "${OUTPUT}" | jq '.date='$(date +%s) > "${OUTPUT_FILE}"
  # update service
  service_update "${OUTPUT_FILE}"
  # wait for ..
  SECONDS=$((CPU_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi
done
