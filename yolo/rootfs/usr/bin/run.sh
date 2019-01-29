#!/bin/sh

if [ ! -z "${SERVICE_LABEL}" ] && [ ! -z $(command -v "${SERVICE_LABEL:-}.sh" ) ]; then
  ${SERVICE_LABEL}.sh &
else
  echo "*** ERROR $0 $$ -- environment variable SERVICE_LABEL: ${SERVICE_LABEL}; command:" $(command -v "${SERVICE_LABEL}.sh") &> /dev/stderr
fi

if [ -z "${LOCALHOST_PORT:-}" ]; then 
  LOCALHOST_PORT=80
else
  echo "+++ WARN: using localhost port ${LOCALHOST_PORT}" &> /dev/stderr
fi

socat TCP4-LISTEN:${LOCALHOST_PORT},fork EXEC:service.sh
