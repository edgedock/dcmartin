#!/bin/bash

if [ -z $(command -v jq) ]; then
  echo "*** ERROR $0 $$ -- please install jq"
  exit 1
fi

TEMPLATE="template.json"
CONFIG="horizon.json"
ID_RSA=~/.ssh/id_rsa

if [ -z "${1}" ]; then
  if [ -s "${CONFIG}" ]; then
    echo "+++ WARN $0 $$ -- no configuration specified; default found: ${CONFIG}" &> /dev/stderr
  elif [ -s "${TEMPLATE}" ]; then
    echo "+++ WARN $0 $$ -- no configuration specified; using template: ${TEMPLATE} for default ${CONFIG}" &> /dev/stderr
    cp -f "${TEMPLATE}" "${CONFIG}"
  else
    echo "*** ERROR $0 $$ -- no configuration specified; no default: ${CONFIG}; no template: ${TEMPLATE}" &> /dev/stderr
    exit 1
  fi
else
  CONFIG="${1}"
fi
if [ ! -s "${CONFIG}" ]; then
  echo "*** ERROR $0 $$ -- configuration file empty: ${1}" &> /dev/stderr
  exit 1
fi

if [ $(jq '.keys==null' "${CONFIG}") ]; then
  if [ -s "${ID_RSA}" ] && [ -s "${ID_RSA}.pub" ]; then
    echo "+++ WARN $0 $$ -- no keys configured; using default ${ID_RSA}"
  else
    echo "+++ WARN $0 $$ -- no SSH credentials; generating.."
    # generate new key
    ssh-keygen -t rsa -f "$ID_RSA" -N "" &> /dev/null
    # test for success
    if [ ! -s "$ID_RSA" ] || [ ! -s "$ID_RSA.pub" ]; then
      echo "*** ERROR: ${id}: failed to create keys $ID_RSA" &> /dev/stderr
      exit 1
    fi
  fi
  jq '.keys={"public":"'${BASE64} "${ID_RSA}.pub"'","private":"'${BASE64} "${ID_RSA}"'"}' "${CONFIG}" > "/tmp/$$.json"
  if [ -s "/tmp/$$.json" ]; then
    mv -f "/tmp/$$.json" "${CONFIG}"
    # echo "??? DEBUG updated ${CONFIG}"
  else
    echo "*** ERROR $0 $$ -- failed to update ${CONFIG}; /tmp/$$.json is empty"
    exit 1
  fi
fi

if [ -s "apiKey.json" ]; then IBMCLOUD_APIKEY=$(jq -r '.apiKey' "apiKey.json"); fi
if [ -s "apiKey-kafka.json" ]; then KAFKA_APIKEY=$(jq -r '.api_key' "apiKey-kafka.json"); fi

cids=$(jq -r '.configurations[]?.id' "${CONFIG}")
if [ -n "${cids}" ] && [ "${cids}" != "null" ]; then
  # echo "??? DEBUG cids:" $(echo "${cids}" | fmt)
  for cid in ${cids}; do
    # echo "??? DEBUG configuration id: $cid"
    c=$(jq '.configurations[]|select(.id=="'$cid'")' "${CONFIG}")
    # echo "??? DEBUG configuration ${cid}:" $(echo "${c}" | jq -c '.')
    nodes=$(echo "${c}" | jq -r '.nodes[]?.id')
    if [ -z "${nodes}" ] || [ "${nodes}" == "null" ]; then
      echo "+++ WARN no nodes for configuration ${cid}"
      continue
    fi
    # echo "??? DEBUG nodes:" $(echo "${nodes}" | fmt)

    echo "--- CONFIGURATION ${cid}"
    # process variables
    keys=$(echo "${c}" | jq -r '.variables[]?.key')
    if [ -n "${keys}" ] && [ "${keys}" != "null" ]; then
      # echo "??? DEBUG keys:" $(echo "$keys" | fmt)
      for key in ${keys}; do
	valid=$(echo "${c}" | jq '.variables[]?|select(.key=="'$key'").value|contains("%%") == false')
	if [ "${valid}" == 'true' ]; then
	  v=$(echo "${c}" | jq -r '(.variables[]?|select(.key=="'$key'")).value')
	  echo -n "[$cid] Enter value for ${key} [" $(echo "${v}" | sed 's|\(...\).*\(...\)|\1***\2|') "]: "
	  read VALUE
	  if [ -z "${VALUE}" ]; then VALUE="${v}"; fi
	else
	  echo -n "[$cid] Enter value for ${key}: "
	  read VALUE
	fi
	c=$(echo "${c}" | jq '(.variables[]|select(.key=="'$key'").value)|="'"${VALUE}"'"')
      done
    fi

    # echo "??? DEBUG configuration ${cid}:" $(echo "${c}" | jq -c '.')
    jq '(.configurations[]|select(.id=="'$cid'"))|='"${c}" "${CONFIG}" > "/tmp/$$.json"
    if [ -s "/tmp/$$.json" ]; then
      mv -f "/tmp/$$.json" "${CONFIG}"
      # echo "??? DEBUG updated ${CONFIG}"
    else
      echo "*** ERROR $0 $$ -- failed to update ${CONFIG}; /tmp/$$.json is empty"
      exit 1
    fi

    # process exchange
    eid=$(echo "${c}" | jq -r '.exchange')
    if [ -z "${eid}" ] || [ "${eid}" == 'null' ]; then
      echo "*** ERROR $0 $$ -- configuration ${cid}: no exchange: ${eid}" &> /dev/stderr
      exit 1
    fi
    e=$(jq '.exchanges[]?|select(.id=="'$eid'")' "${CONFIG}")
    if [ -z "${e}" ] || [ "${e}" == 'null' ]; then
      echo "*** ERROR $0 $$ -- cannot find exchange ${eid} for configuration ${cid}" &> /dev/stderr
      exit 1
    fi
    # echo "??? DEBUG found exchange:" $(echo "${e}" | jq -c '.')
    for key in org password; do
      valid=$(echo "${e}" | jq '.'"${key}"'|contains("%%") == false')
      if [ "${key}" == "password" ] && [ "${valid}" != "true" ] && [ -n "${IBMCLOUD_APIKEY}" ]; then
        v="${IBMCLOUD_APIKEY}"
      elif [ "${valid}" == "true" ]; then
        v=$(echo "${e}" | jq -r '.'"${key}")
      else
        v=
      fi
      if [ -n "${v}" ]; then
	echo -n "[$cid] exchange [${eid}]: enter value for ${key} [" $(echo "${v}" | sed 's|\(...\).*\(...\)|\1***\2|') "]: "
	read VALUE
	if [ -z "${VALUE}" ]; then VALUE="${v}"; fi
      else
	echo -n "[$cid] exchange [${eid}]: enter value for ${key}: "
	read VALUE
      fi
      e=$(echo "${e}" | jq '.'${key}'="'"${VALUE}"'"')
    done
    jq '(.exchanges[]|select(.id=="'$eid'"))|='"${e}" "${CONFIG}" > "/tmp/$$.json"
    if [ -s "/tmp/$$.json" ]; then
      mv -f "/tmp/$$.json" "${CONFIG}"
      # echo "??? DEBUG updated ${CONFIG}"
    else
      echo "*** ERROR $0 $$ -- failed to update ${CONFIG}; /tmp/$$.json is empty"
      exit 1
    fi
  
    # process pattern
    pattern=$(jq '.patterns[]?|select(.id=="'$(echo "${c}" | jq -r '.pattern')'")' "${CONFIG}")
    if [ -z "${pattern}" ] || [ "${pattern}" == 'null' ]; then
      echo "*** ERROR $0 $$ -- cannot find pattern for configuration ${cid}" &> /dev/stderr
      exit 1
    fi

    # process network
    nid=$(echo "${c}" | jq -r '.network')
    if [ -z "${nid}" ] || [ "${nid}" == 'null' ]; then
      echo "*** ERROR $0 $$ -- configuration ${cid}: no network: ${nid}" &> /dev/stderr
      exit 1
    fi
    n=$(jq '.networks[]?|select(.id=="'$nid'")' "${CONFIG}")
    if [ -z "${n}" ] || [ "${n}" == 'null' ]; then
      echo "*** ERROR $0 $$ -- cannot find network ${nid} for configuration ${cid}" &> /dev/stderr
      exit 1
    fi
    # echo "??? DEBUG found network:" $(echo "${n}" | jq -c '.')
    for key in ssid password; do
      valid=$(echo "${n}" | jq '.'"${key}"'|contains("%%") == false')
      if [ "${valid}" == "true" ]; then
	v=$(echo "${n}" | jq -r '.'"${key}")
	echo -n "[$cid] network [$nid]: enter value for ${key} [${v}]: "
	read VALUE
	if [ -z "${VALUE}" ]; then VALUE="${v}"; fi
      else
	echo -n "[$cid] network [$nid]: enter value for ${key}: "
	read VALUE
      fi
      n=$(echo "${n}" | jq '.'${key}'="'"${VALUE}"'"')
    done
    jq '(.networks[]|select(.id=="'$nid'"))|='"${n}" "${CONFIG}" > "/tmp/$$.json"
    if [ -s "/tmp/$$.json" ]; then
      mv -f "/tmp/$$.json" "${CONFIG}"
      # echo "??? DEBUG updated ${CONFIG}"
    else
      echo "*** ERROR $0 $$ -- failed to update ${CONFIG}; /tmp/$$.json is empty"
      exit 1
    fi

  done
fi

## setup network (default)
n=$(jq '.networks|first' "${CONFIG}")
if [ -z "${n}" ] || [ "${n}" == 'null' ]; then
  echo "*** ERROR $0 $$ -- cannot find first network for setup"
  exit 1
fi
nid=$(echo "${n}" | jq -r '.id')
echo "--- NETWORK (setup-only) [${nid}]"
for key in ssid password; do
  valid=$(echo "${n}" | jq '.'"${key}"'|contains("%%") == false')
  if [ "${valid}" == "true" ]; then
    v=$(echo "${n}" | jq -r '.'"${key}")
    echo -n "[$nid] enter value for ${key} [${v}]: "
    read VALUE
    if [ -z "${VALUE}" ]; then VALUE="${v}"; fi
  else
    echo -n "[$nid] enter value for ${key}: "
    read VALUE
  fi
  n=$(echo "${n}" | jq '.'${key}'="'"${VALUE}"'"')
done
jq '(.networks[]|select(.id=="'$nid'"))|='"${n}" "${CONFIG}" > "/tmp/$$.json"
if [ -s "/tmp/$$.json" ]; then
  mv -f "/tmp/$$.json" "${CONFIG}"
  # echo "??? DEBUG updated ${CONFIG}"
else
  echo "*** ERROR $0 $$ -- $0 $$ -- failed to update ${CONFIG}; /tmp/$$.json is empty"
  exit 1
fi
