#!/bin/bash

CONFIG="horizon.json"

if [ -z "${1}" ]; then
  if [ -s "${CONFIG}" ]; then
    echo "+++ WARN $0 $$ -- no configuration specified; default found: ${CONFIG}" &> /dev/stderr
  else
    echo "*** ERROR $0 $$ -- no configuration specified; no default: ${CONFIG}" &> /dev/stderr
    exit 1
  fi
else
  if [ ! -s "${1}" ]; then
    echo "*** ERROR $0 $$ -- configuration file empty: ${1}" &> /dev/stderr
    exit 1
  fi
  CONFIG="${1}"
fi


VID=$(jq -r '.vendor' "${CONFIG}")
if [ "${VID}" != 'null' ]; then
  echo "--- INFO: discovery on:" $(jq -r '.vendors[]|select(.id=="'$VID'")|.tag' "${CONFIG}")
fi

echo "--- INFO: configurations:" $(jq '.configurations[]?.id' "${CONFIG}") &> /dev/stderr
for config in $(jq -r '.configurations[]?.id' "${CONFIG}"); do
  echo "--- INFO: ${config}:" $(jq '.configurations[]|select(.id=="'"${config}"'")|.pattern,.exchange,.network,.nodes[].id' "${CONFIG}")
done

echo "--- INFO: exchanges:" $(jq '.exchanges[]?|.id,.url' "${CONFIG}") &> /dev/stderr

echo "--- INFO: setup network:" $(jq '.networks?|first|.id,.ssid,.password' "${CONFIG}") &> /dev/stderr

echo "--- INFO: nodes:" $(jq '.nodes[]?|{"id":.id,"ssh":.ssh.id,"state":{"id":.node.id,"pattern":.node.pattern,"state":.node.configstate.state}}' "${CONFIG}") &> /dev/stderr


jq '.setup != null and .configurations != null and .exchanges != null and .networks != null' "${CONFIG}"
