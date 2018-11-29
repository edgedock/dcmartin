#!/bin/bash
DEBUG=
VERBOSE=

if [[  $(whoami) -ne "root"  ]]; then
  echo "ERROR: Please run as root, e.g. sudo $0 $argv" 
  exit 1
else
  SSH_DIR=$(echo ~${USER}/.ssh)
fi

###
### default EXCHANGE URL
###

HZN_EXCHANGE_URL="https://alpha.edge-fabric.com/v1"

## check for necessary tooling
if [[ ! -e "/usr/local/bin/nmap" && ! -e "/usr/bin/nmap" ]]; then
  /bin/echo 'No nmap(8); install using brew or apt' &> /dev/stderr
  exit 1
fi

# MACHTYPE
#
# RPi3: arm-unknown-linux-gnueabihf
# LINUX VM: x86_64-pc-linux-gnu
# macOS: x86_64


if [[ $MACHTYPE =~ *linux* ]]; then
  set BASE64_ENCODE='base64 -w 0'
elif [[ $OSTYPE == "darwin" && $VENDOR == "apple" ]]; then
  set BASE64_ENCODE='base64'
else
  echo "Cannot determine which base64 encoding arguments"
  exit 1
fi

if [[ -n $argv ]]; then
  config=$argv[1]
else
  config="horizon.json"
fi
if [[ ! -s "$config"  ]]; then
  echo "Cannot find configuration file"
  exit 1
fi

## DISTRIBUTION config
HORIZON_SETUP_URL=$(jq -r '.setup' "$config")

# ${#distro[@]}
if [[ ${#argv[@]} > 1 ]]; then
  net=$argv[2]
else
  net="192.168.1.0/24"
fi
echo "INFO: executing: $0 $config $net" &> /dev/stderr

TTL=300 # seconds
SECONDS=$(date "+%s")
DATE=$(echo $SECONDS \/ $TTL \* $TTL | bc)
TMP="/tmp/$0:t.$$"

# make temporary directory for working files
mkdir -p "$TMP"
if [[ ! -d "$TMP" ]]; then
  echo "FATAL: no $TMP"
  exit 1
fi

out="/tmp/$0:t.$DATE.txt"
if [[ ! -e "$out" ]]; then
  rm -f "$out:h/$0:t".*.txt
  sudo nmap -sn -T5 "$net" > "$out"
fi

if [[ ! -e "$out" ]]; then
  echo 'No nmap(8) output for '"$net" &> /dev/stderr
  exit 1
fi

macs=$(egrep MAC "$out" | sed 's/.*: \([^ ]*\) .*/\1/')
macarray=($(echo ${macs}))

echo "INFO: found ${#macarray[@]} devices by MAC"

###
### ITERATE OVER ALL MACS on LAN
###

for mac in ${macs}; do 
  # get ipaddr
  client_ipaddr=$(egrep -B 2 "$mac" "$out" | egrep "Nmap scan" | head -1 | awk '{ print $5 }')
  # search for device by mac
  id=$(jq -r '.nodes[]|select(.mac=="'$mac'").id' "$config")
  if [[ -z "$id" ]]; then
    if [ -n "${VERBOSE:-}" ]; then echo "VERBOSE: NOT FOUND; MAC: $mac; IP: $client_ipaddr"; fi
    continue
  else
    # get ip address from nmap output file
    echo "INFO: ($id): FOUND ($id); MAC: $mac; IP $client_ipaddr"
    if [[ -s "${SSH_DIR}/known_hosts" ]]; then
      if [ -n "${DEBUG:-}" ]; then echo "DEBUG ($id): removing $client_ipaddr from $SSH_DIR/known_hosts"; fi
      egrep -v "${client_ipaddr}" "${SSH_DIR}/known_hosts" > $TMP/known_hosts
      mv -f $TMP/known_hosts ${SSH_DIR}/known_hosts
    fi
  fi

  # find configuration which includes device
  conf=$(jq '.configurations[]|select(.nodes[].id=="'$id'")' "$config")
  if [[ -z "${conf}" || "${conf}" == "null" ]]; then
    echo "ERROR: ($id): Cannot find node configuration for device: $id"
    continue
  else
    # identify configuration
    conf_id=$(echo "$conf" | jq -r '.id')
  fi

  # find node state (cannot fail)
  node_state=$(jq '.nodes[]|select(.id=="'$id'")' "$config")

  ## TEST STATUS
  config_keys=$(echo "$conf" | jq '.public_key!=null')
  config_ssh=$(echo "$node_state" | jq '.ssh!=null')
  config_security=$(echo "$node_state" | jq '.ssh.device!=null')
  config_software=$(echo "$node_state" | jq '.software!=null')
  config_exchange=$(echo "$node_state" | jq '.exchange.node!=null')
  config_network=$(echo "$node_state" | jq '.network!=null')

  ## CONFIGURATION KEYS
  if [[ $config_keys -ne 'true' ]]; then
    # test for existing keys
    if [[ ! -s "$conf_id" && ! -s "${conf_id}.pub" ]]; then
      if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): configuring KEYS for $conf_id"; fi
      # generate new key
      ssh-keygen -t rsa -f "$conf_id" -N "" &> /dev/null
      # test for success
      if [[ ! -s "$conf_id" || ! -s "$conf_id.pub" ]]; then
        echo "ERROR: ($id): failed to create key files for $conf_id"
        exit 1
      fi
    else
      if [ -n "${VERBOSE:-}" ]; then echo "VERBOSE: ($id): using existing keys $conf_id"; fi
    fi
    # save into configuration
    public_key='{ "encoding": "base64", "value": "'$(${BASE64_ENCODE} "${conf_id}.pub")'" }'
    jq '(.configurations[]|select(.id=="'"$conf_id"'").public_key)|='"$public_key" "$config" > "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    private_key='{ "encoding": "base64", "value": "'$(${BASE64_ENCODE} "$conf_id")'" }'
    jq '(.configurations[]|select(.id=="'$conf_id'").private_key)|='"$private_key" "$config" > "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    conf=$(jq '.configurations[]|select(.nodes[].id=="'$id'")' "$config")
    # update status
    config_keys=$(echo "$conf" | jq '.public_key!=null')
  fi
  # sanity
  if [[ $config_keys -ne 'true' ]]; then
    echo "FATAL: ($id): failure to configure keys for $conf_id"
    exit
  else
    public_key=$(echo "$conf" | jq '.public_key')
    private_key=$(echo "$conf" | jq '.private_key')
    if [ -n "${VERBOSE:-}" ]; then echo "VERBOSE: ($conf_id): KEYS configured"; fi
  fi

  # process public key for device
  pke=$(echo "$public_key" | jq -r '.encoding')
  if [[ -n $pke && "$pke" == "base64" ]]; then
    public_keyfile="$TMP/$conf_id.pub"
    if [[  ! -e "$public_keyfile"  ]]; then
      echo "$public_key" | jq -r '.value' | base64 --decode > "$public_keyfile"
      chmod 400 "$public_keyfile"
    else
      if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($conf_id): found existing keyfile: $public_keyfile"; fi
    fi
  else
    echo "FATAL: ($id): invalid public key encoding"
    exit 1
  fi

  # process private key for device
  pke=$(echo "$private_key" | jq -r '.encoding')
  if [[ -n $pke && "$pke" == "base64" ]]; then
    private_keyfile="$TMP/$conf_id"
    if [[  ! -e "$private_keyfile"  ]]; then
      echo "$private_key" | jq -r '.value' | base64 --decode > "$private_keyfile"
      chmod 400 "$private_keyfile"
    else
      if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($conf_id): found existing keyfile: $private_keyfile"; fi
    fi
  else
    echo "FATAL: ($id): invalid private key encoding"
    exit 1
  fi


  # get configuration for identified node
  node_conf=$(echo "$conf" | jq '.nodes[]|select(.id=="'"$id"'")')

  # get default username and password for distribution associated with machine assigned to node
  mid=$(echo "$node_conf" | jq -r '.machine')
  did=$(jq -r '.machines[]|select(.id=="'$mid'").distribution' "$config") 
  dist=$(jq '.distributions[]|select(.id=="'$did'")' "$config")
  client_hostname=$(echo "$dist" | jq -r '.client.hostname')
  client_username=$(echo "$dist" | jq -r '.client.username')
  client_password=$(echo "$dist" | jq -r '.client.password')
  client_distro=$(echo "$dist" | jq '{"id":.id,"kernel_version":.kernel_version,"release_date":.release_date,"version":.version}')

  if [ -n "${VERBOSE:-}" ]; then echo "VERBOSE: ($id): machine = $mid; distribution = $did"; fi

  ## CONFIG SSH
  if [[ $config_ssh -ne "true" ]]; then
    echo "INFO: ($id): SSH attempting copy-id: $client_ipaddr"

    # edit template ssh-copy-id 
    ssh_copy_id="$TMP/ssh-copy-id.exp"
    cat "ssh-copy-id.tmpl" \
      | sed 's|%%CLIENT_IPADDR%%|'"${client_ipaddr}"'|g' \
      | sed 's|%%CLIENT_USERNAME%%|'"${client_username}"'|g' \
      | sed 's|%%CLIENT_PASSWORD%%|'"${client_password}"'|g' \
      | sed 's|%%PUBLIC_KEYFILE%%|'"${public_keyfile}"'|g' \
      > "$ssh_copy_id"
    if [ -n "${VERBOSE:-}" ]; then echo "VERBOSE: ($id): attempting ssh-copy-id ($public_keyfile) to device $id"; fi
    success=$(expect -f "$ssh_copy_id" |& egrep "success")
    if [[ "${success}" -ne "success"  ]]; then
      echo "ERROR: ($id) SSH failed; consider re-flashing"
      continue
    fi
    if [ -n "${DEBUG:-}" ]; then echo "DEBUG ($id): configured with $conf_id public key"; fi
    ## UPDATE CONFIGURATION
    node_state=$(echo "$node_state" | jq '.ssh.id="'"${conf_id}"'"')
    if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): updating configuration $config"; fi
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" > "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    # get new status
    config_ssh=$(jq '.nodes[]|select(.id=="'$id'").ssh != null' "$config")
  fi
  # sanity
  if [[ $config_ssh -ne "true" ]]; then
    echo "ERROR: ($id): SSH failed"
    continue
  else
    # test access
    result=$(ssh -o "BatchMode yes" -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'whoami')
    if [[ -z $result || "$result" -ne "${client_username}" ]]; then
      echo "ERROR: ($id) SSH failed; cannot confirm identity ${client_username}; got ($result):" $(echo "$node_state" | jq '.ssh')
      continue
    fi
    echo "INFO: ($id): SSH public key configured: " $(echo "$node_state" | jq -c '.ssh.id')
  fi

  ## CONFIG SECURITY
  if [[ $config_security -ne 'true' ]]; then
    echo "INFO: ($id): SECURITY setting hostname and password"
    # get node configuration specifics
    device=$(echo "$node_conf" | jq -r '.device')
    token=$(echo "$node_conf" | jq -r '.token')
    if [[ -z $device || -z $token ]]; then
      echo "ERROR: ($id): node configuration device or token are unspecified: $node_conf"
      continue
    fi
    # create device and token script
    config_script="$TMP/config-ssh.sh"
    cat "config-ssh.tmpl" \
      | sed 's|%%DEVICE_NAME%%|'"${device}"'|g' \
      | sed 's|%%CLIENT_USERNAME%%|'"${client_username}"'|g' \
      | sed 's|%%CLIENT_HOSTNAME%%|'"${client_hostname}"'|g' \
      | sed 's|%%DEVICE_TOKEN%%|'"${token}"'|g' \
      > "$config_script"
    if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): copying SSH script ($config_script)"; fi
    scp -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$config_script" "${client_username}@${client_ipaddr}:." &> /dev/null
    if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): invoking SSH script ($config_script:t)"; fi
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'sudo bash '"$config_script:t"
    ## UPDATE CONFIGURATION
    node_state=$(echo "$node_state" | jq '.ssh={"id":"'"$conf_id"'","token":"'"${token}"'","device":"'"${device}"'"}')
    if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): updating configuration $config"; fi
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" > "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    config_security=$(echo "$node_state" | jq '.ssh.device!=null')
  fi
  # sanity
  if [[ $config_security -ne "true" ]]; then
    echo "ERROR: ($id): SECURITY failed"
    continue
  else
    # test access
    result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'hostname')
    if [[ -z $result || $(echo "$node_state" | jq -r '.ssh.device=="'"$result"'"') -ne 'true' ]]; then
      echo "ERROR: ($id) SSH failed; cannot confirm hostname: ${result}" $(echo "$node_state" | jq '.ssh')
      continue
    fi
    echo "INFO: ($id): SECURITY configured" $(echo "$node_state" | jq -c '.ssh')
  fi

  ## CONFIG SOFTWARE
  if [[ $config_software -ne "true" ]]; then
    echo "INFO: ($id): SOFTWARE installing ${HORIZON_SETUP_URL}"
    # install software
    result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'wget -qO - '"${HORIZON_SETUP_URL}"' | sudo bash 2> log' | jq '.')
    if [[ -z "${result}" ]]; then
      echo "ERROR: ($id): SOFTWARE failed; result = $result"
      continue
    fi
    # add distribution information
    result=$(echo "$result" | jq '.|.distribution='"${client_distro}")
    if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): result = $result"; fi
    # update node state
    node_state=$(echo "$node_state" | jq '.|.software='"$result")
    if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): node state = $node_state"; fi
    # update configuration file
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" > "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    # update software configuration
    config_software=$(jq '.nodes[]|select(.id=="'$id'").software != null' "$config")
  fi
  # sanity
  if [[ $config_software -ne "true" ]]; then
    echo "WARN: ($id): SOFTWARE failed"
    continue
  else
    # test access
    result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'command -v hzn')
    if [[ -z $result || $(echo "$node_state" | jq -r '.software.command=="'$result'"') -ne 'true' ]]; then
      echo "ERROR: ($id) SOFTWARE failed; cannot confirm command" $(echo "$node_state" | jq '.software')
      continue
    fi
    echo "INFO: ($id): SOFTWARE configured" $(echo "$node_state" | jq -c '.software')
  fi

  ## CONFIG EXCHANGE
  if [[ $config_exchange -ne "true" ]]; then
    echo "INFO: ($id): configuring EXCHANGE"
    # get exchange
    ex_id=$(echo "$conf" | jq -r '.exchange')
    if [[ -z $ex_id || "$ex_id" == "null" ]]; then
      echo "ERROR: ($id): exchange not specified in configuration: $conf"
      continue
    fi
    exchange=$(jq '.exchanges[]|select(.id=="'$ex_id'")' "$config")
    if [[ -z "${exchange}" || "${exchange}" == null ]]; then
      echo "ERROR: ($id): exchange $ex_id not found in exchanges"
      continue
    fi
    # check URL for exchange
    ex_url=$(echo "$exchange" | jq -r '.url')
    if [[ -z $ex_url || "$ex_url" == "null" ]]; then
      ex_url="$HZN_EXCHANGE_URL"
      echo "WARN: exchange $ex_id does not have URL specified; using default: $ex_url"
    fi

    # update node state
    node_state=$(echo "$node_state" | jq '.exchange.id="'"$ex_id"'"|.exchange.url="'"$ex_url"'"')
    if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): node state:" $(echo "$node_state" | jq -c '.'); fi

    # get exchange specifics
    ex_org=$(echo "$exchange" | jq -r '.org')
    ex_username=$(echo "$exchange" | jq -r '.username')
    ex_password=$(echo "$exchange" | jq -r '.password')
    ex_device=$(echo "$node_state" | jq -r '.ssh.device')
    ex_token=$(echo "$node_state" | jq -r '.ssh.token')

    # force specification of exchange URL
    cmd="sudo sed -i 's|HZN_EXCHANGE_URL=.*|HZN_EXCHANGE_URL=${ex_url}|' /etc/default/horizon"
    if [ -n "${VERBOSE:-}" ]; then echo "VERBOSE: ($id): executing remote command: $cmd"; fi
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd &> /dev/null"
    cmd="sudo systemctl restart horizon || false"
    if [ -n "${VERBOSE:-}" ]; then echo "VERBOSE: ($id): executing remote command: $cmd"; fi
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd &> /dev/null"
    # test for failure status
    if [[ $? -ne 0 ]]; then
      echo "ERROR: ($id): EXCHANGE failed; $cmd"
      continue
    fi

    # create node in exchange (always returns nothing)
    cmd="hzn exchange node create -o ${ex_org} -u ${ex_username}:${ex_password} -n ${ex_device}:${ex_token}"
    if [ -n "${VERBOSE:-}" ]; then echo "VERBOSE: ($id): executing remote command: $cmd"; fi
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd &> /dev/null"
    result=$?
    while [[ $result -ne 0 ]]; do
	if [ -n "${DEBUG:-}" ]; then echo "WARN: ($id): failed command ($result): $cmd"; fi
        ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd &> /dev/null"
        result=$?
    done

    # get exchange node information
    cmd="hzn exchange node list -o ${ex_org} -u ${ex_username}:${ex_password} ${ex_device}"
    if [ -n "${VERBOSE:-}" ]; then echo "VERBOSE: ($id): executing remote command: $cmd"; fi
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" > "$TMP/henl.json"
    result=$?
    while [[ $result -ne 0 || ! -s "$TMP/henl.json" ]]; do
      echo "WARN: ($id): EXCHANGE retry; $cmd"
      ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" > "$TMP/henl.json"
      result=$?
    done
    if [ -n "${VERBOSE:-}" ]; then echo "VERBOSE: ($id): result $TMP/henl.json" $(jq -c '.' "$TMP/henl.json"); fi
    # update node state
    result=$(sed 's/{}/null/g' "$TMP/henl.json" | jq '.')
    node_state=$(echo "$node_state" | jq '.exchange.node='"$result")
    if [ -n "${VERBOSE:-}" ]; then echo "VERBOSE: ($id): node state:" $(echo "$node_state" | jq -c '.'); fi

    # get exchange status
    cmd="hzn exchange status -o $ex_org -u ${ex_username}:${ex_password}"
    if [ -n "${VERBOSE:-}" ]; then echo "VERBOSE: ($id): executing remote command: $cmd"; fi
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" > "$TMP/hes.json"
    result=$?
    while [[ $result -ne 0 || ! -s "$TMP/hes.json" ]]; do
      echo "WARN: ($id): EXCHANGE retry; $cmd"
      ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" > "$TMP/hes.json"
      result=$?
    done
    if [ -n "${VERBOSE:-}" ]; then echo "VERBOSE: ($id): result $TMP/hes.json" $(jq -c '.' "$TMP/hes.json"); fi
    # update node state
    result=$(sed 's/{}/null/g' "$TMP/hes.json" | jq '.')
    node_state=$(echo "$node_state" | jq '.exchange.status='"$result")
    if [ -n "${VERBOSE:-}" ]; then echo "VERBOSE: ($id): node state:" $(echo "$node_state" | jq -c '.'); fi

    ## UPDATE CONFIGURATION
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" > "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    config_exchange=$(jq '.nodes[]|select(.id=="'$id'").exchange.node != null' "$config")
  fi
  # sanity
  if [[ $config_exchange -ne "true" ]]; then
    echo "WARN: ($id): EXCHANGE failed"
    continue
  else
    echo "INFO: ($id): EXCHANGE configured" $(echo "$node_state" | jq -c '.exchange')
  fi

  ##
  ## CONFIG PATTERN (or reconfigure)
  ##

  echo "INFO: ($id): configuring PATTERN"
  # get pattern
  ptid=$(echo "$conf" | jq -r '.pattern?')
  if [[ -z $ptid || $ptid == 'null' ]]; then
    echo "ERROR: ($id): pattern not specified in configuration: $conf"
    continue
  fi
  if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): pattern identifier $ptid"; fi
  pattern=$(jq '.patterns[]|select(.id=="'$ptid'")' "$config")
  if [[ -z "${pattern}" || "${pattern}" == "null" ]]; then
    echo "ERROR: ($id): pattern $ptid not found in patterns"
    continue
  fi

  # pattern for registration
  pt_id=$(echo "$pattern" | jq -r '.id')
  pt_org=$(echo "$pattern" | jq -r '.org')
  pt_url=$(echo "$pattern" | jq -r '.url')
  pt_vars=$(echo "$conf" | jq '.variables')
  
  # get node specifics
  ex_id=$(echo "$node_state" | jq -r '.exchange.id')
  ex_device=$(echo "$node_state" | jq -r '.ssh.device')
  ex_token=$(echo "$node_state" | jq -r '.ssh.token')
  ex_org=$(jq -r '.exchanges[]|select(.id=="'"$ex_id"'").org' "$config")
  ex_username=$(jq -r '.exchanges[]|select(.id=="'"$ex_id"'").username' "$config")
  ex_password=$(jq -r '.exchanges[]|select(.id=="'"$ex_id"'").password' "$config")

  # get node status
  cmd='hzn node list'
  if [ -n "${VERBOSE:-}" ]; then echo "VERBOSE: ($id): executing remote command: $cmd"; fi
  result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" | jq '.')
  node_state=$(echo "$node_state" | jq '.node='"$result")

  # test if node is configured with pattern
  node_id=$(echo "$node_state" | jq -r '.node.id')
  node_status=$(echo "$node_state" | jq -r '.node.configstate.state')
  node_pattern=$(echo "$node_state" | jq -r '.node.pattern')

  # unregister node iff
  if [[ ${node_id} == ${ex_device} && $node_pattern == ${pt_org}/${pt_id} && ( $node_status == "configured" || $node_status == "configuring" ) ]]; then
    if [ -n "${DEBUG:-}" ]; then echo "INFO: node ${node_id} is ${node_status} with pattern ${node_pattern}"; fi
  elif [[ $node_status == "unconfiguring" ]]; then
    if [ -n "${DEBUG:-}" ]; then echo "ERROR: ($id): node ${node_id} (aka ${ex_device}) is unconfiguring; consider reflashing (or remove, purge, update, prune, and reboot)"; fi
    continue
  elif [[ ${node_id} -ne ${ex_device} || $node_status -ne "unconfigured" ]]; then
    echo "INFO: ($id): unregistering node ${node_id}"
    # unregister client
    cmd='hzn unregister -f'
    if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): executing remote command: $cmd"; fi
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd &> /dev/null"

    # POLL client for node list information; wait until device identifier matches requested
    cmd='hzn node list'
    if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): executing remote command: $cmd"; fi
    result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" | jq '.')
    while [[ $(echo "$result" | jq '.configstate.state=="unconfigured"') == false ]]; do
      if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): waiting on unregistration (10): $result"; fi
      sleep 10
      if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): executing remote command: $cmd"; fi
      result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" | jq '.')
    done
    node_state=$(echo "$node_state" | jq '.node='"$result")
  fi

  # register node iff
  if [[ $(echo "$node_state" | jq '.node.configstate.state=="unconfigured"') == true ]]; then
    echo "INFO: registering node" $(echo "$node_state" | jq -c '.')
    # create pattern registration file
    input="$TMP/input.json"
    echo '{"services": [{"org": "'"${pt_org}"'","url": "'"${pt_url}"'","versionRange": "[0.0.0,INFINITY)","variables": {' > "${input}"
    # process all variables 
    pvs=$(echo "${pt_vars}" | jq -r '.[].key')
    i=0
    for pv in ${pvs}; do
      value=$(echo "${pt_vars}" | jq -r '.[]|select(.key=="'"${pv}"'").value')
      if [[ $i ]]; then echo ',' >> "${input}"; fi
      echo '"'"${pv}"'":"'"${value}"'"' >> "${input}"
      i=$((i+1))
    done
    echo '}}]}' >> "${input}"
    if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): node ${ex_device} pattern ${pt_org}/${pt_id}: " $(jq -c "${input}"); fi

    # copy pattern registration file to client
    scp -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "${input}" "${client_username}@${client_ipaddr}:." &> /dev/null
    # perform registration
    cmd="hzn register ${ex_org} -u ${ex_username}:${ex_password} ${pt_org}/${pt_id} -f ${input:t} -n ${ex_device}:${ex_token}"
    if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): registering with command: $cmd"; fi
    result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "${cmd} &> /dev/null")
  fi

  # POLL client for node list information; wait for configured state
  cmd="hzn node list"
  while [[ result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" | jq '.') \
   && $(echo "$result" | jq '.configstate.state=="configured"') == false ]]; do
    if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): waiting on configuration (10): $result"; fi
    sleep 10
  done
  if [[ -z "${result}" || "${results}" == "null" ]]; then
    echo "ERROR: failed to execute: $cmd"
    continue
  fi
  node_state=$(echo "$node_state" | jq '.node='"$result")
  if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): node is configured"; fi

  # POLL client for agreementlist information; wait until agreement exists
  cmd="hzn agreement list"
  while [[ result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" | jq '.') \
   && $(echo "$result" | jq '.==[]') == "true" ]]; do
    if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): waiting on agreement (10): $result"; fi
    sleep 10
  done
  node_state=$(echo "$node_state" | jq '.pattern='"$result")
  if [ -n "${DEBUG:-}" ]; then echo "DEBUG: agreement complete: $result" ; fi

  # UPDATE CONFIGURATION
  jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" > "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"

  ## DONE w/ PATTERN
  echo "INFO: ($id): PATTERN configured" $(echo "$node_state" | jq -c '.pattern')

  ##
  ## CONFIG NETWORK
  ##

  if [[ $config_network -ne "true" ]]; then
    echo "INFO: ($id): configuring NETWORK"
    # get network
    nwid=$(echo "$conf" | jq -r '.network?')
    if [[ -z $nwid || $nwid == 'null' ]]; then
      echo "ERROR: ($id): network not specified in configuration: $conf"
      continue
    fi
    network=$(jq '.networks[]|select(.id=="'$nwid'")' "$config")
    if [[ -z "${network}" || "${network}" == "null" ]]; then
      echo "ERROR: ($id): network $nwid not found in network"
      continue
    fi
    # network for deployment
    nw_id=$(echo "$network" | jq -r '.id')
    nw_dhcp=$(echo "$network" | jq -r '.dhcp')
    nw_ssid=$(echo "$network" | jq -r '.ssid')
    nw_password=$(echo "$network" | jq -r '.password')
    # create wpa_supplicant.conf
    config_script="$TMP/wpa_supplicant.conf"
    cat "wpa_supplicant.tmpl" \
      | sed 's|%%WIFI_SSID%%|'"${nw_ssid}"'|g' \
      | sed 's|%%WIFI_PASSWORD%%|'"${nw_password}"'|g' \
      > "$config_script"
    if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): copying script ($config_script)"; fi
    scp -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$config_script" "${client_username}@${client_ipaddr}:." &> /dev/null
    if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): invoking script ($config_script:t)"; fi
    cmd='sudo mv -f '"$config_script:t"' /etc/wpa_supplicant/wpa_supplicant.conf'
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd &> /dev/null"
    result='{ "ssid": "'"${nw_ssid}"'","password":"'"${nw_password}"'"}'
    node_state=$(echo "$node_state" | jq '.network='"$result")

    ## UPDATE CONFIGURATION
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" > "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    config_network=$(jq '.nodes[]|select(.id=="'$id'").network != null' "$config")
  fi
  # sanity
  if [[ $config_network -ne "true" ]]; then
    echo "WARN: ($id): NETWORK failed"
    continue
  else
    echo "INFO: ($id): NETWORK configured" $(echo "$node_state" | jq -c '.network')
  fi

  if [ -n "${DEBUG:-}" ]; then echo "DEBUG: ($id): node state: $node_state"; fi

done

if [ -z "${DEBUG:-}" ]; then rm -fr "$TMP"; fi
exit 0
