#!/bin/bash

DEBUG=

if [ -z "${HZN_EXCHANGE_URL}" ]; then HZN_EXCHANGE_URL="https://alpha.edge-fabric.com/v1"; fi

DIR="${1}"
if [ -z "${DIR}" ]; then DIR="horizon"; echo "+++ WARN -- $0 $$ -- directory not specified; using ${DIR}" &> /dev/stderr; fi
if [ ! -d "${DIR}" ]; then echo "*** ERROR -- $0 $$ -- cannot find directory ${DIR}" &> /dev/stderr; exit 1; fi

###
### EXCHANGE
###

hzn_exchange()
{
  ITEM="${1}"
  ITEMS='null'
  if [ ! -z "${ITEM}" ]; then
    URL="${HZN_EXCHANGE_URL}/orgs/${SERVICE_ORG}/${ITEM}"
    ALL=$(curl -fsSL -u "${SERVICE_ORG}/iamapikey:$(cat APIKEY)" "${URL}")
    ENTITYS=$(echo "${ALL}" | jq '{"'${ITEM}'":[.'${ITEM}'| objects | keys[]] | unique}' | jq -r '.'${ITEM}'[]') 
    ITEMS='{"'${ITEM}'":['
    i=0; for ENTITY in ${ENTITYS}; do 
      if [[ $i > 0 ]]; then ITEMS="${ITEMS}"','; fi
      ITEMS="${ITEMS}"$(echo "${ALL}" | jq '.'${ITEM}'."'"${ENTITY}"'"' | jq -c '.id="'"${ENTITY}"'"')
      i=$((i+1))
    done
    ITEMS="${ITEMS}"']}'
  fi
  echo "${ITEMS}"
}

exchange_services() {
  if [ -z "${EXCHANGE_SERVICES:-}" ]; then EXCHANGE_SERVICES=$(hzn_exchange services); fi
  echo "${EXCHANGE_SERVICES}"
}

exchange_patterns() {
  if [ -z "${EXCHANGE_PATTERNS:-}" ]; then EXCHANGE_PATTERNS=$(hzn_exchange patterns); fi
  echo "${EXCHANGE_PATTERNS}"
}

find_service_in_exchange() {
  id="${1}"
  RESULT=$(exchange_services | jq '.services[]|select(.id=="'${id}'")')
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- find_service_in_exchange ${service}; result (label):" $(echo "${RESULT}" | jq -c '.label') &> /dev/stderr; fi
  echo "${RESULT}"
}

find_pattern_in_exchange() {
  id="${1}"
  RESULT=$(exchange_patterns | jq '.patterns[]|select(.id=="'${id}'")')
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- find_pattern_in_exchange ${pattern}; result (label):" $(echo "${RESULT}" | jq -c '.label') &> /dev/stderr; fi
  echo "${RESULT}"
}

is_service_in_exchange() {
  service="${1}"
  RESULT=$(find_service_in_exchange ${service})
  if [ -z "${RESULT}" ]; then RESULT='false'; else RESULT='true'; fi
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- is_service_in_exchange ${service}; result: ${RESULT}" &> /dev/stderr; fi
  echo "${RESULT}"
}

is_pattern_in_exchange() {
  pattern="${1}"
  RESULT=$(find_pattern_in_exchange ${pattern})
  if [ -z "${RESULT}" ]; then RESULT='false'; else RESULT='true'; fi
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- is_pattern_in_exchange ${pattern}; result: ${RESULT}" &> /dev/stderr; fi
  echo "${RESULT}"
}

###
### SERVICES
###

read_service_file() {
  jq -c '.' "${SERVICE_FILE}"
}

get_required_service_ids() {
  echo $(echo "${*}" | jq -j '.requiredServices[]|.org,"/",.url,"_",.version,"_",.arch," "')
}

is_image_in_registry() {
  service="${1}"
  IMAGE=$(echo "${SERVICES}" | jq -r '.[]|select(.id=="'${service}'").image')
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- is_image_in_registry ${service}; image: ${IMAGE}" &> /dev/stderr; fi
  docker pull "${IMAGE}" &> /dev/null && STATUS=$?
  docker rmi "${IMAGE}" &> /dev/null
  if [ $STATUS == 0 ]; then echo 'true'; else echo 'false'; fi
}

test_service_arch_support () {
  RESULT='true'
  for arch in ${ARCH_SUPPORT}; do
    sid="${SERVICE_ORG}/${SERVICE_URL}_${SERVICE_VER}_${arch}"
    if [ $(is_service_in_exchange "${sid}") != 'true' ]; then
      if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- service ${sid} is NOT in exchange" &> /dev/stderr; fi
      RESULT='false'
    else
      if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- service ${sid} is FOUND in exchange" &> /dev/stderr; fi
    fi
  done
  echo "${RESULT}"
}

## test if all services have images in registry
test_service_images() {
  SERVICES=$(jq '[.deployment.services|to_entries[]|{"id":.key,"image":.value.image}]' "${SERVICE_FILE}")
  for service in $(echo "${SERVICES}" | jq -r '.[].id'); do
    if [ "{DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- checking registry for service ${service}" &> /dev/stderr; fi
    STATUS=$(is_image_in_registry "${service}")
    if [ "${STATUS}" == 'true' ]; then
      if [ "{DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- found image ${IMAGE} in registry; status: ${STATUS}" &> /dev/stderr; fi
    else
      STATUS=false
      if [ "{DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- no existing image ${IMAGE} in registry; status: ${STATUS}" &> /dev/stderr; fi
    fi
    echo "${STATUS}"
  done
  echo "${STATUS}"
}

semver_gt() {
  RESULT='false'
  ev1="${1%%.*}"
  ev2="${1%.*}" && ev2=${ev2##*.}
  ev3="${1##*.}"
  nv1="${2%%.*}"
  nv2="${2%.*}" && nv2=${nv2##*.}
  nv3="${2##*.}"
  if [ ${ev1} -gt ${nv1} ]; then RESULT='true'; fi
  if [ ${ev1} -ge ${nv1} ] && [ ${ev2} -gt ${nv2} ]; then RESULT='true'; fi
  if [ ${ev1} -ge ${nv1} ] && [ ${ev2} -ge ${nv2} ] && [ ${ev3} -gt ${nv3} ]; then RESULT='true'; fi
  echo "${RESULT}" 
}

## service_test
service_test() {
  id="${1}"
  STATUS=0
  RESULT=$(is_service_in_exchange "${id}") 
  if [ "${RESULT}" != 'true' ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- no existing service ${id} in exchange; status: ${RESULT}" &> /dev/stderr; fi
  else
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- found service ${id} in exchange; status: ${RESULT}" &> /dev/stderr; fi
  fi
  rsids=$(get_required_service_ids $(read_service_file))
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- found required services ids: ${rsids}" &> /dev/stderr; fi
  if [ ! -z "${rsids}" ]; then
    for RS in ${rsids}; do
      version=$(echo "${RS}" | sed 's|.*/.*_\(.*\)_.*|\1|')
      if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- checking required service: ${RS}; version ${version}" &> /dev/stderr; fi
      if [ $(is_service_in_exchange "${RS}") != 'true' ]; then
	STATUS=1
	if [ "${DEBUG:-}" == 'true' ]; then echo "*** ERROR -- $0 $$ -- no existing service ${RS} in exchange; status: ${STATUS}" &> /dev/stderr; fi
      else
        rsie=$(find_service_in_exchange "${RS}")
	url=$(echo "${rsie}" | jq -r '.url')
	arch=$(echo "${rsie}" | jq -r '.arch')

	for ver in $(exchange_services | jq -r '.services[]|select(.url=="'${url}'" and .arch=="'${arch}'")|.version'); do
	  if [ $(semver_gt "${ver}" "${version}") == 'true' ]; then
	    STATUS=1
	    if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- NEWER: exchange: ${ver}; service: ${version}; url: ${url}; arch: ${arch}; status: ${STATUS}" &> /dev/stderr; fi
          fi 
	done
      fi
    done
  else
    echo "+++ WARN -- $0 $$ -- no required services found in service JSON" &> /dev/stderr
  fi
  echo "${STATUS}"
}

###
### PATTERN
###

read_pattern_file() {
  jq -c '.' "${PATTERN_FILE}"
}

get_pattern_service_ids() {
  echo $(echo "${*}" | jq -j '.services[]|.serviceOrgid,"/",.serviceUrl,"_",.serviceVersions[].version,"_",.serviceArch," "')
}

get_pattern_file_services() {
  echo $(jq -j '.services[]|.serviceOrgid,"/",.serviceUrl,"_",.serviceVersions[].version,"_",.serviceArch," "' "${1}")
}

pattern_services_in_exchange() {
  pattern_services="${*}"
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- pattern services: ${pattern_services}" &> /dev/stderr; fi
  STATUS='true'
  if [ ! -z "${pattern_services}" ]; then
    for PS in ${pattern_services}; do
      if [ $(is_service_in_exchange "${PS}") != 'true' ]; then
        STATUS='false'
	if [ "${DEBUG:-}" == 'true' ]; then echo "*** ERROR -- $0 $$ -- no existing service ${PS} in exchange; status: ${STATUS}" &> /dev/stderr; fi
      else
	if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- found service ${PS} in exchange; status: ${STATUS}" &> /dev/stderr; fi
      fi
    done
  else
    echo "+++ WARN -- $0 $$ -- no services found in pattern JSON" &> /dev/stderr
  fi
  echo "${STATUS}"
}

## pattern_test
pattern_test() {
  id="${1}"
  STATUS=0
  ## test if all services for pattern exist
  RESULT=$(pattern_services_in_exchange $(get_pattern_service_ids $(read_pattern_file)))
  if [ "${RESULT}" != 'true' ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "*** ERROR -- $0 $$ -- pattern ${id}: some exchange services are MISSING" &> /dev/stderr; fi
    STATUS=1
  else
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- pattern ${id}: all exchange services are AVAILABLE" &> /dev/stderr; fi
    ## test if pattern exists
    RESULT=$(is_pattern_in_exchange "${id}")
    if [ "${RESULT}" == 'true' ]; then
      if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- pattern ${id}: EXISTS in exchange; checking services..." &> /dev/stderr; fi
      sipf=$(get_pattern_service_ids $(read_pattern_file))
      siex=$(get_pattern_service_ids $(find_pattern_in_exchange "${id}"))
      for sp in ${sipf}; do
	match=false
	for xp in ${siex}; do
	  if [ "${sp}" == "${xp}" ]; then match=true; break; fi
	done
	if [ "${match}" != 'true' ]; then break; fi
      done
      if [ "${match}" == 'true' ]; then 
	echo "*** ERROR -- $0 $$ -- pattern: ${id}: services: NO change" &> /dev/stderr
	STATUS=1
      else
	echo "--- WARN -- $0 $$ -- pattern: ${id}: services: CHANGED" &> /dev/stderr
      fi
    else
      if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- pattern ${id}: AVAILABLE in exchange" &> /dev/stderr; fi
    fi
  fi
  echo "${STATUS}"
}

###
### MAIN
###

## get name of script
SCRIPT_NAME="${0##*/}" && SCRIPT_NAME="${SCRIPT_NAME%.*}"



STATUS=1
EXCHANGE_SERVICES=
EXCHANGE_PATTERNS=
PATTERN_SERVICES=

BUILD_FILE="build.json"
if [ ! -s "${BUILD_FILE}" ]; then echo "*** ERROR -- $0 $$ -- build JSON ${BUILD_FILE} not found; exiting" &> /dev/stderr; exit 1; fi
ARCH_SUPPORT=$(jq -r '.build_from|to_entries[].key' "${BUILD_FILE}")

SERVICE_FILE="${2}"
if [ -z "${SERVICE_FILE}" ]; then SERVICE_FILE="${DIR}/service.definition.json"; echo "+++ WARN -- $0 $$ -- service JSON not specified; using ${SERVICE_FILE}" &> /dev/stderr; fi
SERVICE_ORG=$(jq -r '.org' "${SERVICE_FILE}")

case ${SCRIPT_NAME} in 
  pattern-test)
	PATTERN_FILE="${3}"
	if [ -z "${PATTERN_FILE}" ]; then PATTERN_FILE="${DIR}/pattern.json"; echo "+++ WARN -- $0 $$ -- pattern JSON not specified; using ${PATTERN_FILE}" &> /dev/stderr; fi
	if [ -s "${PATTERN_FILE}" ]; then
	  PATTERN_LABEL=$(read_pattern_file | jq -r '.label')
	  ID="${SERVICE_ORG}/${PATTERN_LABEL}"
	  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- testing pattern ${ID}" &> /dev/stderr; fi
	  STATUS=$(pattern_test "${ID}")
        else
	  STATUS=0
	  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- no pattern: ${PATTERN_FILE}; status: ${STATUS}" &> /dev/stderr; fi
        fi
	;;
  service-test) 
	if [ -s "${SERVICE_FILE}" ]; then
          SERVICE_LABEL=$(read_service_file | jq -r '.label')
	  SERVICE_ARCH=$(read_service_file | jq -r '.arch')
	  SERVICE_URL=$(read_service_file | jq -r '.url')
	  SERVICE_VER=$(read_service_file | jq -r '.version')
	  ID="${SERVICE_ORG}/${SERVICE_URL}_${SERVICE_VER}_${SERVICE_ARCH}"
	  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- testing service ${ID}" &> /dev/stderr; fi
	  STATUS=$(service_test "${ID}")
	else
	  STATUS=0
	  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- no service: ${SERVICE_FILE}; status: ${STATUS}" &> /dev/stderr; fi
	fi
	;;
  *)
	if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- invalid script: ${SCRIPT_NAME}" &> /dev/stderr; fi
	;;
esac

exit ${STATUS}
