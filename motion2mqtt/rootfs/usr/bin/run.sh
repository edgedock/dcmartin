#!/bin/sh

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

hzn_pattern() {
  PATTERN='null'
  if [ ! -z "${1}" ] && [ ! -z "${HZN_ORGANIZATION:-}" ] && [ ! -z "${HZN_EXCHANGE_APIKEY:-}" ] && [ ! -z "${HZN_EXCHANGE_URL:-}" ]; then
    ALL=$(curl -sL -u "${HZN_ORGANIZATION}/iamapikey:${HZN_EXCHANGE_APIKEY}" "${HZN_EXCHANGE_URL}/orgs/${HZN_ORGANIZATION}/patterns")
    if [ ! -z "${ALL}" ]; then
      PATTERN=$(echo "${ALL}" | jq '.patterns|to_entries[]|select(.key=="'${1}'")')
    fi
  fi
  echo "${PATTERN}"
}


# hzn config
export HZN='{"hzn":{"agreementid":"'${HZN_AGREEMENTID:-}'","arch":"'${HZN_ARCH:-}'","cpus":'${HZN_CPUS:-0}',"device_id":"'${HZN_DEVICE_ID:-}'","exchange_url":"'${HZN_EXCHANGE_URL:-}'","host_ips":['$(echo "${HZN_HOST_IPS:-}" | sed 's/,/","/g' | sed 's/\(.*\)/"\1"/')'],"organization":"'${HZN_ORGANIZATION:-}'","pattern":"'${HZN_PATTERN:-}'","ram":'${HZN_RAM:-0}'},"date":'$(date +%s)',"service":"'${SERVICE_LABEL:-}'","pattern":'$(hzn_pattern "${HZN_PATTERN:-}")'}'

# make a file
echo "${HZN}" > "${TMP}/config.json"

# label
if [ ! -z "${SERVICE_LABEL:-}" ] && [ ! -z $(command -v "${SERVICE_LABEL:-}.sh" ) ]; then
  ${SERVICE_LABEL}.sh &
else
  echo "+++ WARN $0 $$ -- executable not found for ${SERVICE_LABEL}: ${SERVICE_LABEL:-}.sh" &> /dev/stderr
fi

# port
if [ -z "${LOCALHOST_PORT:-}" ]; then 
  LOCALHOST_PORT=80
else
  echo "+++ WARN: using localhost port ${LOCALHOST_PORT}" &> /dev/stderr
fi

# start listening
socat TCP4-LISTEN:${LOCALHOST_PORT},fork EXEC:service.sh
