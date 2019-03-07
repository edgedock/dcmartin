#!/bin/bash

if [ -z "${1}" ]; then
  echo "*** ERROR -- $0 $$ -- no Docker tag specified; exiting" &> /dev/stderr
  exit 1
fi
DOCKER_TAG="${1}"

CID=$(docker ps --format '{{.Names}} {{.Image}}' | egrep "${DOCKER_TAG}" | awk '{ print $1 }')
if [ -z "${CID}" ]; then
  echo "*** ERROR -- $0 $$ -- cannot find running container with tag: ${DOCKER_TAG}" &> /dev/stderr
  exit 1
fi

if [ ! -z "${2}" ]; then
  HOST="${2}"
else
  HOST="127.0.0.1"
  echo "--- INFO -- $0 $$ -- No host specified; assuming ${HOST}" &> /dev/stderr
fi

if [ "${HOST%:*}" == "${HOST}" ]; then
  PORT=$(jq -r '.ports?|to_entries|first|.key?' service.json | sed 's|\(.*\)/.*|\1|')
  echo "+++ WARN $0 $$ -- No port specified; assuming port ${PORT}" &> /dev/stderr
  HOST="${HOST}:${PORT}"
fi

if [[ ${HOST} =~ http* ]]; then
  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- protocol specified" &> /dev/stderr; fi
else
  PROT="http"
  echo "+++ WARN $0 $$ -- No protocol specified; assuming ${PROT}" &> /dev/stderr
  HOST="${PROT}://${HOST}"
fi

if [ -z "${SERVICE_LABEL:-}" ]; then SERVICE_LABEL=${PWD##*/}; fi
CMD="${PWD}/test-${SERVICE_LABEL}.sh"
if [ -z $(command -v "${CMD}") ]; then
  echo "+++ WARN -- $0 $$ -- no test script: ${CMD}; exiting" &> /dev/stderr
  exit 0
fi

if [ -z ${TIMEOUT:-} ]; then TIMEOUT=5; fi

echo "--- INFO -- $0 $$ -- Testing ${SERVICE_LABEL} in container tagged: ${DOCKER_TAG} at" $(date) &> /dev/stderr

I=0

while true; do
  OUT=$(docker exec "${CID}" curl -m ${TIMEOUT} -sSL "${HOST}")
  if [ $? != 0 ]; then
    echo "*** ERROR -- $0 $$ -- curl failed to ${HOST}" &> /dev/stderr
    echo 'null'
    exit 1
  fi
  if [ ! -z "${OUT}" ] && [ "${OUT}" != 'null' ]; then
    echo "${OUT}" > "test.json"
    if [ ! -z "$(command -v ${CMD})" ]; then
      TEST=$(echo "${OUT}" | ${CMD})
      if [ "${TEST:-}" == 'true' ]; then
        echo "!!! SUCCESS -- $0 $$ -- test ${CMD} returned ${TEST}" &> /dev/stderr
	echo "${TEST}"
        exit 0
      else
        echo "*** ERROR -- $0 $$ -- test ${CMD} returned ${TEST}" &> /dev/stderr
	echo "${OUT}"
        exit 1
      fi
    else
        echo "+++ WARN -- $0 $$ -- missing test command: ${CMD}" &> /dev/stderr
    fi
  else
    echo "*** ERROR -- $0 $$ -- ${HOST} returns ${OUT}" &> /dev/stderr
    exit 1
  fi
  if [ $(date +%s) -gt ${TIMEOUT} ]; then
    echo "*** ERROR -- $0 $$ -- timeout" &> /dev/stderr
    exit 1
  fi
  I=$((I+1))
  echo '--- INFO -- $0 $$ -- iteration ${I}; sleeping ...' &> /dev/stderr
  sleep 1
done
