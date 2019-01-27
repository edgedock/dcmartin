#!/bin/sh

if [ ! -z "${HZN_PATTERN}" ] && [ ! -z $(command -v "${HZN_PATTERN:-}.sh" ) ]; then
  ${HZN_PATTERN}.sh &
else
  echo "*** ERROR $0 $$ -- environment variable HZN_PATTERN: ${HZN_PATTERN}; command:" $(command -v "${HZN_PATTERN}.sh") &> /dev/stderr
fi

socat TCP4-LISTEN:80,fork EXEC:service.sh
