#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

# scale of image
SCALE="320x240"

# temporary image and output
JPG="/tmp/image.$$.jpg"
OUT="/tmp/image.$$.out"

if [ -z "${YOLO_PERIOD:-}" ]; then YOLO_PERIOD=0; fi
if [ -z "${YOLO_ENTITY:-}" ]; then YOLO_ENTITY=person; fi

if [ -z "${DARKNET:-}" ]; then DARKNET="/darknet"; else echo "** WARNING: DARKNET from environment: ${DARKNET}" &> /dev/stderr; fi
cd ${DARKNET}

while true; do
  # capture image from /dev/video0 and grab file attributes for later use
  fswebcam --scale "${SCALE}" --no-banner "${JPG}" &> "${OUT}"
  # extract image size
  WIDTH=$(egrep 'resolution' "${OUT}" | sed 's/.* to \([^\.]*\)\./\1/' | sed 's/\([0-9]*\)x\([0-9]*\)/\1/')
  if [ -z "${WIDTH}" ]; then WIDTH=0; fi
  HEIGHT=$(egrep 'resolution' "${OUT}" | sed 's/.* to \([^\.]*\)\./\1/' | sed 's/\([0-9]*\)x\([0-9]*\)/\2/')
  if [ -z "${HEIGHT}" ]; then HEIGHT=0; fi
  # test image 
  if [ ! -s "${JPG}" ]; then 
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
  # count entity
  COUNT=$(egrep '^'"${YOLO_ENTITY}" "${OUT}" | wc -l)
  # capture annotated image as BASE64 encoded string
  IMAGE=$(base64 -w 0 -i predictions.jpg)
  echo '{"date":'$(date +%s)',"time":'${TIME}',"entity":"'${YOLO_ENTITY}'","count":'${COUNT}',"width":'${WIDTH}',"height":'${HEIGHT}',"scale":"'${SCALE}'","mock":"'${MOCK}'","image":"'${IMAGE}'"}' > ${TMP}/${HZN_PATTERN}.json
  rm -f "${JPG}" "${OUT}" predictions.jpg

  sleep ${YOLO_PERIOD}
done

