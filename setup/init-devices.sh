#!/bin/tcsh
unsetenv DEBUG
unsetenv VERBOSE

if ( `whoami` != "root" ) then
  echo "ERROR: Please run as root, e.g. sudo $0 $argv" 
  exit 1
else
  set SSH_DIR = `echo ~${USER}/.ssh`
endif

# no glob'ing by default
set noglob

###
### default EXCHANGE URL
###

setenv HZN_EXCHANGE_URL "https://alpha.edge-fabric.com/v1"

## check for necessary tooling
if (! -e "/usr/local/bin/nmap" && ! -e "/usr/bin/nmap") then
  /bin/echo 'No nmap(8); install using brew or apt' >& /dev/stderr
  exit 1
endif

if ($HOSTTYPE == "x86_64-linux") then
  set BASE64_ENCODE='base64 -w 0'
else if ($OSTYPE == "darwin" && $VENDOR == "apple") then
  set BASE64_ENCODE='base64'
else
  echo "Cannot determine which base64 encoding arguments"
  exit 1
endif

onintr cleanup

if ($#argv > 0) then
  set config = $argv[1]
else
  set config = "horizon.json"
endif
if (! -s "$config" ) then
  echo "Cannot find configuration file"
  exit 1
endif

## DISTRIBUTION config
set HORIZON_SETUP_URL = `jq -r '.setup' "$config"`

if ($#argv > 1) then
  set net = $argv[2]
else
  set net = "192.168.1.0/24"
endif
echo "INFO: executing: $0 $config $net" >&! /dev/stderr

set TTL = 300 # seconds
set SECONDS = `date "+%s"`
set DATE = `echo $SECONDS \/ $TTL \* $TTL | bc`
set TMP = "/tmp/$0:t.$$"

# make temporary directory for working files
mkdir -p "$TMP"
if (! -d "$TMP") then
  echo "FATAL: no $TMP"
  exit 1
endif

set out = "/tmp/$0:t.$DATE.txt"
if (! -e "$out") then
  unset noglob
  rm -f "$out:h/$0:t".*.txt
  set noglob
  sudo nmap -sn -T5 "$net" >! "$out"
endif

if (! -e "$out") then
  echo 'No nmap(8) output for '"$net" >& /dev/stderr
  exit 1
endif

set macs = ( `egrep MAC "$out" | sed 's/.*: \([^ ]*\) .*/\1/'` )

echo "INFO: found $#macs devices by MAC"

###
### ITERATE OVER ALL MACS on LAN
###

foreach mac ( $macs )
  # get ipaddr
  set client_ipaddr = `egrep -B 2 "$mac" "$out" | egrep "Nmap scan" | head -1 | awk '{ print $5 }'`
  # search for device by mac
  set id = `jq -r '.nodes[]|select(.mac=="'$mac'").id' "$config"`
  if ($#id == 0) then
    if ($?VERBOSE) echo "VERBOSE: NOT FOUND; MAC: $mac; IP: $client_ipaddr"
    continue
  else
    # get ip address from nmap output file
    echo "INFO: ($id): FOUND ($id); MAC: $mac; IP $client_ipaddr"
    if (-s "${SSH_DIR}/known_hosts") then
      if ($?DEBUG) echo "DEBUG ($id): removing $client_ipaddr from $SSH_DIR/known_hosts"
      egrep -v "${client_ipaddr}" "${SSH_DIR}/known_hosts" > $TMP/known_hosts
      mv -f $TMP/known_hosts ${SSH_DIR}/known_hosts
    endif
  endif

  # find configuration which includes device
  set conf = `jq '.configurations[]|select(.nodes[].id=="'$id'")' "$config"`
  if ($#conf == 0) then
    echo "ERROR: ($id): Cannot find node configuration for device: $id"
    continue
  else
    # identify configuration
    set conf_id = ( `echo "$conf" | jq -r '.id'` )
  endif

  # find node state (cannot fail)
  set node_state = ( `jq '.nodes[]|select(.id=="'$id'")' "$config"` )

  ## TEST STATUS
  set config_keys = `echo "$conf" | jq '.public_key!=null'`
  set config_ssh = `echo "$node_state" | jq '.ssh!=null'`
  set config_security = `echo "$node_state" | jq '.ssh.device!=null'`
  set config_software = `echo "$node_state" | jq '.software!=null'`
  set config_exchange = `echo "$node_state" | jq '.exchange.node!=null'`
  set config_network = `echo "$node_state" | jq '.network!=null'`

  ## CONFIGURATION KEYS
  if ($config_keys != 'true') then
    # test for existing keys
    if (! -s "$conf_id" && ! -s "${conf_id}.pub") then
      if ($?DEBUG) echo "DEBUG: ($id): configuring KEYS for $conf_id"
      # generate new key
      ssh-keygen -t rsa -f "$conf_id" -N "" >& /dev/null
      # test for success
      if (! -s "$conf_id" || ! -s "$conf_id.pub") then
        echo "ERROR: ($id): failed to create key files for $conf_id"
        exit 1
      endif
    else
      if ($?VERBOSE) echo "VERBOSE: ($id): using existing keys $conf_id"
    endif
    # save into configuration
    set public_key = '{ "encoding": "base64", "value": "'`${BASE64_ENCODE} "${conf_id}.pub"`'" }'
    jq '(.configurations[]|select(.id=="'"$conf_id"'").public_key)|='"$public_key" "$config" >! "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    set private_key = '{ "encoding": "base64", "value": "'`${BASE64_ENCODE} "$conf_id"`'" }'
    jq '(.configurations[]|select(.id=="'$conf_id'").private_key)|='"$private_key" "$config" >! "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    set conf = `jq '.configurations[]|select(.nodes[].id=="'$id'")' "$config"`
    # update status
    set config_keys = `echo "$conf" | jq '.public_key!=null'`
  endif
  # sanity
  if ($config_keys != 'true') then
    echo "FATAL: ($id): failure to configure keys for $conf_id"
    exit
  else
    set public_key = ( `echo "$conf" | jq '.public_key'` )
    set private_key = ( `echo "$conf" | jq '.private_key'` )
    if ($?VERBOSE) echo "VERBOSE: ($id): KEYS configured: $conf_id"
  endif

  # process public key for device
  set pke = ( `echo "$public_key" | jq -r '.encoding'` )
  if ($#pke && "$pke" == "base64") then
    set public_keyfile = "$TMP/$conf_id.pub"
    if ( ! -e "$public_keyfile" ) then
      echo "$public_key" | jq -r '.value' | base64 --decode >! "$public_keyfile"
      chmod 400 "$public_keyfile"
    else
      if ($?DEBUG) echo "DEBUG: ($id): found existing keyfile: $public_keyfile"
    endif
  else
    echo "FATAL: ($id): invalid public key encoding"
    exit 1
  endif

  # process private key for device
  set pke = ( `echo "$private_key" | jq -r '.encoding'` )
  if ($#pke && "$pke" == "base64") then
    set private_keyfile = "$TMP/$conf_id"
    if ( ! -e "$private_keyfile" ) then
      echo "$private_key" | jq -r '.value' | base64 --decode >! "$private_keyfile"
      chmod 400 "$private_keyfile"
    else
      if ($?DEBUG) echo "DEBUG: ($id): found existing keyfile: $private_keyfile"
    endif
  else
    echo "FATAL: ($id): invalid private key encoding"
    exit 1
  endif

  # get configuration for identified node
  set node_conf = (  `echo "$conf" | jq '.nodes[]|select(.id=="'"$id"'")'` )
  # get default username and password for distribution associated with machine assigned to node
  set mid = `echo "$node_conf" | jq -r '.machine'`
  set did = `jq -r '.machines[]|select(.id=="'$mid'").distribution' "$config"` 
  set dist = `jq -r '.distributions[]|select(.id=="'$did'")' "$config"`
  set client_hostname = `echo "$dist" | jq -r '.client.hostname'`
  set client_username = `echo "$dist" | jq -r '.client.username'`
  set client_password = `echo "$dist" | jq -r '.client.password'`
  set client_distro = `echo "$dist" | jq '{"id":.id,"kernel_version":.kernel_version,"release_date":.release_date,"version":.version}'`

  if ($?DEBUG) echo "[DEBUG] ($id): client_hostname = $client_hostname; client_username = $client_username; client_password = $client_password"

  ## CONFIG SSH
  if ($config_ssh != "true") then
    echo "INFO: ($id): SSH attempting copy-id: $client_ipaddr"

    # edit template ssh-copy-id 
    set ssh_copy_id = "$TMP/ssh-copy-id.exp"
    cat "ssh-copy-id.tmpl" \
      | sed 's|%%CLIENT_IPADDR%%|'"${client_ipaddr}"'|g' \
      | sed 's|%%CLIENT_USERNAME%%|'"${client_username}"'|g' \
      | sed 's|%%CLIENT_PASSWORD%%|'"${client_password}"'|g' \
      | sed 's|%%PUBLIC_KEYFILE%%|'"${public_keyfile}"'|g' \
      >! "$ssh_copy_id"
    if ($?VERBOSE) echo "VERBOSE: ($id): attempting ssh-copy-id ($public_keyfile) to device $id"
    set success = ( `expect -f "$ssh_copy_id" |& egrep success | sed 's/.*success.*/success/g'` )
    if ($#success == 0) then
      echo "ERROR: ($id) SSH failed; consider re-flashing"
      continue
    endif
    if ($?DEBUG) echo "DEBUG: target $id configured with $conf_id public key"
    ## UPDATE CONFIGURATION
    set node_state = ( `echo "$node_state" | jq '.ssh.id="'"${conf_id}"'"'` )
    if ($?DEBUG) echo "DEBUG: ($id): updating configuration $config"
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" >! "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    # get new status
    set config_ssh = ( `jq '.nodes[]|select(.id=="'$id'").ssh != null' "$config"` )
  endif
  # sanity
  if ($config_ssh != "true") then
    echo "ERROR: ($id): SSH failed"
    continue
  else
    # test access
    set result = ( `ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'whoami'` )
    if ($#result == 0 || "$result" != "${client_username}") then
      echo "ERROR: ($id) SSH failed; cannot confirm identity ${client_username}; got ($result):" `echo "$node_state" | jq '.ssh'`
      continue
    endif
    echo "INFO: ($id): SSH public key configured: " `echo "$node_state" | jq -c '.ssh.id'`
  endif

  ## CONFIG SECURITY
  if ($config_security != 'true') then
    echo "INFO: ($id): SECURITY setting hostname and password"
    # get node configuration specifics
    set device = ( `echo "$node_conf" | jq -r '.device'` )
    set token = ( `echo "$node_conf" | jq -r '.token'` )
    if ($#device == 0 || $#token == 0) then
      echo "ERROR: ($id): node configuration device or token are unspecified: $node_conf"
      continue
    endif
    # create device and token script
    set config_script = "$TMP/config-ssh.sh"
    cat "config-ssh.tmpl" \
      | sed 's|%%DEVICE_NAME%%|'"${device}"'|g' \
      | sed 's|%%CLIENT_HOSTNAME%%|'"${client_hostname}"'|g' \
      | sed 's|%%DEVICE_TOKEN%%|'"${token}"'|g' \
      >! "$config_script"
    if ($?DEBUG) echo "DEBUG: ($id): copying SSH script ($config_script)"
    scp -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$config_script" "${client_username}@${client_ipaddr}:." 
    if ($?DEBUG) echo "DEBUG: ($id): invoking SSH script ($config_script:t)"
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'sudo bash '"$config_script:t"
    ## UPDATE CONFIGURATION
    set node_state = ( `echo "$node_state" | jq '.ssh={"id":"'"$conf_id"'","token":"'"${token}"'","device":"'"${device}"'"}'` )
    if ($?DEBUG) echo "DEBUG: ($id): updating configuration $config"
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" >! "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    set config_security = `echo "$node_state" | jq '.ssh.device!=null'`
  endif
  # sanity
  if ($config_security != "true") then
    echo "ERROR: ($id): SECURITY failed"
    continue
  else
    # test access
    set result = ( `ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'hostname'` )
    if ($#result == 0 || `echo "$node_state" | jq -r '.ssh.device=="'"$result"'"'` != 'true') then
      echo "ERROR: ($id) SSH failed; cannot confirm hostname: ${result}" `echo "$node_state" | jq '.ssh'`
      continue
    endif
    echo "INFO: ($id): SECURITY configured" `echo "$node_state" | jq -c '.ssh'`
  endif

  ## CONFIG SOFTWARE
  if ($config_software != "true") then
    echo "INFO: ($id): SOFTWARE installing ${HORIZON_SETUP_URL}"
    # install software
    set result = ( `ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'wget -qO - '"${HORIZON_SETUP_URL}"' | sudo bash 2> log' | jq '.'` )
    if ($#result <= 1) then
      echo "ERROR: ($id): SOFTWARE failed; result = $result"
      continue
    endif
    # add distribution information
    set result = ( `echo "$result" | jq '.|.distribution='"${client_distro}"` )
    if ($?DEBUG) echo "DEBUG: ($id): result = $result"
    # update node state
    set node_state = ( `echo "$node_state" | jq '.|.software='"$result"` )
    if ($?DEBUG) echo "DEBUG: ($id): node state = $node_state"
    # update configuration file
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" >! "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    # update software configuration
    set config_software = ( `jq '.nodes[]|select(.id=="'$id'").software != null' "$config"` )
  endif
  # sanity
  if ($config_software != "true") then
    echo "WARN: ($id): SOFTWARE failed"
    continue
  else
    # test access
    set result = ( `ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'command -v hzn'` )
    if ($#result == 0 || `echo "$node_state" | jq -r '.software.command=="'$result'"'` != 'true') then
      echo "ERROR: ($id) SOFTWARE failed; cannot confirm command" `echo "$node_state" | jq '.software'`
      continue
    endif
    echo "INFO: ($id): SOFTWARE configured" `echo "$node_state" | jq -c '.software'`
  endif

# hzn exchange node list 
# {
#   "cgiroua@us.ibm.com/dcm-macbook": {
#     "lastHeartbeat": "2018-11-20T01:02:58.676Z[UTC]",
#     "msgEndPoint": "",
#     "name": "dcm-macbook",
#     "owner": "cgiroua@us.ibm.com/dcmartin@us.ibm.com",
#     "pattern": "",
#     "publicKey": "",
#     "registeredServices": [],
#     "softwareVersions": {},
#     "token": "********"
#   }
# }

# hzn exchange status
# {
#   "dbSchemaVersion": 13,
#   "msg": "Exchange server operating normally",
#   "numberOfAgbotAgreements": 1,
#   "numberOfAgbotMsgs": 0,
#   "numberOfAgbots": 2,
#   "numberOfNodeAgreements": 2,
#   "numberOfNodeMsgs": 0,
#   "numberOfNodes": 9,
#   "numberOfUsers": 21
# }

  ## CONFIG EXCHANGE
  if ($config_exchange != "true") then
    echo "INFO: ($id): configuring EXCHANGE"
    # get exchange
    set ex_id = ( `echo "$conf" | jq -r '.exchange'` )
    if ($#ex_id == 0 || "$ex_id" == "null") then
      echo "ERROR: ($id): exchange not specified in configuration: $conf"
      continue
    endif
    set exchange = ( `jq '.exchanges[]|select(.id=="'$ex_id'")' "$config"` )
    if ($#exchange <= 1) then
      echo "ERROR: ($id): exchange $ex_id not found in exchanges"
      continue
    endif
    # check URL for exchange
    set ex_url = ( `echo "$exchange" | jq -r '.url'` )
    if ($#ex_url == 0 || "$ex_url" == "null") then
      set ex_url = "$HZN_EXCHANGE_URL"
      echo "WARN: exchange $ex_id does not have URL specified; using default: $ex_url"
    endif

    # update node state
    set node_state = ( `echo "$node_state" | jq '.exchange.id="'"$ex_id"'"|.exchange.url="'"$ex_url"'"'` )
    if ($?DEBUG) echo "DEBUG: ($id): node state:" `echo "$node_state" | jq -c '.'`

    # get exchange specifics
    set ex_org = ( `echo "$exchange" | jq -r '.org'` )
    set ex_username = ( `echo "$exchange" | jq -r '.username'` )
    set ex_password = ( `echo "$exchange" | jq -r '.password'` )
    set ex_device = ( `echo "$node_state" | jq -r '.ssh.device'` )
    set ex_token = ( `echo "$node_state" | jq -r '.ssh.token'` )

    # force specification of exchange URL
    set cmd = "sudo sed -i 's|HZN_EXCHANGE_URL=.*|HZN_EXCHANGE_URL=${ex_url}|' /etc/default/horizon"
    if ($?VERBOSE) echo "VERBOSE: ($id): executing remote command: $cmd"
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null"
    set cmd = "sudo systemctl restart horizon || false"
    if ($?VERBOSE) echo "VERBOSE: ($id): executing remote command: $cmd"
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null"
    # test for failure status
    if ($status != 0) then
      echo "ERROR: ($id): EXCHANGE failed; $cmd"
      continue
    endif

    # create node in exchange (always returns nothing)
    set cmd = "hzn exchange node create -o ${ex_org} -u ${ex_username}:${ex_password} -n ${ex_device}:${ex_token}"
    if ($?VERBOSE) echo "VERBOSE: ($id): executing remote command: $cmd"
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null"
    set result = $status
    while ( $result != 0 )
	if ($?DEBUG) echo "WARN: ($id): failed command ($result): $cmd"
        ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null"
        set result = $status
    end

    # get exchange node information
    set cmd = "hzn exchange node list -o ${ex_org} -u ${ex_username}:${ex_password} ${ex_device}"
    if ($?VERBOSE) echo "VERBOSE: ($id): executing remote command: $cmd"
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" >! "$TMP/henl.json"
    set result = $status
    while ($result != 0 || ! -s "$TMP/henl.json" )
      echo "WARN: ($id): EXCHANGE retry; $cmd"
      ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" >! "$TMP/henl.json"
      set result = $status
    end
    if ($?VERBOSE) echo "VERBOSE: ($id): result $TMP/henl.json" `jq -c '.' "$TMP/henl.json"`
    # update node state
    set result = `sed 's/{}/null/g' "$TMP/henl.json" | jq '.'`
    set node_state = ( `echo "$node_state" | jq '.exchange.node='"$result"` )
    if ($?VERBOSE) echo "VERBOSE: ($id): node state:" `echo "$node_state" | jq -c '.'`

    # get exchange status
    set cmd = "hzn exchange status -o $ex_org -u ${ex_username}:${ex_password}"
    if ($?VERBOSE) echo "VERBOSE: ($id): executing remote command: $cmd"
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" >! "$TMP/hes.json"
    set result = $status
    while ($result != 0 || ! -s "$TMP/hes.json")
      echo "WARN: ($id): EXCHANGE retry; $cmd"
      ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" >! "$TMP/hes.json"
      set result = $status
    end
    if ($?VERBOSE) echo "VERBOSE: ($id): result $TMP/hes.json" `jq -c '.' "$TMP/hes.json"`
    # update node state
    set result = `sed 's/{}/null/g' "$TMP/hes.json" | jq '.'`
    set node_state = ( `echo "$node_state" | jq '.exchange.status='"$result"` )
    if ($?VERBOSE) echo "VERBOSE: ($id): node state:" `echo "$node_state" | jq -c '.'`

    ## UPDATE CONFIGURATION
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" >! "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    set config_exchange = ( `jq '.nodes[]|select(.id=="'$id'").exchange.node != null' "$config"` )
  endif
  # sanity
  if ($config_exchange != "true") then
    echo "WARN: ($id): EXCHANGE failed"
    continue
  else
    echo "INFO: ($id): EXCHANGE configured" `echo "$node_state" | jq -c '.exchange'`
  endif

  ##
  ## CONFIG PATTERN (or reconfigure)
  ##

  echo "INFO: ($id): configuring PATTERN"
  # get pattern
  set ptid = ( `echo "$conf" | jq -r '.pattern?'` )
  if ($#ptid == 0 || $ptid == 'null') then
    echo "ERROR: ($id): pattern not specified in configuration: $conf"
    continue
  endif
  if ($?DEBUG) echo "DEBUG: ($id): pattern identifier $ptid"
  set pattern = ( `jq '.patterns[]|select(.id=="'$ptid'")' "$config"` )
  if ($#pattern <= 1) then
    echo "ERROR: ($id): pattern $ptid not found in patterns"
    continue
  endif

  # pattern for registration
  set pt_id = ( `echo "$pattern" | jq -r '.id'` )
  set pt_org = ( `echo "$pattern" | jq -r '.org'` )
  set pt_url = ( `echo "$pattern" | jq -r '.url'` )
  set pt_vars = ( `echo "$conf" | jq '.variables'` )
  
  # get node specifics
  set ex_id = `echo "$node_state" | jq -r '.exchange.id'`
  set ex_device = ( `echo "$node_state" | jq -r '.ssh.device'` )
  set ex_token = ( `echo "$node_state" | jq -r '.ssh.token'` )
  set ex_org = `jq -r '.exchanges[]|select(.id=="'"$ex_id"'").org' "$config"`
  set ex_username = `jq -r '.exchanges[]|select(.id=="'"$ex_id"'").username' "$config"`
  set ex_password = `jq -r '.exchanges[]|select(.id=="'"$ex_id"'").password' "$config"`

  # get node status
  set cmd = 'hzn node list'
  if ($?VERBOSE) echo "VERBOSE: ($id): executing remote command: $cmd"
  set result = `ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" | jq '.'`
  set node_state = ( `echo "$node_state" | jq '.node='"$result"` )

  # test if node is configured with pattern
  set node_id = `echo "$node_state" | jq -r '.node.id'`
  set node_status = `echo "$node_state" | jq -r '.node.configstate.state'`
  set node_pattern = `echo "$node_state" | jq -r '.node.pattern'`

  # unregister node iff
  if (${node_id} == ${ex_device} && $node_pattern == ${pt_org}/${pt_id} && ( $node_status == "configured" || $node_status == "configuring" )) then
    if ($?DEBUG) echo "INFO: node ${node_id} is ${node_status} with pattern ${node_pattern}"
  else if ($node_status == "unconfiguring") then
    if ($?DEBUG) echo "ERROR: ($id): node ${node_id} (aka ${ex_device}) is unconfiguring; consider reflashing (or remove, purge, update, prune, and reboot)"
    continue
  else if (${node_id} != ${ex_device} || $node_status != "unconfigured") then
    if ($?DEBUG) echo "DEBUG: ($id): unregistering node ${node_id}"
    # unregister client
    set cmd = 'hzn unregister -f'
    if ($?DEBUG) echo "DEBUG: ($id): executing remote command: $cmd"
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null"

    # POLL client for node list information; wait until device identifier matches requested
    set cmd = 'hzn node list'
    if ($?DEBUG) echo "DEBUG: ($id): executing remote command: $cmd"
    set result = `ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" | jq '.'`
    while ( `echo "$result" | jq '.configstate.state=="unconfigured"'` == false )
      if ($?DEBUG) echo "DEBUG: ($id): waiting on unregistration (10): $result"
      sleep 10
      if ($?DEBUG) echo "DEBUG: ($id): executing remote command: $cmd"
      set result = `ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" | jq '.'`
    end
    set node_state = ( `echo "$node_state" | jq '.node='"$result"` )
  endif

  # register node iff
  if (`echo "$node_state" | jq '.node.configstate.state=="unconfigured"'` == true) then
    echo "INFO: registering node" `echo "$node_state" | jq -c '.'`
    # create pattern registration file
    set input = "$TMP/input.json"
    echo '{"services": [{"org": "'"${pt_org}"'","url": "'"${pt_url}"'","versionRange": "[0.0.0,INFINITY)","variables": {' > "${input}"
    # process all variables 
    set pvs = `echo "${pt_vars}" | jq -r '.[].key'`
    @ i = 0
    foreach pv ( ${pvs} )
      set value = `echo "${pt_vars}" | jq -r '.[]|select(.key=="'"${pv}"'").value'`
      if ($i) echo ',' >> "${input}"
      echo '"'"${pv}"'":"'"${value}"'"' >> "${input}"
      @ i++
    end
    echo '}}]}' >> "${input}"
    if ($?DEBUG) echo "DEBUG: ($id): node ${ex_device} pattern ${pt_org}/${pt_id}: " `jq -c "${input}"`

    # copy pattern registration file to client
    scp -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "${input}" "${client_username}@${client_ipaddr}:." 
    # perform registration
    set cmd = "hzn register ${ex_org} -u ${ex_username}:${ex_password} ${pt_org}/${pt_id} -f ${input:t} -n ${ex_device}:${ex_token}"
    if ($?DEBUG) echo "DEBUG: ($id): registering with command: $cmd"
    set result = ( `ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "${cmd} 2> /dev/null"` )
  endif

  # POLL client for node list information; wait for configured state
  set cmd = "hzn node list"
  set result = `ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" | jq '.'`
  while ( $#result && `echo "$result" | jq '.configstate.state=="configured"'` == false)
    if ($?DEBUG) echo "DEBUG: ($id): waiting on configuration (10): $result"
    sleep 10
    set result = `ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" | jq '.'`
  end
  if ($#result == 0) then
    echo "ERROR: failed to execute: $cmd"
    continue
  endif
  set node_state = ( `echo "$node_state" | jq '.node='"$result"` )
  if ($?DEBUG) echo "DEBUG: ($id): node is configured"

  # POLL client for agreementlist information; wait until agreement exists
  set cmd = "hzn agreement list"
  set result = `ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" | jq '.'`
  while ( $#result <= 1) 
    if ($?DEBUG) echo "DEBUG: ($id): waiting on agreement (10): $result"
    sleep 10
    set result = `ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" | jq '.'`
  end
  set node_state = ( `echo "$node_state" | jq '.pattern='"$result"` )
  if ($?DEBUG) echo "DEBUG: agreement complete: $result" 

  # UPDATE CONFIGURATION
  jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" >! "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"

  ## DONE w/ PATTERN
  echo "INFO: ($id): PATTERN configured" `echo "$node_state" | jq -c '.pattern'`

  ##
  ## CONFIG NETWORK
  ##

  if ($config_network != "true") then
    echo "INFO: ($id): configuring NETWORK"
    # get network
    set nwid = ( `echo "$conf" | jq -r '.network?'` )
    if ($#nwid == 0 || $nwid == 'null') then
      echo "ERROR: ($id): network not specified in configuration: $conf"
      continue
    endif
    set network = ( `jq '.networks[]|select(.id=="'$nwid'")' "$config"` )
    if ($#network <= 1) then
      echo "ERROR: ($id): network $nwid not found in network"
      continue
    endif
    # network for deployment
    set nw_id = ( `echo "$network" | jq -r '.id'` )
    set nw_dhcp = ( `echo "$network" | jq -r '.dhcp'` )
    set nw_ssid = ( `echo "$network" | jq -r '.ssid'` )
    set nw_password = ( `echo "$network" | jq -r '.password'` )
    # create wpa_supplicant.conf
    set config_script = "$TMP/wpa_supplicant.conf"
    cat "wpa_supplicant.tmpl" \
      | sed 's|%%WIFI_SSID%%|'"${nw_ssid}"'|g' \
      | sed 's|%%WIFI_PASSWORD%%|'"${nw_password}"'|g' \
      >! "$config_script"
    if ($?DEBUG) echo "DEBUG: ($id): copying script ($config_script)"
    scp -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$config_script" "${client_username}@${client_ipaddr}:." 
    if ($?DEBUG) echo "DEBUG: ($id): invoking script ($config_script:t)"
    set cmd = 'sudo mv -f '"$config_script:t"' /etc/wpa_supplicant/wpa_supplicant.conf'
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null"
    set result = '{ "ssid": "'"${nw_ssid}"'","password":"'"${nw_password}"'"}'
    set node_state = ( `echo "$node_state" | jq '.network='"$result"` )

    ## UPDATE CONFIGURATION
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" >! "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    set config_network = ( `jq '.nodes[]|select(.id=="'$id'").network != null' "$config"` )
  endif
  # sanity
  if ($config_network != "true") then
    echo "WARN: ($id): NETWORK failed"
    continue
  else
    echo "INFO: ($id): NETWORK configured" `echo "$node_state" | jq -c '.network'`
  endif

  if ($?DEBUG) echo "DEBUG: ($id): node state: $node_state"

end

done:
if ($?DEBUG == 0) rm -fr "$TMP"
exit 0

cleanup:
if ($?DEBUG == 0) rm -fr "$TMP"
exit 1
