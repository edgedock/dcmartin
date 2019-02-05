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
      VALID=$(echo "${REPLY}" | ./test-yolo2msghub.sh 2> /dev/null)
    else
      echo "+++ WARN $0 $$ -- null payload"
      continue
    fi
    if [ "${VALID}" != 'true' ]; then
      echo "+++ WARN $0 $$ -- invalid payload: ${REPLY}"
      continue
    fi
    ID=$(echo "${REPLY}" | jq -r '.hzn.device_id')
    DATE=$(echo "${REPLY}" | jq -r '.yolo2msghub.yolo.date')
    THIS=$(echo "${DEVICES}" | jq '.[]|select(.id=="'${ID}'")')
    if [ -z "${THIS}" ] || [ "${THIS}" == 'null' ]; then
      THIS='{"id":"'${ID}'","date":'${DATE}',"count":0}'
      DEVICES=$(echo "${DEVICES}" | jq '.+=['"${THIS}"']')
      TOTAL=0
      LAST=0
    else
      TOTAL=$(echo "${THIS}" | jq '.count')
      LAST=$(echo "${THIS}" | jq '.date')
    fi

    DEVICES=$(echo "${DEVICES}" | jq '(.[]|select(.id=="'${ID}'"))|='"${THIS}")

    if [ $(echo "${REPLY}" | jq '.yolo2msghub.yolo!=null') == 'true' ]; then
      if [ $(echo "${REPLY}" | jq -r '.yolo2msghub.yolo.mock') != 'true' ]; then
        if [ ${DATE} -gt ${LAST} ]; then
	  COUNT=$(echo "${REPLY}" | jq -r '.yolo2msghub.yolo.count')
          if [ ${COUNT} -gt 0 ]; then
	    echo "--- INFO $0 $$ -- ${ID} at ${DATE}: person count ${COUNT}"
            TOTAL=$((${TOTAL}+${COUNT}))
            THIS=$(echo "${THIS}" | jq '.count='${TOTAL})
            echo "${REPLY}" | jq -r '.yolo2msghub.yolo.image' | base64 --decode > $0.$$.jpeg
            if [ ! -z $(command -v open) ]; then open $0.$$.jpeg; fi
	  else
	    echo "+++ WARN $0 $$ -- ${ID} at ${DATE}: no person"
          fi
          THIS=$(echo "${THIS}" | jq '.date='${DATE})
	  DEVICES=$(echo "${DEVICES}" | jq '(.[]|select(.id=="'${ID}'"))|='"${THIS}")
          DEVICES=$(echo "${DEVICES}" | jq '.|sort_by(.count)|reverse')
        fi
      else
	echo "+++ WARN $0 $$ -- ${ID} at ${DATE}: mock"
      fi
    else
      echo "+++ WARN $0 $$ -- ${ID} at ${DATE}: no yolo output"
    fi
    echo "${DEVICES}" | jq -c '.'
done
rm -f $0.$$.*
