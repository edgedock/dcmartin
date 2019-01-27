#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

while true; do
  echo '{"date":'$(date +%s)',"lshw":'$(lshw.sh|jq '.lshw')',"lsusb":'$(lsusb.sh|jq '.lsusb?')',"lscpu":'$(lscpu.sh|jq '.lscpu?')',"lspci":'$(lspci.sh|jq '.lspci?')',"lsblk":'$(lsblk.sh|jq '.lsblk?')'}' > "${TMP}/${HZN_PATTERN}.json"
  sleep 60
done
