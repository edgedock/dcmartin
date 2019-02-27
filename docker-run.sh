#!/bin/bash

# name
if [ -n "${1}" ]; then 
  DOCKER_NAME="${1}"
else
  echo "*** ERROR -- -- $0 $$ -- DOCKER_NAME unspecified; exiting"
  exit 1
fi

# tag
if [ -n "${2}" ]; then
  DOCKER_TAG="${2}"
else
  echo "*** ERROR -- $0 $$ -- DOCKER_TAG unspecified; exiting"
  exit 1
fi

## configuration
if [ -z "${SERVICE:-}" ]; then SERVICE="service.json"; fi
if [ ! -s "${SERVICE}" ]; then echo "*** ERROR -- $0 $$ -- Cannot locate service configuration ${SERVICE}; exiting"; exit 1; fi
SERVICE_LABEL=$(jq -r '.label' "${SERVICE}")

## privileged
if [ "$(jq '.deployment.services|to_entries[]|select(.key=="'${SERVICE_LABEL}'").value.privileged?==true' "${SERVICE}")" == 'true' ]; then
  OPTIONS="${OPTIONS:-}"' --privileged'
fi

## environment
EVARS=$(jq '.deployment.services|to_entries[]|select(.key=="'${SERVICE_LABEL}'").value.environment?' "${SERVICE}")
if [ "${EVARS}" != 'null' ]; then
  OPTIONS="${OPTIONS:-} $(echo "${EVARS}" | jq -r '.[]' | while read -r; do T="-e ${REPLY}"; echo "${T}"; done)"
fi

## input
if [ -z "${USERINPUT:-}" ]; then USERINPUT="userinput.json"; fi
if [ ! -s "${USERINPUT}" ]; then echo "+++ WARN -- $0 $$ -- cannot locate ${USERINPUT}; continuing"; fi

# temporary file-system
if [ $(jq '.tmpfs!=null' "${SERVICE}") == 'true' ]; then 
  # size
  TS=$(jq -r '.tmpfs.size' ${SERVICE})
  if [ -z "${TS}" ] || [ "${TS}" == 'null' ]; then 
    echo "--- INFO -- $0 $$ -- temporary filesystem; no size specified; defaulting to 8 Mbytes"
    TS=4096000
  fi
  # destination
  TD=$(jq -r '.tmpfs.destination' ${SERVICE})
  if [ -z "${TD}" ] || [ "${TD}" == 'null' ]; then 
    echo "--- INFO -- $0 $$ -- temporary filesystem; no destination specified; defaulting to /tmpfs"
    TD="/tmpfs"
  fi
  # mode
  TM=$(jq -r '.tmpfs.mode' ${SERVICE})
  if [ -z "${TM}" ] || [ "${TM}" == 'null' ]; then 
    echo "--- INFO -- $0 $$ -- temporary filesystem; no mode specified; defaulting to 1777"
    TM="1777"
  fi
  OPTIONS="${OPTIONS:-}"' --mount type=tmpfs,destination='"${TD}"',tmpfs-size='"${TS}"',tmpfs-mode='"${TM}"
else
  echo "--- INFO -- $0 $$ -- no tmpfs"
fi

# inputs
if [ "$(jq '.userInput!=null' ${SERVICE})" == 'true' ]; then
  URL=$(jq -r '.url' ${SERVICE})
  NAMES=$(jq -r '.userInput[].name' ${SERVICE})
  for NAME in ${NAMES}; do
    DV=$(jq -r '.userInput[]|select(.name=="'$NAME'").defaultValue' ${SERVICE})
    if [ -s "${USERINPUT}" ]; then
      VAL=$(jq -r '.services[]|select(.url=="'${URL}'").variables|to_entries[]|select(.key=="'${NAME}'").value' ${USERINPUT})
    fi
    if [ -s "${NAME}" ]; then
       VAL=$(sed 's/^"\(.*\)"$/\1/' "${NAME}")
    fi
    if [ -n "${VAL}" ] && [ "${VAL}" != 'null' ]; then 
      DV=${VAL};
    elif [ "${DV}" == 'null' ]; then
      echo "*** ERROR -- $0 $$ -- value NOT defined for required: ${NAME}; create file ${NAME} with JSON value; exiting"
      exit 1
    fi
    OPTIONS="${OPTIONS:-}"' -e '"${NAME}"'='"${DV}"
  done
else
  echo "+++ WARN -- $0 $$ -- no inputs"
fi

# ports
if [ $(jq '.ports!=null' ${SERVICE}) == 'true' ]; then
  PORTS=$(jq -r '.ports?|to_entries[]|.key?' "${SERVICE}" | sed 's|/tcp||')
  for PS in ${PORTS}; do
    PE=$(jq -r '.ports|to_entries[]|select(.key=="'${PS}'/tcp")|.value' "${SERVICE}")
    if [ -z "${PE}" ]; then PE=$(jq -r '.ports|to_entries[]|select(.key=="'${PS}'")|.value' "${SERVICE}"); fi
    OPTIONS="${OPTIONS:-}"' --publish='"${PE}"':'"${PS}"
  done
else
  echo "+++ WARN -- $0 $$ -- no ports"
fi

echo "--- INFO -- $0 $$ -- docker run -d --name ${DOCKER_NAME} ${OPTIONS} ${DOCKER_TAG}"
docker run -d --name "${DOCKER_NAME}" ${OPTIONS} "${DOCKER_TAG}"
