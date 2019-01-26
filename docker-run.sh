#!/bin/bash

# name
if [ -n "${1}" ]; then 
  DOCKER_NAME="${1}"
else
  echo "*** ERROR $0 $$ -- DOCKER_NAME unspecified; exiting"
  exit 1
fi

# tag
if [ -n "${2}" ]; then
  DOCKER_TAG="${2}"
else
  echo "*** ERROR $0 $$ -- DOCKER_TAG unspecified; exiting"
  exit 1
fi

## configuration
if [ -z "${SERVICE:-}" ]; then SERVICE="service.json"; fi
if [ ! -s "${SERVICE}" ]; then echo "*** ERROR $0 $$ -- Cannot locate service configuration ${SERVICE}; exiting"; exit 1; fi
LABEL=$(jq -r '.label' "${SERVICE}")

## input
if [ -z "${USERINPUT:-}" ]; then USERINPUT="userinput.json"; fi
if [ ! -s "${USERINPUT}" ]; then echo "+++ WARN $0 $$ -- cannot locate ${USERINPUT}; continuing"; fi

## privileged
if [ $(jq '.deployment.services|to_entries[]|select(.key=="'${LABEL}'").privileged==true' "${SERVICE}") ]; then
  OPTIONS="${OPTION:-}"' --privileged'
fi

# temporary file-system
if [ $(jq '.tmpfs!=null' "${SERVICE}") == 'true' ]; then 
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
else
  echo "+++ WARN $0 $$ -- no tmpfs"
fi

# pre-defined inputs
HZN_PATTERN=$(jq -r '.label' ${SERVICE})
OPTIONS="${OPTIONS:-}"' -e HZN_PATTERN='"${HZN_PATTERN}"
HZN_ORGANIZATION=$(jq -r '.org' ${SERVICE})
OPTIONS="${OPTIONS:-}"' -e HZN_ORGANIZATION='"${HZN_ORGANIZATION}"
HZN_DEVICE_ID=$(hostname)-${DOCKER_NAME}
OPTIONS="${OPTIONS:-}"' -e HZN_DEVICE_ID='"${HZN_DEVICE_ID}"

# inputs
if [ "$(jq '.userInput!=null' ${SERVICE})" == 'true' ]; then
  URL=$(jq -r '.url' ${SERVICE})
  NAMES=$(jq -r '.userInput[].name' ${SERVICE})
  for NAME in ${NAMES}; do
    DV=$(jq -r '.userInput[]|select(.name=="'$NAME'").defaultValue' ${SERVICE})
    if [ -s "${USERINPUT}" ]; then
      VAL=$(jq -r '.services[]|select(.url=="'"${URL}"'").variables|to_entries[]|select(.key=="'"${NAME}"'").value' ${USERINPUT})
      if [ -n "${VAL}" ] && [ "${VAL}" != 'null' ] && [ "${VAL}" != '' ]; then 
        DV="${VAL}";
      elif [ -z "${DV}" ] || [ "${DV}" == 'null' ]; then
        echo "*** ERROR $0 $$ -- value NOT defined for required: ${NAME}; edit ${USERINPUT}; exiting"
        exit 1
      fi
    fi
    OPTIONS="${OPTIONS:-}"' -e '"${NAME}"'="'"${DV}"'"'
  done
else
  echo "+++ WARN $0 $$ -- no inputs"
fi

# ports
if [ $(jq '.ports!=null' ${SERVICE}) == 'true' ]; then
  PORTS=$(jq -r '.ports?|to_entries[]|.key?' "${SERVICE}" | sed 's|/tcp||')
  for PS in ${PORTS}; do
    PE=$(jq -r '.ports|to_entries[]|select(.key=="'${PS}'/tcp")|.value' "${SERVICE}")
    OPTIONS="${OPTIONS:-}"' --publish='"${PS}"':'"${PE}"
  done
else
  echo "+++ WARN $0 $$ -- no ports"
fi

echo "RUN: ${DOCKER_NAME} ${OPTIONS} ${DOCKER_TAG}"
docker run -d --name "${DOCKER_NAME}" ${OPTIONS} "${DOCKER_TAG}"
