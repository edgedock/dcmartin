#!/bin/bash

DEFAULT=/etc/default/horizon

# get exchange
if [ ! -z "${1}" ]; then
  case ${1} in
    st*)
	EX="stg"
	;;
    al*)
	EX="alpha"
	;;
    *)
	echo "Error: neither alpha nor staging specified" &> /dev/stderr
	exit 1
	;;
  esac
else
  echo "Usage: $0 alpha or staging" &> /dev/stderr
  exit 1
fi

# make URL
URL="https://${EX}.edge-fabric.com/v1/"

# set timeout
if [ -z "${TIMEOUT}" ]; then TIMEOUT=2; fi

# test alive
OUT=$(curl -m ${TIMEOUT} -sSL ${URL}) && STATUS=$?
if [ ! -z "${OUT}" ] || [ $STATUS != 0 ]; then
  echo "Error: ${URL} not accessible in ${TIMEOUT} seconds; ${STATUS}; ${OUT}" &> /dev/stderr
  exit 1
fi

## CHECK

OLD= $(grep "HZN_EXCHANGE_URL" "${DEFAULT}" | sed 's|HZN_EXCHANGE_URL=\(.*\)|\1|')
if [ "${OLD}" == "${URL}" ]; then
  echo -n "+++ WARN: exchange current; confirm switch to ${URL}? [y/n] (N): "
  if [ "${VALUE}" != 'Y' ] && [ "${VALUE}" != 'y' ]; then 
    echo "cancelling"
    exit 0
  fi
fi

## ASK

echo -n "Confirm exchange switch to ${URL}? [y/n] (N): "
read VALUE
if [ "${VALUE}" != 'Y' ] && [ "${VALUE}" != 'y' ]; then 
  echo "quitting"
  exit 0
fi

## SWITCH

# unregister
hzn unregister -f -r

# clean
sudo apt remove -y bluehorizon horizon horizon-cli
sudo apt purge -y bluehorizon horizon horizon-cli

# install
sudo apt update -y
sudo apt install -y bluehorizon horizon horizon-cli

# update URL
echo "HZN_EXCHANGE_URL=${URL}" > /tmp/$$
sudo mv /tmp/$$ "${DEFAULT}"

# restart horizon
sudo service horizon restart
