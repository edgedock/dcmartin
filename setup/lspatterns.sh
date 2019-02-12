#!/bin/bash
if [ -z $(command -v jq) ]; then
  echo "*** ERROR $0 $$ -- please install jq"
  exit 1
fi

CONFIG="horizon.json"
if [ -z "${1}" ]; then
  if [ -s "${CONFIG}" ]; then
    echo "+++ WARN $0 $$ -- no configuration specified; default found: ${CONFIG}" &> /dev/stderr
  else
    echo "*** ERROR $0 $$ -- no configuration specified; no default: ${CONFIG}; run mkconfig.sh" &> /dev/stderr
    exit 1
  fi
else
  CONFIG="${1}"
fi
if [ ! -s "${CONFIG}" ]; then
  echo "*** ERROR $0 $$ -- configuration file empty: ${1}" &> /dev/stderr
  exit 1
fi

IBM_CLOUD_APIKEY=$(jq -r '.exchanges[]|select(.id=="alpha")|.password' "${CONFIG}")
if [ -z "${IBM_CLOUD_APIKEY}" ] || [ "${IBM_CLOUD_APIKEY}" == "null" ]; then
  echo "*** ERROR $0 $$ -- invalid IBM_CLOUD_APIKEY" &> /dev/stderr
  exit 1
fi
  
HZN_EXCHANGE_URL=$(jq -r '.exchanges[]|select(.id=="alpha")|.url' "${CONFIG}")
if [ -z "${HZN_EXCHANGE_URL}" ] || [ "${HZN_EXCHANGE_URL}" == "null" ]; then
  echo "*** ERROR $0 $$ -- invalid HZN_EXCHANGE_URL" &> /dev/stderr
  exit 1
fi

IBM_CLOUD_LOGIN_EMAIL=$(jq -r '.exchanges[]|select(.id=="alpha")|.org' "${CONFIG}")
if [ -z "${IBM_CLOUD_LOGIN_EMAIL}" ] || [ "${IBM_CLOUD_LOGIN_EMAIL}" == "null" ]; then
  echo "*** ERROR $0 $$ -- invalid IBM_CLOUD_LOGIN_EMAIL" &> /dev/stderr
  exit 1
fi

ALL=$(curl -sL -u "${IBM_CLOUD_LOGIN_EMAIL}/iamapikey:${IBM_CLOUD_APIKEY}" "${HZN_EXCHANGE_URL}/orgs/${IBM_CLOUD_LOGIN_EMAIL}/patterns")
PATTERNS=$(echo "${ALL}" | jq '{"patterns":[.patterns | objects | keys[]] | unique}' | jq -r '.patterns[]')  
OUTPUT='{"patterns":['
i=0; for PATTERN in ${PATTERNS}; do 
  if [[ $i > 0 ]]; then OUTPUT="${OUTPUT}"','; fi
  OUTPUT="${OUTPUT}"$(echo "${ALL}" | jq '.patterns."'"${PATTERN}"'"' | jq -c '.id="'"${PATTERN}"'"')
  i=$((i+1))
done 
OUTPUT="${OUTPUT}"']}'
echo "${OUTPUT}" | jq -c '.'
