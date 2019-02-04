#!/bin/bash

if [ -z "${1}" ]; then HOST="127.0.0.1"; else HOST="${1}"; fi
PORT=$(jq -r '.ports?|to_entries|first|.key?' service.json | sed 's|/tcp||')
if [ -z "${PORT}" ]; then PORT=80; echo "+++ WARN $0 $$ -- no port specified; using ${PORT}" &> /dev/stderr; fi

NOW=$(date +%s)
PERIOD=30
OUT=

while true; do
  OUT=$(curl -sSL "http://${HOST}:${PORT}")
  echo "${OUT}" | ../test-service.sh
  echo "Sleeping ${PERIOD}..."; sleep ${PERIOD}
done

