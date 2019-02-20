#!/bin/bash

# where
if [ -z "${1}" ]; then DIR="horizon"; else DIR="${1}"; fi
if [ ! -d "${DIR}" ]; then
  echo "*** ERROR $0 $$ -- no directory ${DIR}" &> /dev/stderr
  exit 1
fi

# what
SERVICE="service.json"
SERVICE_VERSION=$(jq -r '.version' "${SERVICE}")

PATTERN="pattern.json"
PATTERN_LABEL=$(jq -r '.label' "${PATTERN}")
if [ -s "${PATTERN}" ]; then
  jq -c '.services=[.services[]|.serviceVersions[].version="'${SERVICE_VERSION}'"]' "${PATTERN}" > "${PATTERN}.$$"
  # tagging
  if [ ! -z "${TAG:-}" ]; then
    jq -c '.label="'${PATTERN_LABEL}-${TAG}'"|.services=[.services[]|.serviceUrl as $url|.serviceUrl=$url+"-'${TAG}'"]' "${PATTERN}.$$" > "${PATTERN}.$$.$$"
    mv -f "${PATTERN}.$$.$$" "${PATTERN}.$$"
  fi
  mv -f "${PATTERN}.$$" "${DIR}/${PATTERN}"
else
  echo "+++ WARN $0 $$ -- cannot find pattern JSON template: ${PATTERN}" &> /dev/stderr
  exit 1
fi
