#!/bin/bash

# where
if [ -z "${1}" ]; then DIR="horizon"; else DIR="${1}"; fi
if [ ! -d "${DIR}" ]; then
  echo "*** ERROR $0 $$ -- no directory ${DIR}" &> /dev/stderr
  exit 1
fi

# what
PATTERN="pattern.json"
if [ -s "${PATTERN}" ]; then
  # tagging
  if [ ! -z "${TAG:-}" ]; then
    PATTERN_LABEL=$(jq -r '.label' "${PATTERN}")
    echo "+++ WARN $0 $$ -- modifying service label to ${PATTERN_LABEL} URL with ${TAG} in ${PATTERN}" &> /dev/stderr
    jq -c '.label="'${PATTERN_LABEL}-${TAG}'"|.services=[.services[]|.serviceUrl as $url|.serviceUrl=$url+"-'${TAG}'"]' "${PATTERN}" > "${DIR}/${PATTERN}"
  else
    echo "--- INFO $0 $$ -- no TAG; doing nothing" &> /dev/stderr
  fi
else
  echo "+++ WARN $0 $$ -- cannot find file: ${PATTERN}" &> /dev/stderr
  exit 1
fi
