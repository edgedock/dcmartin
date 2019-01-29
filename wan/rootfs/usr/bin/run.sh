#!/bin/sh

if [ ! -z "${SERVICE}" ] && [ ! -z $(command -v "${SERVICE:-}.sh" ) ]; then
  ${SERVICE}.sh &
else
  echo "*** ERROR $0 $$ -- environment variable SERVICE: ${SERVICE}; command:" $(command -v "${SERVICE}.sh") &> /dev/stderr
fi

if [ -z "${LOCALHOST_PORT:-}" ]; then 
  LOCALHOST_PORT=80
else
  echo "+++ WARN: using localhost port ${LOCALHOST_PORT}" &> /dev/stderr
fi

socat TCP4-LISTEN:${LOCALHOST_PORT},fork EXEC:service.sh
