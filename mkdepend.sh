#!/bin/bash

# where
if [ -z "${1}" ]; then DIR="horizon"; else DIR="${1}"; fi
if [ ! -d "${DIR}" ]; then
  echo "*** ERROR $0 $$ -- no directory ${DIR}" &> /dev/stderr
  exit 1
fi

# what
SERVICE="${DIR}/service.definition"
USERINPUT="${DIR}/userinput"

# mandatory
for json in ${SERVICE} ${USERINPUT}; do
if [ ! -s "${json}.json" ]; then echo "*** ERROR $0 $$ -- no ${json}.json" 2> /dev/stderr; exit 1; fi
done

# architecture
ARCH=$(jq -r '.arch' "${SERVICE}.json")

# environment
if [ -z "${HZN_EXCHANGE_URL:-}" ] || [ -z "${HZN_EXCHANGE_USERAUTH:-}" ]; then
  echo "Usage: export HZN_EXCHANGE_URL=<url> HZN_EXCHANGE_USERAUTH=<auth> && $0 [horizon|<directory>]" &> /dev/stderr
  exit 1
fi

# tagging
if [ ! -z "${TAG:-}" ]; then
  echo "+++ WARN $0 $$ -- modifying service URL with ${TAG} in ${USERINPUT}.json and ${SERVICE}.json" &> /dev/stderr
  jq -c '.services=[.services[]|.url as $url|.url=$url+"-'${TAG}'"]' ${USERINPUT}.json > /tmp/$$
  mv -f /tmp/$$ ${USERINPUT}.json
  jq -c '.requiredServices=[.requiredServices[]|.url as $url|.url=$url+"-'${TAG}'"]' ${SERVICE}.json > /tmp/$$
  mv -f /tmp/$$ ${SERVICE}.json
fi

# architecture
jq -c '.requiredServices=[.requiredServices[]|.arch="'${ARCH}'"]' ${SERVICE}.json > /tmp/$$
mv -f /tmp/$$ ${SERVICE}.json

jq -r '.requiredServices|to_entries[]|.value.url' "${SERVICE}.json" | while read -r; do
    URL="${REPLY}"
    if [ -z "${URL}" ]; then echo "Error: empty required service URL: ${URL}" &> /dev/stderr; exit 1; fi
    VER=$(jq -r '.requiredServices|to_entries[]|select(.value.url=="'${URL}'").value.version' "${SERVICE}.json")
    if [ -z "${VER}" ]; then echo "Error: empty version for required service ${URL}" &> /dev/stderr; exit 1; fi
    ORG=$(jq -r '.requiredServices|to_entries[]|select(.value.url=="'${URL}'").value.org' "${SERVICE}.json")
    if [ -z "${ORG}" ]; then echo "Error: empty org for required service ${URL}" &> /dev/stderr; exit 1; fi
    hzn dev dependency fetch -d ${DIR}/ --ver "${VER}" --arch "${ARCH}" --org "${ORG}" --url "${URL}" -u "${HZN_EXCHANGE_USERAUTH}"
    if [ $? != 0 ]; then
      echo "*** ERROR $0 $$ -- dependency ${REPLY} was not fetched; exiting" &> /dev/stderr
      exit 1
    fi
done

