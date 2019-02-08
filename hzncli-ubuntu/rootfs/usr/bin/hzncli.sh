#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

if [ -z "${TEST_PERIOD}" ]; then TEST_PERIOD=60; fi

CONFIG='{"date":'$(date +%s)',"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"period":'${TEST_PERIOD}'}'
echo "${CONFIG}" > ${TMP}/${SERVICE_LABEL}.json

while true; do
  DATE=$(date +%s)
  OUTPUT="${CONFIG}"

  OUTPUT=$(echo "${OUTPUT}" | jq '.node='$(hzn node list))

  # output
  echo "${OUTPUT}" | jq '.date='$(date +%s) > "${TMP}/$$"
  mv -f "${TMP}/$$" "${TMP}/${SERVICE_LABEL}.json"
  # wait for ..
  SLEEP=$((TEST_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SLEEP} > 0 ]; then
    sleep ${SLEEP}
  fi
done
