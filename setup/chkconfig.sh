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

if [ $(jq -r '.default.token==null' "${CONFIG}") == 'true' ]; then
  echo "+++ ERROR $0 $$ -- no default token; run mkconfig.sh" &> /dev/stderr
  echo 'false'
  exit 1
fi

if [ $(jq -r '.default.keys==null' "${CONFIG}") == 'true' ]; then
  echo "+++ ERROR $0 $$ -- no default keys; run mkconfig.sh" &> /dev/stderr
  echo 'false'
  exit 1
fi

MID=$(jq -r '.default.machine' "${CONFIG}")
if [ "${MID}" != 'null' ]; then
  if [ $(jq -r '.machines[]|select(.id=="'$MID'")!=null' "${CONFIG}") == 'true' ]; then
    echo "--- INFO: default machine:" $(jq -r '.machines[]|select(.id=="'$MID'")|.type' "${CONFIG}") &> /dev/stderr
  else
    echo "+++ ERROR $0 $$ -- invalid default machine ${MID}" &> /dev/stderr
    echo 'false'
    exit 1
  fi
else
  echo "+++ WARN: no default machine" &> /dev/stderr
fi

if [ $(jq -r '.discover==true' "${CONFIG}") == 'true' ]; then
  VID=$(jq -r '.vendor' "${CONFIG}")
  if [ $(jq -r '.vendors[]|select(.id=="'$VID'")!=null' "${CONFIG}") == 'true' ]; then
    echo "--- INFO: discover default vendor:" $(jq -r '.vendors[]|select(.id=="'$VID'")|.tag' "${CONFIG}") &> /dev/stderr
  else
    echo "+++ ERROR $0 $$ -- invalid discover vendor ${VID}" &> /dev/stderr
    echo 'false'
    exit 1
  fi
else
  echo "+++ WARN: discover default vendor: FALSE" &> /dev/stderr
fi

echo "--- INFO: configurations:" $(jq '.configurations[]?.id' "${CONFIG}") &> /dev/stderr
for config in $(jq -r '.configurations[]?.id' "${CONFIG}"); do
  echo "--- INFO: ${config}:" $(jq '.configurations[]|select(.id=="'"${config}"'")|.pattern,.exchange,.network,.nodes[].id' "${CONFIG}") &> /dev/stderr
done

echo "--- INFO: exchanges:" $(jq '.exchanges[]?|.id,.url' "${CONFIG}") &> /dev/stderr

echo "--- INFO: setup network:" $(jq '.networks?|first|.id,.ssid,.password' "${CONFIG}") &> /dev/stderr

echo "--- INFO: nodes:" $(jq '.nodes[]?|{"id":.id,"ssh":.ssh.id,"status":{"id":.node.id,"pattern":.node.pattern,"state":.node.configstate.state}}' "${CONFIG}") &> /dev/stderr


jq '.setup != null and .configurations != null and .exchanges != null and .networks != null and .default.token != null' "${CONFIG}"
