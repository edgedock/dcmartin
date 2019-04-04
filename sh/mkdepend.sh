#!/bin/bash

# test envsubst
if [ -z $(command -v "envsubst") ]; then
  echo "*** ERROR -- $0 $$ -- please install gettext package for command envsubst" &> /dev/stderr
  exit 1
fi

# where
if [ -z "${1}" ]; then DIR="horizon"; else DIR="${1}"; fi
if [ ! -d "${DIR}" ]; then
  echo "*** ERROR -- $0 $$ -- no directory ${DIR}" &> /dev/stderr
  exit 1
fi

# what
SERVICE="${DIR}/service.definition"
USERINPUT="${DIR}/userinput"

# mandatory
for json in ${SERVICE} ${USERINPUT}; do
if [ ! -s "${json}.json" ]; then echo "*** ERROR -- $0 $$ -- no ${json}.json" 2> /dev/stderr; exit 1; fi
done

# architecture
ARCH=$(jq -r '.arch' "${SERVICE}.json")

# environment
if [ -z "${HZN_EXCHANGE_URL:-}" ]; then
  echo "Error: no HZN_EXCHANGE_URL" &> /dev/stderr
  exit 1
fi
if [ -z "${HZN_EXCHANGE_USERAUTH:-}" ]; then
  echo "Error: no HZN_EXCHANGE_USERAUTH" &> /dev/stderr
  exit 1
fi
if [ -z "${HZN_ORG_ID:-}" ]; then
  echo "Error: no HZN_ORG_ID" &> /dev/stderr
  exit 1
fi

jq -r '.requiredServices|to_entries[]|.value.url' "${SERVICE}.json" | while read -r; do
    URL="${REPLY}"
    if [ -z "${URL}" ]; then echo "Error: empty required service URL: ${URL}" &> /dev/stderr; exit 1; fi
    VER=$(jq -r '.requiredServices|to_entries[]|select(.value.url=="'${URL}'").value.version' "${SERVICE}.json")
    if [ -z "${VER}" ]; then echo "Error: empty version for required service ${URL}" &> /dev/stderr; exit 1; fi
    ORG=$(jq -r '.requiredServices|to_entries[]|select(.value.url=="'${URL}'").value.org' "${SERVICE}.json" | envsubst)
    if [ -z "${ORG}" ]; then echo "Error: empty org for required service ${URL}" &> /dev/stderr; exit 1; fi
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- hzn dev dependency fetch -d ${DIR}/ --ver ${VER} --arch ${ARCH} --org ${ORG} --url ${URL} -u ${HZN_EXCHANGE_USERAUTH}"; fi
    hzn dev dependency fetch -d ${DIR}/ --ver "${VER}" --arch "${ARCH}" --org "${ORG}" --url "${URL}" -u "${HZN_EXCHANGE_USERAUTH}"
    if [ $? != 0 ]; then
      echo "*** ERROR -- $0 $$ -- dependency ${REPLY} was not fetched; exiting" &> /dev/stderr
      exit 1
    fi
done

