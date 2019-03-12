#!/bin/bash

source /usr/bin/motion-start.sh

if [ -z "${MOTION_PERIOD:-}" ]; then MOTION_PERIOD=30; echo "+++ WARN -- $0 $$ -- MOTION_PERIOD unspecified; using: ${MOTION_PERIOD}" &> /dev/stderr; fi

CMD=${1}
PID=${2}

if [ -z "${CMD}" ]; then echo "*** ERROR -- $0 $$ -- no motion command path specified" &> /dev/stderr; exit 1; fi

while true; do
  pid=$(ps | awk '{ print $1,$4 }' | egrep "${CMD}" | awk '{ print $1 }')
  if [ -z "${pid}" ] || [ "${PID}" != "${pid}" ]; then
    if [ ! -z "${PID}" ]; then kill -9 ${PID}; fi
    PID=$(motion_start)
  fi
  sleep ${MOTION_PERIOD}
done
