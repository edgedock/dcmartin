#!/bin/bash

node_status()
{
  machine=${1}
  hzn=$(ssh ${machine} 'command -v hzn')
  if [ ! -z "${hzn}" ]; then
    state=$(ssh ${machine} 'hzn node list 2> /dev/null')
  fi
  if [ -z "${state:-}" ]; then state='null'; fi
  echo ${state}
}

node_state()
{
  machine=${1}
  state=$(node_status ${machine} | jq -r '.configstate.state')
  if [ -z "${state:-}" ]; then state='null'; fi
  echo ${state}
}

node_purge()
{
  machine=${1}
  node_unregister ${machine}
  echo "--- INFO -- $0 $$ -- purging ${machine}" &> /dev/stderr
  ssh ${machine} 'sudo apt-get remove -y bluehorizon horizon horizon-cli' &> /dev/null
  ssh ${machine} 'sudo apt-get purge -y bluehorizon horizon horizon-cli' &> /dev/null
}

node_install()
{
  machine=${1}
  echo "--- INFO -- $0 $$ -- installing ${machine}" &> /dev/stderr
  ssh ${machine} 'sudo apt-get update' &> /dev/null
  ssh ${machine} 'sudo apt-get upgrade -y' &> /dev/null
  ssh ${machine} 'sudo apt-get install -y bluehorizon' &> /dev/null
}

node_unregister()
{
  machine=${1}
  echo "--- INFO -- $0 $$ -- unregistering ${machine}" &> /dev/stderr
  ssh ${machine} 'hzn unregister -f -r' &> /dev/null
}

node_register()
{
  machine=${1}
  echo "--- INFO -- $0 $$ -- registering ${machine} with pattern: ${SERVICE_NAME}; input: ${INPUT}" &> /dev/stderr
  scp ${INPUT} ${machine}:/tmp/input.json &> /dev/null
  ssh ${machine} hzn register ${HZN_ORG_ID} -u iamapikey:${HZN_EXCHANGE_APIKEY} ${SERVICE_NAME} -f /tmp/input.json -n "${machine%.*}:null" # &> /dev/null
}

node_update()
{
  machine=${1}
  state=$(node_state ${machine})
  case ${state} in
    null)
      node_install ${machine}
      ;;
    unconfigured)
      node_register ${machine}
      ;;
    configuring|unconfiguring)
      node_purge ${machine}
      ;;
    configured)
      pattern=$(node_status ${machine} | jq -r '.pattern')
      echo "--- INFO -- $0 $$ -- ${machine} -- configured with ${pattern}" &> /dev/stderr
      if [ "${SERVICE_NAME}" == "${pattern}" ]; then
        URL=$(ssh ${machine} hzn service list | jq -r '.[].url' | while read; do if [ "${REPLY##*.}" == "${pattern##*/}" ]; then echo "${REPLY}"; fi; done)
        VER=$(ssh ${machine} hzn service list | jq -r '.[]|select(.url=="'${URL}'").version')
        echo "--- INFO -- $0 $$ -- ${machine} -- version: ${VER}; url: ${URL}" &> /dev/stderr
      else
	node_unregister ${machine}
        sleep 30
      fi
      ;;
    *)
      echo "+++ WARN -- $0 $$ -- ${state} ${machine} with ${SERVICE_NAME}" &> /dev/stderr
      ;;
  esac
  state=$(node_state ${machine})
  echo ${state}
}

if [ -z "${HZN_ORG_ID}" ]; then echo "*** ERROR -- $0 $$0 -- set environment variable HZN_ORG_ID"; exit 1; fi
if [ -z "${HZN_EXCHANGE_APIKEY}" ]; then echo "*** ERROR -- $0 $$0 -- set environment variable HZN_EXCHANGE_APIKEY"; exit 1; fi

if [ -z "${SERVICE_NAME}" ]; then 
  if [ ! -z "${2}" ]; then SERVICE_NAME="${2}"; else echo "*** ERROR -- $0 $$0 -- set environment variable SERVICE_NAME"; exit 1; fi
fi
if [ "${SERVICE_NAME##*/}" == "${SERVICE_NAME}" ]; then
  SERVICE_NAME="${HZN_ORG_ID}/${SERVICE_NAME}"
  if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- missing service organization; using ${SERVICE_NAME}" &> /dev/stderr; fi
fi
if [ -z "${INPUT}" ]; then 
  if [ ! -z "${3}" ]; then INPUT="${3}"; else  echo "*** ERROR -- $0 $$0 -- set environment variable INPUT"; exit 1; fi
fi

###
### MAIN
###

machine=${1}
if [ -z "${machine}" ]; then echo "*** ERROR -- $0 $$ -- no machine specified; exiting" &> /dev/stderr; exit 1; fi

OUT=$(ping -c 1 ${machine})
if [ $? != 0 ]; then echo "+++ WARN -- $0 $$ -- machine not found on network; exiting" &> /dev/stderr; exit 1; fi

IPADDR=$(echo "${OUT}" | head -1 | sed 's|.*(\([^)]*\)).*|\1|')

echo "--- INFO -- $0 $$ -- ${machine} at IP: ${IPADDR:-}" &> /dev/stderr
state=$(node_update ${machine}) 
while [ "${state}" != 'configured' ]; do
  echo "--- INFO -- $0 $$ -- machine: ${machine}; state: ${state}" &> /dev/stderr
  state=$(node_update "${machine}") 
done

