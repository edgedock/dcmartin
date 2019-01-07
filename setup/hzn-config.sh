#!/bin/bash

if [ -z $(command -v jq) ]; then
  echo "*** ERROR $0 $$ -- please install jq"
  exit 1
fi

## MACOS is strange
if [[ "$OSTYPE" == "darwin" && "$VENDOR" == "apple" ]]; then
  BASE64_ENCODE='base64'
else
  BASE64_ENCODE='base64 -w 0'
fi

TEMPLATE="template.json"
CONFIG="horizon.json"

if [ -z "${1}" ]; then
  if [ -s "${CONFIG}" ]; then
    echo "+++ WARN $0 $$ -- no configuration specified; default found: ${CONFIG}"
  elif [ -s "${TEMPLATE}" ]; then
    echo "+++ WARN $0 $$ -- no configuration specified; using template: ${TEMPLATE} for default ${CONFIG}"
    cp -f "${TEMPLATE}" "${CONFIG}"
  else
    echo "*** ERROR $0 $$ -- no configuration specified; no default: ${CONFIG}; no template: ${TEMPLATE}"
    exit 1
  fi
else
  CONFIG="${1}"
fi
if [ ! -s "${CONFIG}" ]; then
  echo "*** ERROR $0 $$ -- configuration file empty: ${1}"
  exit 1
else
  echo "??? DEBUG $0 $$ -- configuration file: ${CONFIG}"
fi

for svc in kafka stt nlu nosql; do
 json="apiKey-${svc}.json"
 if [ -s "${json}" ]; then 
   echo "+++ WARN $0 $$ -- found existing ${json} file; using for ${svc} API key"
   apikey=$(jq -r '.apikey' "${json}")
   if [ -z "${apikey}" ] || [ $apikey == 'null' ]; then
     echo "+++ WARN: no apikey in ${json} for ${svc}; checking for api_key"
     apikey=$(jq -r '.api_key' "${json}")
   fi
   if [ -z "${apikey}" ] || [ "$apikey" == 'null' ]; then
     echo "+++ WARN: no API key found in ${json} for ${svc}"
     apikey='null'
     apiname='null'
   else
     apiname=$(jq -r '.iam_apikey_name' "${json}")
     if [ -z "${apiname}" ] || [ "${apiname}" == 'null' ]; then
       echo "+++ WARN: no iam_apikey_name found in ${json} for ${svc}"
       apiname='null'
     fi
   fi
   password=$(jq -r '.password' "${json}")
   if [ -z "${password}" ] || [ "$password" == 'null' ]; then
     echo "+++ WARN: no password found in ${json} for ${svc}"
     password='null'
   fi
   username=$(jq -r '.username' "${json}")
   if [ -z "${username}" ] || [ "$username" == 'null' ]; then
     echo "+++ WARN: no username found in ${json} for ${svc}"
     username='null'
   fi
   url=$(jq -r '.url' "${json}")
   if [ -z "${url}" ] || [ "$url" == 'null' ]; then
     echo "+++ WARN: no url found in ${json} for ${svc}"
     url='null'
   fi
   if [ ! -z "$SVC_API_KEYS" ]; then SVC_API_KEYS="${SVC_API_KEYS}"','; else SVC_API_KEYS='{'; fi
   SVC_API_KEYS="${SVC_API_KEYS}"'"'${svc}'":{"url":"'$url'","name_key":"'${apiname}:${apikey}'","user_pass":"'${username}:${password}'"}'
 fi
done
SVC_API_KEYS="${SVC_API_KEYS}"'}'
echo ${SVC_API_KEYS} | jq 

exit

HORIZON_CLOUDANT_URL=$(jq -r '.apikey' apiKey-nosql.json)
HORIZON_CONFIG_DB='hzn-config'
HORIZON_CONFIG_NAME=$(hostname)

    # find configuration entry
    URL="${HORIZON_CLOUDANT_URL}/${HORIZON_CONFIG_DB}/${HORIZON_CONFIG_NAME}"

    VALUE=$(curl -sL "${URL}")
    if [ "$(echo "${VALUE}" | jq '._id?=="'${HORIZON_CONFIG_NAME}'"')" != "true" ]; then
      hass.log.fatal "Found no configuration ${HORIZON_CONFIG_NAME}"
      hass.die
    fi
    REV=$(echo "${VALUE}" | jq -r '._rev?')
    if [[ "${REV}" != "null" && ! -z "${REV}" ]]; then
      hass.log.debug "Found prior configuration ${HORIZON_CONFIG_NAME}; revision ${REV}"
      URL="${URL}?rev=${REV}"
    fi
    hass.log.info $(date) "Retrieved configuration ${HORIZON_CONFIG_NAME} with ${REV}"
    # make file
    HORIZON_CONFIG_FILE="${CONFIG_DIR}/${HORIZON_CONFIG_NAME}.json"
    echo "${VALUE}" | jq '.' > "${HORIZON_CONFIG_FILE}"
    if [ ! -s "${HORIZON_CONFIG_FILE}" ]; then
      hass.log.fatal "Invalid addon configuration: ${VALUE}"
      hass.die
    fi
    hass.log.debug $(date) "Configuration file: ${HORIZON_CONFIG_FILE}"

    NODES=$(${SCRIPT_DIR}/${LSNODES} "${HORIZON_CONFIG_FILE}")
    hass.log.debug $(date) "Nodes:" $(echo "${NODES}" | jq -c '.nodes[].id')

    ## copy configuration
    cp -f "${HORIZON_CONFIG_FILE}" "${HORIZON_CONFIG_FILE}.$$"
    ## EVALUATE
    hass.log.info $(date) "${SCRIPT} on ${HORIZON_CONFIG_FILE}.$$ for ${HOST_LAN}; logging to ${SCRIPT_LOG}"
    RESULT=$(cd "${SCRIPT_DIR}" && ${SCRIPT_DIR}/${SCRIPT} "${HORIZON_CONFIG_FILE}.$$" "${HOST_LAN}" 2>> "${SCRIPT_LOG}" || true)
    hass.log.info $(date) "Executed ${SCRIPT_DIR}/${SCRIPT} returns:" $(echo "${RESULT}")
    if [ -n "${RESULT}" ]; then
      RESULT=$(echo "${RESULT}" | jq '{"nodes":.,"date":'$(date +%s)',"org":"'${HORIZON_ORGANIZATION}'","device":"'${HORIZON_DEVICE_NAME}'","configuration":"'${HORIZON_CONFIG_NAME}'"}')
      hass.log.debug $(date) "Posting result to ${HORIZON_ORGANIZATION}/${HORIZON_DEVICE_NAME}/${SCRIPT}/result" $(echo "${RESULT}" | jq -c '.')
      mosquitto_pub -r -q 2 -h "${MQTT_HOST}" -p "${MQTT_PORT}" -t "${HORIZON_ORGANIZATION}/${HORIZON_DEVICE_NAME}/${HORIZON_CONFIG_NAME}/result" -m "${RESULT}"
    fi
    if [ -s "${HORIZON_CONFIG_FILE}.$$" ]; then
      DIFF=$(diff "${HORIZON_CONFIG_FILE}" "${HORIZON_CONFIG_FILE}.$$" | wc -c || true)
      if [[ ${DIFF} > 0 ]]; then
        # update configuration
        hass.log.info $(date) "Configuration ${HORIZON_CONFIG_NAME} bytes changed: ${DIFF}; updating database"
        RESULT=$(curl -sL "${URL}" -X PUT -d '@'"${HORIZON_CONFIG_FILE}.$$")
        if [ "$(echo "${RESULT}" | jq '.ok?')" != "true" ]; then
          hass.log.warning $(date) "Update configuration ${HORIZON_CONFIG_NAME} failed; ${HORIZON_CONFIG_FILE}.$$" $(echo "${RESULT}" | jq '.error?')
        else
          hass.log.debug $(date) "Update configuration ${HORIZON_CONFIG_NAME} succeeded:" $(echo "${RESULT}" | jq -c '.')
        fi
        hass.log.info $(date) "Updated configuration: ${HORIZON_CONFIG_NAME}"
        mv -f "${HORIZON_CONFIG_FILE}.$$" "${HORIZON_CONFIG_FILE}"
        if [ -s "${HORIZON_CONFIG_FILE}" ]; then
          RESULT=$(jq '.org="'${HORIZON_ORGANIZATION}'"|.device="'${HORIZON_DEVICE_NAME}'"|.configuration="'${HORIZON_CONFIG_NAME}'"' "${HORIZON_CONFIG_FILE}")
          mosquitto_pub -r -q 2 -h "${MQTT_HOST}" -p "${MQTT_PORT}" -t "${HORIZON_ORGANIZATION}/${HORIZON_DEVICE_NAME}/${HORIZON_CONFIG_NAME}/status" -m "${RESULT}"
        fi
      else
        hass.log.info $(date) "No updates: ${HORIZON_CONFIG_NAME}"
      fi
    else
      hass.log.fatal $(date) "Failed ${SCRIPT} processing; zero-length result; ${SCRIPT_LOG} from host ${HOST_IPADDR}" $(cat "${SCRIPT_LOG}")
      hass.die
    fi

