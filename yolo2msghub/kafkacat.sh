#!/bin/bash
BROKER="kafka05-prod02.messagehub.services.us-soutbluemix.net:9093,kafka01-prod02.messagehub.services.us-south.bluemix.net:9093,kafka03-prod02.messagehub.services.us-south.bluemix.net:9093,kafka04-prod02.messagehub.services.us-south.bluemix.net:9093,kafka02-prod02.messagehub.services.us-south.bluemix.net:9093"
APIKEY=$(sed -e 's|"\(.*\)"|\1|' YOLO2MSGHUB_APIKEY)
TOPIC="yolo2msghub"

kafkacat -E -u -C -q -o end -f "%s\n" -b "${BROKER}" \
  -X "security.protocol=sasl_ssl" \
  -X "sasl.mechanisms=PLAIN" \
  -X "sasl.username=${APIKEY:0:16}" \
  -X "sasl.password=${APIKEY:16}" \
  -t "${TOPIC}" | while read -r; do
    if [ -n "${REPLY}" ]; then
      echo "${REPLY}" >> $0.$$.out
      echo "${REPLY}" | ./test-yolo2msghub.sh
    else
      continue
    fi
  echo "LAST:" $(jq -r '.hzn.device_id' $0.$$.out | tail -1)
  echo "ALL:" $(jq -r '.hzn.device_id' $0.$$.out | sort | uniq)
done
rm -f $0.$$.out
