#!/bin/bash

if [ "${VENDOR}" != "apple" ] && [ "${OSTYPE}" != "darwin" ]; then
  echo "This script is for macOS only" >&2
  exit 1
fi

## ETCHER
ETCHER_DIR="/opt/etcher-cli"
ETCHER_URL="https://github.com/balena-io/etcher/releases/download/v1.4.8/balena-etcher-cli-1.4.8-darwin-x64.tar.gz"
ETCHER_CMD="balena-etcher"

ETCHER=$(command -v "${ETCHER_CMD}")
if [ -z "${ETCHER}" ]; then
  if [ ! -d "${ETCHER_DIR}" ]; then
    echo "+++ WARN $0 $$ -- etcher CLI not installed in ${ETCHER_DIR}; installing from ${ETCHER_URL}" &> /dev/stderr
    mkdir "${ETCHER_DIR}"
    wget -qO - "${ETCHER_URL}" | ( cd "${ETCHER_DIR}" ; tar xzf - ; mv */* . ; rmdir * ) &> /dev/null
  fi
  ETCHER="${ETCHER_DIR}/${ETCHER_CMD}"
fi
if [ -z "${ETCHER}" ] || [ ! -e "${ETCHER}" ]; then
  echo "+++ WARN $0 $$ -- executable ${ETCHER} not found; manually flash SD card; try Etcher at https://www.balena.io/etcher/"
fi

## BOOT VOLUME MOUNT POINT
if [ -z "${VOLUME_BOOT:-}" ]; then
  VOLUME_BOOT="/Volumes/boot"
else
  echo "+++ WARN $0 $$ -- non-standard VOLUME_BOOT: ${VOLUME_BOOT}"
fi
if [ ! -d "${VOLUME_BOOT}" ]; then
  echo "*** ERROR $0 $$ -- did not find directory: ${VOLUME_BOOT}"
  exit 1
fi


## HORIZON CONFIG

CONFIG="horizon.json"
if [ -z "${1}" ]; then
  if [ -s "${CONFIG}" ]; then
    echo "+++ WARN $0 $$ -- no configuration specified; default found: ${CONFIG}"
  else
    echo "*** ERROR $0 $$ -- no configuration specified; no default: ${CONFIG}"
    exit 1
  fi
else
  if [ ! -s "${1}" ]; then
    echo "*** ERROR configuration file empty: ${1}"
    exit 1
  fi
  CONFIG="${1}"
fi

## WIFI

WIFI_SSID=$(jq -r '.networks|first|.ssid' "${CONFIG}")
WIFI_PASSWORD=$(jq -r '.networks|first|.password' "${CONFIG}")
if [ "${WIFI_SSID}" == "null" ] || [ "${WIFI_PASSWORD}" == "null" ]; then
  echo "*** ERROR $0 $$ -- WIFI_SSID or WIFI_PASSWORD undefined; run mkconfig.sh"
  exit 1
elif [ -z "${WIFI_SSID}" ]; then
  echo "*** ERROR $0 $$ -- WIFI_SSID blank; run mkconfig.sh"
  exit 1
elif [ -z "${WIFI_PASSWORD}" ]; then
  echo "+++ WARN $0 $$ -- WIFI_PASSWORD is blank"
fi

## WPA SUPPLICANT
if [ -z ${WPA_SUPPLICANT_FILE:-} ]; then
  WPA_SUPPLICANT_FILE="${VOLUME_BOOT}/wpa_supplicant.conf"
else
  echo "+++ WARN $0 $$ -- non-standard WPA_SUPPLICANT_FILE: ${WPA_SUPPLICANT_FILE}"
fi

## SSH ACCESS
SSH_FILE="${VOLUME_BOOT}/ssh"
touch "${SSH_FILE}"
if [ ! -e "${SSH_FILE}" ]; then
  echo "*** ERROR $0 $$ -- could not create: ${SSH_FILE}"
  exit 1
else
  # write public keyfile
  echo $(jq -r '.key.public' "${CONFIG}" | base64 --decode) > "${VOLUME_BOOT}/ssh.pub"
fi
echo "--- INFO $0 $$ -- created ${SSH_FILE} for SSH access"

## WPA TEMPLATE
if [ -z "${WPA_TEMPLATE_FILE:-}" ]; then
    WPA_TEMPLATE_FILE="wpa_supplicant.tmpl"
else
  echo "+++ WARN $0 $$ -- non-standard WPA_TEMPLATE_FILE: ${WPA_TEMPLATE_FILE}"
fi
if [ ! -s "${WPA_TEMPLATE_FILE}" ]; then
  echo "*** ERROR $0 $$ -- could not find: ${WPA_TEMPLATE_FILE}"
  exit 1
fi

# change template
sed \
  -e 's|%%WIFI_SSID%%|'"${WIFI_SSID}"'|g' \
  -e 's|%%WIFI_PASSWORD%%|'"${WIFI_PASSWORD}"'|g' \
  "${WPA_TEMPLATE_FILE}" > "${WPA_SUPPLICANT_FILE}"
if [ ! -s "${WPA_SUPPLICANT_FILE}" ]; then
  echo "*** ERROR $0 $$ -- could not create: ${WPA_SUPPLICANT_FILE}"
  exit 1
fi

## SUCCESS
echo "--- INFO $0 $$ -- ${WPA_SUPPLICANT_FILE} created using SSID ${WIFI_SSID}; password ${WIFI_PASSWORD}"

if [ -n $(command -v diskutil) ]; then
  echo "--- INFO $0 $$ -- ejecting volume ${VOLUME_BOOT}"
  diskutil eject "${VOLUME_BOOT}"
else
  echo "+++ WARN $0 $$ -- you may now safely eject volume ${VOLUME_BOOT}"
fi
