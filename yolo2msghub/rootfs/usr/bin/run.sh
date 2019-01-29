#!/bin/sh

if [ ! -z "${HZN_PATTERN}" ] && [ ! -z $(command -v "${HZN_PATTERN:-}.sh" ) ]; then
  ${HZN_PATTERN}.sh &
else
  echo "*** ERROR $0 $$ -- environment variable HZN_PATTERN: ${HZN_PATTERN}; command:" $(command -v "${HZN_PATTERN}.sh") &> /dev/stderr
fi

if [ -z "${LOCALHOST_PORT:-}" ]; then 
  LOCALHOST_PORT=80
else
  echo "+++ WARN: using localhost port ${LOCALHOST_PORT}" &> /dev/stderr
fi

socat TCP4-LISTEN:${LOCALHOST_PORT},fork EXEC:service.sh
