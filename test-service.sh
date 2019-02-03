#!/bin/bash

if [ -z "${SERVICE_LABEL:-}" ]; then SERVICE_LABEL=$(echo "${0##*/}" | sed 's|test-\(.*\).sh|\1|'); fi

REPLY=$(cat -)

echo "${REPLY}" | jq -c '.'${SERVICE_LABEL}'!=null'
