#!/bin/bash

if [ ! -z "${1}" ]; then
  HOST="${1}"
  if [ "${HOST%:*}" == "${HOST}" ]; then
    HOST="${HOST}:80"
    echo "No port specified; assuming port 80"
  fi
else
  HOST="127.0.0.1:8587"
fi
echo "Testing ${HOST}"

I=0
COUNT=0
DATE=$(date +%s)

# curl 127.0.0.1:8587 | jq '.yolo2msghub.yolo|.image=null'
# {
#   "log_level": "info",
#   "debug": "false",
#   "date": 1548951749,
#   "period": 0,
#   "entity": "person",
#   "time": 45.163295,
#   "count": 1,
#   "width": 320,
#   "height": 240,
#   "scale": "320x240",
#   "mock": "false",
#   "image": null
# }

echo "${I}: ${DATE} ${COUNT}"
while true; do
  OUT=$(curl -sSL "http://${HOST}" | jq -c '.yolo2msghub.yolo')
  if [ ! -z "${OUT}" ]; then
    D=$(echo "${OUT}" | jq -r '.date')
    if [[ ${D} > ${DATE} ]]; then 
      DATE=${D}
      T=$(echo "${OUT}" | jq -r '.time')
      C=$(echo "${OUT}" | jq -r '.count')
      COUNT=$((COUNT+C))
      echo; echo "${I}: ${DATE} ${COUNT} ${T}"
    fi
  fi
  I=$((I+1))
  echo -n '.'
done
