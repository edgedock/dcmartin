#!/bin/bash

if [ -z ${WIFI_SSID:-} ] || [ -z ${WIFI_PASSWORD} ]; then
  WIFI_SSID="TEST"
  WIFI_PASSWORD="0123456789"
  echo "[WARN] $0 $$ -- no WIFI_SSID or WIFI_PASSWORD defined; using default (${WIFI_SSID}:${WIFI_PASSWORD})"
fi

## BOOT VOLUME MOUNT POINT
if [ -z ${VOLUME_BOOT:-} ]; then
  VOLUME_BOOT="/Volumes/boot"
else
  echo "[WARN] $0 $$ -- non-standard VOLUME_BOOT: ${VOLUME_BOOT}"
fi
if [ ! -d "${VOLUME_BOOT}" ]; then
  echo "[ERROR] $0 $$ -- did not find directory: ${VOLUME_BOOT}"
  exit 1
fi

## WPA SUPPLICANT
if [ -z ${WPA_SUPPLICANT_FILE:-} ]; then
  WPA_SUPPLICANT_FILE="${VOLUME_BOOT}/wpa_supplicant.conf"
else
  echo "[WARN] $0 $$ -- non-standard WPA_SUPPLICANT_FILE: ${WPA_SUPPLICANT_FILE}"
fi

## SSH ACCESS
SSH_FILE="${VOLUME_BOOT}/ssh"
touch "${SSH_FILE}"
if [ ! -e "${SSH_FILE}" ]; then
  echo "[ERROR] $0 $$ -- could not create: ${SSH_FILE}"
  exit 1
fi
echo "[INFO] $0 $$ -- created ${SSH_FILE} for SSH access"

## WPA TEMPLATE
if [ -z "${WPA_TEMPLATE_FILE:-}" ]; then
    WPA_TEMPLATE_FILE="wpa_supplicant.tmpl"
else
  echo "[WARN] $0 $$ -- non-standard WPA_TEMPLATE_FILE: ${WPA_TEMPLATE_FILE}"
fi
if [ ! -s "${WPA_TEMPLATE_FILE}" ]; then
  echo "[ERROR] $0 $$ -- could not find: ${WPA_TEMPLATE_FILE}"
  exit 1
fi

# change template
sed \
  -e 's|%%WIFI_SSID%%|'"${WIFI_SSID}"'|g' \
  -e 's|%%WIFI_PASSWORD%%|'"${WIFI_PASSWORD}"'|g' \
  "${WPA_TEMPLATE_FILE}" > "${WPA_SUPPLICANT_FILE}"
if [ ! -s "${WPA_SUPPLICANT_FILE}" ]; then
  echo "[ERROR] $0 $$ -- could not create: ${WPA_SUPPLICANT_FILE}"
  exit 1
fi

## SUCCESS
echo "[INFO] $0 $$ -- ${WPA_SUPPLICANT_FILE} created using SSID ${WIFI_SSID}; password ${WIFI_PASSWORD}"

if [ -n $(command -v diskutil) ]; then
  echo "[INFO] $0 $$ -- ejecting volume ${VOLUME_BOOT}"
  diskutil eject "${VOLUME_BOOT}"
else
  echo "[WARN] $0 $$ -- you may now safely eject volume ${VOLUME_BOOT}"
fi
