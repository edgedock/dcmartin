#!/bin/bash
fswebcam /tmp/image.$$.jpg
/darknet/darknet detector test cfg/voc.data cfg/yolov2-tiny-voc.cfg yolov2-tiny-voc.weights /tmp/image.$$.jpg > /tmp/image.$$.out
TIME=$(cat /tmp/image.$$.out | egrep "Predicted" | sed 's/.*Predicted in \([^ ]*\).*/\1/')
PERSONS=$(cat /tmp/image.$$.out | egrep '^person' | wc -l)
NODEID=$(hzn node list | jq -r '.id')
echo '{"devid":"'${NODEID}'","date":$(date +%s),"time":'${TIME}',"person":'${PERSONS}'}'
