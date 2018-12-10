#!/bin/bash

CONFIG="horizon.json"

if [ -z "${1}" ]; then
  if [ -s "${CONFIG}" ]; then
    echo "[WARN] $0 $$ -- no configuration specified; default found: ${CONFIG}" &> /dev/stderr
  else
    echo "[ERROR] $0 $$ -- no configuration specified; no default: ${CONFIG}" &> /dev/stderr
    exit 1
  fi
else
  if [ ! -s "${1}" ]; then
    echo "[ERROR] configuration file empty: ${1}" &> /dev/stderr
    exit 1
  fi
  CONFIG="${1}"
fi


NODES=$(jq -r '.nodes[]?.id' "${CONFIG}")
echo "[Info] nodes:" $(jq -r '.nodes[]?|.id,.ssh?.id' "${CONFIG}") &> /dev/stderr

VID=$(jq -r '.vendor' "${CONFIG}")
if [ "${VID}" != 'null' ]; then
  echo "[Info] discovery on:" $(jq -r '.vendors[]|select(.id=="'$VID'")|.tag' "${CONFIG}")
fi
echo "[Info] configurations:" $(jq '.configurations[]?.id' "${CONFIG}") &> /dev/stderr
for config in $(jq -r '.configurations[]?.id' "${CONFIG}"); do
  echo "[Info] ${config}:" $(jq '.configurations[]|select(.id=="'"${config}"'")|.pattern,.exchange,.network,.nodes[].id' "${CONFIG}")
done
echo "[Info] exchanges:" $(jq '.exchanges[]?|.id,.url' "${CONFIG}") &> /dev/stderr
echo "[Info] setup network:" $(jq '.networks[0]?|.id,.ssid,.password' "${CONFIG}") &> /dev/stderr

jq \
  '.setup != null and .configurations != null and .exchanges != null and ([.configurations[].variables[]?.value|contains("%%")]|unique[]) == false' \
  "${CONFIG}"
