#!/usr/bin/env bash

kafka_mktopic() {
  topic=
  if [ ! -z "${1}" ]; then 
    topic='{"name":"'${1}'"}'
    response=$(curl -sSL -H 'Content-Type: application/json' -H "X-Auth-Token: ${MQTT2KAFKA_APIKEY}" "${MQTT2KAFKA_ADMIN_URL}/admin/topics" -d "${topic}"
    if [ "$(echo "${response}" | jq '.errorCode!=null')" == 'true' ]; then
      echo "+++ WARN $0 $$ -- topic: ${topic}; message:" $(echo "${response}" | jq -r '.errorMessage') &> /dev/stderr
    fi
  fi
  echo "${topic}"
}
