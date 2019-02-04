#!/bin/bash

if [ -z "${SERVICE_LABEL:-}" ]; then SERVICE_LABEL=$(echo "${0##*/}" | sed 's|test-\(.*\).sh|\1|'); fi

REPLY=$(cat -)
if [ ! -z "${REPLY}" ]; then 
  echo "${REPLY}" | jq -c '.'${SERVICE_LABEL}'!=null'
else
  echo "no input" &> /dev/stderr
  exit 1
fi
