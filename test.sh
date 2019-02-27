#!/bin/bash

if [ ! -z "${1}" ]; then
  HOST="${1}"
else
  HOST="127.0.0.1"
  echo "--- INFO -- $0 $$ -- No host specified; assuming ${HOST}"
fi

if [ "${HOST%:*}" == "${HOST}" ]; then
  PORT=$(jq -r '.ports?|to_entries|first|.value?' service.json)
  echo "--- INFO -- $0 $$ -- No port specified; assuming port ${PORT}"
  HOST="${HOST}:${PORT}"
fi

if [[ ${HOST} =~ http* ]]; then
  echo "T"
else
  PROT="http"
  echo "--- INFO -- $0 $$ -- No protocol specified; assuming ${PROT}"
  HOST="${PROT}://${HOST}"
fi

if [ -z "${SERVICE_LABEL:-}" ]; then SERVICE_LABEL=${PWD##*/}; fi
CMD="${PWD}/test-${SERVICE_LABEL}.sh"

if [ -z ${TIMEOUT:-} ]; then TIMEOUT=5; fi
DATE=$(($(date +%s)+${TIMEOUT}))

echo "--- INFO -- $0 $$ -- Testing ${HOST} at" $(date)

I=0

while true; do
  OUT=$(curl -m ${TIMEOUT} -sSL "${HOST}")
  if [ $? != 0 ]; then
    echo "ERROR: curl failed to http://${HOST}" &> /dev/stderr
    exit 1
  fi
  if [ ! -z "${OUT}" ] && [ "${OUT}" != 'null' ]; then
    if [ ! -z "$(command -v ${CMD})" ]; then
      TEST=$(echo "${OUT}" | ${CMD})
      if [ "${TEST:-}" == 'true' ]; then
        echo "!!! SUCCESS -- $0 $$ -- test ${CMD} returned ${TEST}" &> /dev/stderr
        exit 0
      else
        echo "*** ERROR -- $0 $$ -- test ${CMD} returned ${TEST}" &> /dev/stderr
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
  echo '--- INFO -- $0 $$ -- iteration ${I}; sleeping ...'
  sleep 1
done
