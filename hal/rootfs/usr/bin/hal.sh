#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

if [ -z "${HAL_PERIOD:-}" ]; then HAL_PERIOD=60; fi
CONFIG='{"log_level":"'${LOG_LEVEL}'","debug":"'${DEBUG}'","date":'$(date +%s)',"period":'${HAL_PERIOD}'}'
echo "${CONFIG}" > ${TMP}/${HZN_PATTERN}.json

while true; do
  echo "${CONFIG}" | jq '.date='$(date +%s)'|.lshw='$(lshw.sh|jq '.lshw')'|.lsusb='$(lsusb.sh|jq '.lsusb?')'|.lscpu='$(lscpu.sh|jq '.lscpu?')'|.lspci='$(lspci.sh|jq '.lspci?')'|.lsblk='$(lsblk.sh|jq '.lsblk?') > "${TMP}/${HZN_PATTERN}.json"
  sleep ${HAL_PERIOD)
done
