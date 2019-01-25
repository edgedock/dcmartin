#!/bin/bash

# name
if [ -n "${1}" ]; then 
  DOCKER_NAME="${1}"
else
  echo "*** ERROR $0 $$ -- DOCKER_NAME unspecified; exiting"
fi

# tag
if [ -n "${2}" ]; then
  DOCKER_TAG="${2}"
else
  echo "*** ERROR $0 $$ -- DOCKER_TAG unspecified; exiting"
fi

## configuration
if [ -z "${SERVICE:-}" ]; then SERVICE="service.json"; fi
if [ ! -s "${SERVICE}" ]; then echo "Cannot locate ${SERVICE}; exiting"; exit 1; fi

# name
NAME=$(jq -r '.label' "${SERVICE}")
if [ -z "${NAME}" ]; then echo "*** ERROR: cannot find label in ${SERVICE}; exiting"; exit 1; fi
# version
VERSION=$(jq -r '.version' "${SERVICE}")
if [ -z "${VERSION}" ]; then echo "*** ERROR: cannot find version in ${SERVICE}; exiting"; exit 1; fi

# temporary file-system
TMPFS=$(jq '.tmpfs?' "${SERVICE}")
if [ -n "${TMPFS}" ] && [ "${TMPFS}" != 'null' ]; then 
  # size
  TS=$(jq -r '.tmpfs.size' ${SERVICE})
  if [ -z "${TS}" ] || [ "${TS}" == 'null' ]; then 
    echo "+++ WARN $0 $$ -- temporary filesystem; no size specified; defaulting to 8 Mbytes"
    TS=8
  fi
  # destination
  TD=$(jq -r '.tmpfs.destination' ${SERVICE})
  if [ -z "${TD}" ] || [ "${TD}" == 'null' ]; then 
    echo "+++ WARN $0 $$ -- temporary filesystem; no destination specified; defaulting to /tmpfs"
    TD="/tmpfs"
  fi
  # mode
  TM=$(jq -r '.tmpfs.mode' ${SERVICE})
  if [ -z "${TM}" ] || [ "${TM}" == 'null' ]; then 
    echo "+++ WARN $0 $$ -- temporary filesystem; no mode specified; defaulting to 1777"
    TM="1777"
  fi
  OPTIONS="${OPTIONS:-}"' --mount type=tmpfs,destination='"${TD}"',tmpfs-size='"${TS}"',tmpfs-mode='"${TM}"
fi

# ports
PORTS=$(jq -r '.ports|to_entries[]|.key' "${SERVICE}" | sed 's|/tcp||')
for PS in ${PORTS}; do
  PE=$(jq -r '.ports|to_entries[]|select(.key=="'${PS}'/tcp")|.value' "${SERVICE}")
  OPTIONS="${OPTIONS:-}"' --publish='"${PS}"':'"${PE}"
done

docker run -d --name "${DOCKER_NAME}" ${OPTIONS} "${DOCKER_TAG}"
