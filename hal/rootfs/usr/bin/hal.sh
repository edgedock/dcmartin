#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

while true; do
  echo '{"lshw":'$(lshw.sh|jq '.lshw')',"lsusb":'$(lsusb.sh|jq '.lsusb?')',"lscpu":'$(lscpu.sh|jq '.lscpu?')',"lspci":'$(lspci.sh|jq '.lspci?')',"lsblk":'$(lsblk.sh|jq '.lsblk?')'}' > "${TMP}/output.json"
  sleep 60
done
