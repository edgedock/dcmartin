#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

if [ -z "${HZNCLI_PERIOD}" ]; then HZNCLI_PERIOD=60; fi

CONFIG='{"date":'$(date +%s)',"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"period":'${HZNCLI_PERIOD}'}'
echo "${CONFIG}" > ${TMPDIR}/${SERVICE_LABEL}.json

while true; do
  DATE=$(date +%s)

  CONFIG_FILE=$(mktemp)
  echo "${CONFIG}" | jq '.date='$(date +%s) > "${CONFIG_FILE}"

  TEMP_FILE=$(mktemp)
  echo '{"nodes":' > ${TEMP_FILE}
  DATA_FILE=$(mktemp)
  hzn exchange node list -l > ${DATA_FILE} 2> /dev/stderr
  if [ -s "${DATA_FILE}" ]; then
    echo '[' >> ${TEMP_FILE}
    cat "${DATA_FILE}" >> ${TEMP_FILE}
    echo ']' >> ${TEMP_FILE}
  else
    if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- no data from hzn exchange node list" &> /dev/stderr; fi
    echo 'null' >> ${TEMP_FILE}
  fi
  echo '}' >> ${TEMP_FILE}

  OUT_FILE=$(mktemp)
  jq -s add "${CONFIG_FILE}" "${TEMP_FILE}" > "${OUT_FILE}"
  if [ ! -s "${OUT_FILE}" ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "*** ERROR -- $0 $$ -- jq add failed" &> /dev/stderr; fi
  else
    mv -f "${OUT_FILE}" "${TMPDIR}/${SERVICE_LABEL}.json"
  fi
  # wait for ..
  SECONDS=$((HZNCLI_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi
done
