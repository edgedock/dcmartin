#!/bin/bash
DOCKER_NAME="${1}"
DOCKER_TAG="${2}"
CONFIG="config.json"
PORTS_SOURCE=$(jq -r '.ports|to_entries[]|.key' "${CONFIG}" | sed 's|/tcp||')
for PS in ${PORTS_SOURCE}; do
  PE=$(jq -r '.ports|to_entries[]|select(.key=="'${PS}'/tcp")|.value' "${CONFIG}")
  OPTIONS="${OPTIONS:-}"' --publish='"${PS}"':'"${PE}"
done
echo $OPTIONS
VOLUME=$(pwd)
#
docker run -d --name ${DOCKER_NAME} ${OPTIONS} --volume "${VOLUME}"':/outside' "${DOCKER_TAG}"

