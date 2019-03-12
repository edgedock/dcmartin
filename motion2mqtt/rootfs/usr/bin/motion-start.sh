#!/usr/bin/env bash

###
### MOTION tools
### 

MOTION_PID_FILE="/var/run/motion/motion.pid" 
MOTION_CMD=$(command -v motion)

motion_pid()
{
  PID=
  if [ -s "${MOTION_PID_FILE}" ]; then
    PID=$(cat ${MOTION_PID_FILE})
  fi
  if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- motion PID: ${PID}" &> /dev/stderr; fi
  echo ${PID}
}

motion_start()
{
  if [ -z "$(motion_pid)" ]; then
    if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- starting ${MOTION_CMD} with ${MOTION_PID_FILE}" &> /dev/stderr; fi
    ${MOTION_CMD} -b -d ${MOTION_LOG_LEVEL:-6} -k ${MOTION_LOG_TYPE:-9} -c "${MOTION_CONF_FILE}" -p "${MOTION_PID_FILE}" -l ${TMPDIR}/motion.log
    while [ -z "$(motion_pid)" ]; do
      if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- waiting on motion" &> /dev/stderr; fi
      sleep 1
    done
    # start watchdog
    motion_watchdog &
  fi
  echo $(motion_pid)
}

motion_watchdog()
{
  WATCHDOG_CMD=$(command -v motion-watchdog.sh)
  if [ -z "${WATCHDOG_CMD}" ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- no motion-watchdog.sh command found" &> /dev/stderr; fi
  else
    pid=$(ps | awk '{ print $1,$4 }' | egrep "${WATCHDOG_CMD}" | awk '{ print $1 }')
    if [ -z "${pid}" ]; then
      ${WATCHDOG_CMD} ${MOTION_CMD} $(motion_pid)
    else
      if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- ${WATCHDOG_CMD} running; PID: ${pid}" &> /dev/stderr; fi
    fi
  fi
}
