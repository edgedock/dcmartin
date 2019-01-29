#!/bin/bash
if [ ! -z "${1}" ] && [ ! -z "${HZN_EXCHANGE_URL:-}" ] && [ ! -z "${HZN_EXCHANGE_USERAUTH:-}" ]; then
  if [ -z "${1}" ]; then DIR="horizon"; else DIR="${1}"; fi
  if [ ! -d "${DIR}" ]; then echo "Error: no directory ${DIR}" &> /dev/stderr; exit 1; fi
  SVC="${DIR}/service.definition.json"
  if [ ! -s "${SVC}" ]; then echo "Error: no ${SVC}" &> /dev/stderr; exit 1; fi
  ARCH=$(jq -r '.arch' "${SVC}")
  jq -r '.requiredServices|to_entries[]|.value.url' "${SVC}" | while read -r; do
    URL="${REPLY}"
    if [ -z "${URL}" ]; then echo "Error: empty required service URL: ${URL}" &> /dev/stderr; exit 1; fi
    VER=$(jq -r '.requiredServices|to_entries[]|select(.value.url=="'${URL}'").value.version' "${SVC}")
    if [ -z "${VER}" ]; then echo "Error: empty version for required service ${URL}" &> /dev/stderr; exit 1; fi
    ORG=$(jq -r '.requiredServices|to_entries[]|select(.value.url=="'${URL}'").value.org' "${SVC}")
    if [ -z "${ORG}" ]; then echo "Error: empty org for required service ${URL}" &> /dev/stderr; exit 1; fi
    echo hzn dev dependency fetch -d test/ --ver "${VER}" --arch "${ARCH}" --org "${ORG}" --url "${URL}" -u "${HZN_EXCHANGE_USERAUTH}"
    hzn dev dependency fetch -d test/ --ver "${VER}" --arch "${ARCH}" --org "${ORG}" --url "${URL}" -u "${HZN_EXCHANGE_USERAUTH}"
  done
  exit 0
else
  echo "Usage: export HZN_EXCHANGE_URL=<url> HZN_EXCHANGE_USERAUTH=<auth> && $0 service.json [ <directory> (default: horizon) ]" &> /dev/stderr
  exit 1
fi

