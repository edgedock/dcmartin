#!/bin/bash

source /usr/bin/motion-start.sh

if [ -z "${MOTION_PERIOD:-}" ]; then MOTION_PERIOD=30; echo "+++ WARN -- $0 $$ -- MOTION_PERIOD unspecified; using: ${MOTION_PERIOD}" &> /dev/stderr; fi

if [ -z "${MOTION_CONTROL_PORT}" ]; then MOTION_CONTROL_PORT=8080; echo "+++ WARN -- $0 $$ -- MOTION_CONTROL_PORT unspecified; using: ${MOTION_CONTROL_PORT}" &> /dev/stderr; fi

CMD=${1}
PID=${2}

if [ -z "${CMD}" ]; then echo "*** ERROR -- $0 $$ -- no motion command path specified" &> /dev/stderr; exit 1; fi

while true; do
  pid=$(ps | awk '{ print $1,$4 }' | egrep "${CMD}" | awk '{ print $1 }')
  if [ -z "${pid}" ] || [ "${PID}" != "${pid}" ]; then
    rm -f ${MOTION_PID_FILE}
    if [ ! -z "${PID}" ]; then 
      if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- sending KILL signal to PID: ${PID}" &> /dev/stderr; fi
      kill -9 ${PID}
    fi
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- requesting motion start" &> /dev/stderr; fi
    PID=$(motion_start)
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- motion start result: ${PID}" &> /dev/stderr; fi
  else
    if [ $(curl -fsSL -m 1 "http://localhost:${MOTION_CONTROL_PORT}" &> /dev/null && true || false) ]; then
      if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- sending HUP signal to PID: ${PID}" &> /dev/stderr; fi
      kill -HUP ${PID}
    fi
  fi
  sleep ${MOTION_PERIOD}
done
