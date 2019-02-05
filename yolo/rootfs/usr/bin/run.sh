#!/bin/sh

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

# hzn config
export HZN='{"hzn":{"agreementid":"'${HZN_AGREEMENTID}'","arch":"'${HZN_ARCH}'","cpus":'${HZN_CPUS:-0}',"device_id":"'${HZN_DEVICE_ID}'","exchange_url":"'${HZN_EXCHANGE_URL}'","host_ips":['$(echo "${HZN_HOST_IPS}" | sed 's/,/","/g' | sed 's/\(.*\)/"\1"/')'],"organization":"'${HZN_ORGANIZATION}'","pattern":"'${HZN_PATTERN}'","ram":'${HZN_RAM:-0}'},"date":'$(date +%s)',"service":"'${SERVICE_LABEL:-}'"}'

# add hostname
IPADDR=$(hostname -i | awk '{ print $1 }' | awk -F\. '{ printf("%03d%03d%03d%03d\n", $1, $2, $3, $4) }')
HOSTNAME="$(hostname)-${IPADDR}"
HZN=$(echo "${HZN}" | jq '.hostname="'${HOSTNAME}'"')

# make a file
echo "${HZN}" > ${TMP}/config.json

# label
if [ ! -z "${SERVICE_LABEL:-}" ] && [ ! -z $(command -v "${SERVICE_LABEL:-}.sh" ) ]; then
  ${SERVICE_LABEL}.sh &
else
  echo "*** ERROR $0 $$ -- environment variable SERVICE_LABEL: ${SERVICE_LABEL:-}; command:" $(command -v "${SERVICE_LABEL:-}.sh") &> /dev/stderr
fi

# port
if [ -z "${LOCALHOST_PORT:-}" ]; then 
  LOCALHOST_PORT=80
else
  echo "+++ WARN: using localhost port ${LOCALHOST_PORT}" &> /dev/stderr
fi

# start listening
socat TCP4-LISTEN:${LOCALHOST_PORT},fork EXEC:service.sh
