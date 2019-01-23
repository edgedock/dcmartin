#!/bin/bash

# punt on node identification (for now)
NODEID=$(hostname)
SCALE="320x240"

# temporary image and output
JPG="/tmp/image.$$.jpg"
OUT="/tmp/image.$$.out"

# capture image from /dev/video0 and grab file attributes for later use
fswebcam --scale "${SCALE}" --no-banner "${JPG}" &> "${OUT}"
# extract image size
WIDTH=$(egrep 'resolution' "${OUT}" | sed 's/.* to \([^\.]*\)\./\1/' | sed 's/\([0-9]*\)x\([0-9]*\)/\1/')
if [ -z "${WIDTH}" ]; then WIDTH=0; fi
HEIGHT=$(egrep 'resolution' "${OUT}" | sed 's/.* to \([^\.]*\)\./\1/' | sed 's/\([0-9]*\)x\([0-9]*\)/\2/')
if [ -z "${HEIGHT}" ]; then HEIGHT=0; fi

if [ -z "${DARKNET:-}" ]; then DARKNET="/darknet"; else echo "** WARNING: DARKNET from environment: ${DARKNET}" &> /dev/stderr; fi

cd ${DARKNET}

# test image 
if [ ! -s /"${JPG}" ]; then 
  cp "data/personx4.jpg" "${JPG}"
  MOCK=true
else
  MOCK=false
fi
# identify from tiny set
./darknet detector test cfg/voc.data cfg/yolov2-tiny-voc.cfg yolov2-tiny-voc.weights "${JPG}" > "${OUT}"
# extract processing time in seconds
TIME=$(cat "${OUT}" | egrep "Predicted" | sed 's/.*Predicted in \([^ ]*\).*/\1/')
# failure is zero
if [ -z "${TIME}" ]; then TIME=0; fi
# count 'person'
PERSONS=$(egrep '^person' "${OUT}" | wc -l)
# capture annotated image as BASE64 encoded string
IMAGE=$(base64 -w 0 -i predictions.jpg)
echo '{"devid":"'${NODEID}'","date":'$(date +%s)',"time":'${TIME}',"person":'${PERSONS}',"width":'${WIDTH}',"height":'${HEIGHT}',"scale":"'${SCALE}'","mock":"'${MOCK}'","image":"'${IMAGE}'"}'
rm -f "${JPG}" "${OUT}" predictions.jpg
