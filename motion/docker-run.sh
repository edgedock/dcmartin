#!/bin/bash

if [ -z "${ARCH:-}" ]; then ARCH=$(uname -m | sed -e 's/aarch64.*/arm64/' -e 's/x86_64.*/amd64/' -e 's/armv.*/arm/'); fi

## configuration
if [ -z "${CONFIG:-}" ]; then CONFIG="config.json"; fi
if [ ! -s "${CONFIG}" ]; then echo "Cannot locate ${CONFIG}; exiting"; exit 1; fi
# name
SERVICE_NAME=$(jq -r '.slug' config.json)
if [ -z "${SERVICE_NAME}" ]; then echo "*** ERROR: cannot find SERVICE_NAME in ${CONFIG}; exiting"; exit 1; fi
SERVICE_VERSION=$(jq -r '.version' config.json)
if [ -z "${SERVICE_VERSION}" ]; then echo "*** ERROR: cannot find SERVICE_VERSION in ${CONFIG}; exiting"; exit 1; fi

## docker
if [ -z "${DOCKER_HUB_ID}" ]; then DOCKER_HUB_ID=$(whoami); echo "+++ WARN: DOCKER_HUB_ID unspecified; using default: ${DOCKER_HUB_ID}"; fi
# name
if [ -n "${1}" ]; then 
  DOCKER_NAME="${1}"
elif [ -z "${DOCKER_NAME}" ]; then 
  DOCKER_NAME=${ARCH}_${SERVICE_NAME}
  echo "+++ WARN: DOCKER_NAME unspecified; using default: ${DOCKER_NAME}"
fi
# tag
if [ -n "${2}" ]; then
  DOCKER_TAG="${2}"
else
  DOCKER_TAG=${DOCKER_HUB_ID}/${DOCKER_NAME}:${SERVICE_VERSION}
  echo "+++ WARN: DOCKER_TAG unspecified; using default: ${DOCKER_TAG}"
fi

PORTS_SOURCE=$(jq -r '.ports|to_entries[]|.key' "${CONFIG}" | sed 's|/tcp||')
for PS in ${PORTS_SOURCE}; do
  PE=$(jq -r '.ports|to_entries[]|select(.key=="'${PS}'/tcp")|.value' "${CONFIG}")
  OPTIONS="${OPTIONS:-}"' --publish='"${PS}"':'"${PE}"
done

if [ -z "${VOLUME:-}" ]; then VOLUME="$(pwd)/data"; fi
if [ ! -d "${VOLUME}" ]; then mkdir -p "${VOLUME}"; fi
jq '.options' ${CONFIG} > ${VOLUME}/options.json

docker run -d --name ${DOCKER_NAME} ${OPTIONS} --volume "${VOLUME}"':/data' "${DOCKER_TAG}"
