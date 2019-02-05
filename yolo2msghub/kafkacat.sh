#!/bin/bash
BROKER="kafka05-prod02.messagehub.services.us-soutbluemix.net:9093,kafka01-prod02.messagehub.services.us-south.bluemix.net:9093,kafka03-prod02.messagehub.services.us-south.bluemix.net:9093,kafka04-prod02.messagehub.services.us-south.bluemix.net:9093,kafka02-prod02.messagehub.services.us-south.bluemix.net:9093"
APIKEY=$(sed -e 's|"\(.*\)"|\1|' YOLO2MSGHUB_APIKEY)
TOPIC="yolo2msghub"
DEVICES='[]'

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
    ID=$(echo "${REPLY}" | jq -r '.hzn.device_id')
    DATE=$(echo "${REPLY}" | jq -r '.yolo2msghub.yolo.date')
    THIS=$(echo "${DEVICES}" | jq '.[]|select(.id=="'${ID}'")')
    if [ -z "${THIS}" ] || [ "${THIS}" == 'null' ]; then
      THIS='{"id":"'${ID}'","date":'${DATE}'}'
      DEVICES=$(echo "${DEVICES}" | jq '.+=['"${THIS}"']')
      echo "${DEVICES}"
      LAST=0
    else
      echo LAST=$(echo "${THIS}" | jq '.date')
    fi
    if [ $(echo "${REPLY}" | jq '.yolo2msghub.yolo!=null') == 'true' ]; then
      if [ $(echo "${REPLY}" | jq -r '.yolo2msghub.yolo.mock') != 'true' ]; then
        if [ ${DATE} -gt ${LAST} ]; then
          DATE=${LAST}
          if [ $(echo "${REPLY}" | jq -r '.yolo2msghub.yolo.count') -gt 0 ]; then
            echo "${REPLY}" | jq -r '.yolo2msghub.yolo.image' | base64 --decode > $0.$$.jpeg
            if [ ! -z $(command -v open) ]; then open $0.$$.jpeg; fi
          fi
        fi
      fi
    fi
    echo "ALL:" $(jq -r '.hzn.device_id' $0.$$.out | sort | uniq)
done
rm -f $0.$$.*
