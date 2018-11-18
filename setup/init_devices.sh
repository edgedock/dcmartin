#!/bin/tcsh

setenv DEBUG

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

## default login and password for target device image
set CLIENT_USERNAME = "pi"
set CLIENT_PASSWORD = "raspberry"

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

if ($#argv > 1) then
  set net = $argv[2]
else
  set net = "192.168.1.0/24"
endif
echo "$0 - using net ($net)" >&! /dev/stderr

set TTL = 60 # seconds
set SECONDS = `date "+%s"`
set DATE = `echo $SECONDS \/ $TTL \* $TTL | bc`
set TMP = "/tmp/$0:t.$$"
mkdir -p "$TMP"

set out = "/tmp/$0:t.$DATE.txt"
if (! -e "$out") then
  rm -fr "$out:r:r".*.txt
  /usr/bin/sudo nmap -sn -T5 "$net" >! "$out"
endif

if (! -e "$out") then
  echo 'No nmap(8) output for '"$net" >& /dev/stderr
  exit 1
endif

set macs = ( `egrep MAC "$out" | sed 's/.*: \([^ ]*\) .*/\1/'` )

if ($?DEBUG) echo "DEBUG: found $#macs devices by MAC"

foreach mac ( $macs )
  unset id device token pattern_org pattern_url ex_org ex_url

  # get ipaddr
  set client_ipaddr = `egrep -B 2 "$mac" "$out" | egrep "Nmap scan" | awk '{ print $5 }'`
  # search for device by mac
  set id = `jq -r '.nodes[]|select(.mac=="'$mac'").id' "$config"`
  if ($#id == 0) then
    if ($?DEBUG) echo "DEBUG: NOT FOUND; MAC: $mac; IP: $client_ipaddr"
    continue
  else
    # get ip address from nmap output file
    if ($?DEBUG) echo "DEBUG: FOUND ($id); MAC: $mac; IP $client_ipaddr"
  endif

  # find configuration which includes device
  set conf = `jq '.configurations[]|select(.nodes[].id=="'$id'")' "$config"`
  if ($#conf == 0) then
    echo "WARN: Cannot find node configuration for device: $id"
    continue
  else
    # identify configuration
    set conf_id = ( `echo "$conf" | jq -r '.id'` )
  endif

  # get configuration for identified node
  set node_conf = (  `echo "$conf" | jq '.nodes[]|select(.id=="'"$id"'")'` )
  # find node state (cannot fail)
  set node_state = ( `jq '.nodes[]|select(.id=="'$id'")' "$config"` )

  ## TEST STATUS
  set config_keys = `echo "$conf" | jq '.public_key!=null'`
  set config_ssh = `echo "$node_state" | jq '.ssh!=null'`
  set config_security = `echo "$node_state" | jq '.ssh.device!=null'`
  set config_software = `echo "$node_state" | jq '.software!=null'`
  set config_exchange = `echo "$node_state" | jq '.exchange!=null'`
  set config_pattern = `echo "$node_state" | jq '.pattern!=null'`
  set config_network = `echo "$node_state" | jq '.network!=null'`

  if ($?DEBUG) echo "DEBUG: KEYS $config_keys SSH $config_ssh SOFTWARE $config_software EXCHANGE $config_exchange PATTERN $config_pattern NETWORK $config_network"

  ## CONFIGURATION KEYS
  if ($config_keys == 'true') then
    set public_key = ( `echo "$conf" | jq '.public_key'` )
    set private_key = ( `echo "$conf" | jq '.private_key'` )
    echo "INFO: KEYS configured: $conf_id"
  else
    echo "INFO: configuring KEYS for $conf_id"
    # generate new key
    ssh-keygen -t rsa -f "$conf_id" -N "" >& /dev/null
    # test for success
    if (! -s "$conf_id" || ! -s "$conf_id.pub") then
      echo "ERROR: failed to create key files for $conf_id"
      exit 1
    endif
    set public_key = '{ "encoding": "base64", "value": "'`${BASE64_ENCODE} "${conf_id}.pub"`'" }'
    jq '(.configurations[]|select(.id=="'"$conf_id"'").public_key)|='"$public_key" "$config" >! "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    set private_key = '{ "encoding": "base64", "value": "'`${BASE64_ENCODE} "$conf_id"`'" }'
    jq '(.configurations[]|select(.id=="'$conf_id'").private_key)|='"$private_key" "$config" >! "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    set conf = `jq '.configurations[]|select(.nodes[].id=="'$id'")' "$config"`
    # cleanup
    rm -f "$conf_id" "${conf_id}.pub"
    # update status
    set config_keys = `echo "$conf" | jq '.public_key!=null'`
  endif
  # sanity
  if ($config_keys != 'true') then
    echo "WARN: failure to configure keys for $conf_id"
    continue
  endif

  # process public key for device
  set pke = ( `echo "$public_key" | jq -r '.encoding'` )
  if ($#pke && "$pke" == "base64") then
    set public_keyfile = "$TMP/$conf_id.pub"
    echo "$public_key" | jq -r '.value' | base64 --decode >! "$public_keyfile"
    chmod 400 "$public_keyfile"
  else
    echo "ERROR: invalid public key encoding"
    continue
  endif

  # process private key for device
  set pke = ( `echo "$private_key" | jq -r '.encoding'` )
  if ($#pke && "$pke" == "base64") then
    set private_keyfile = "$TMP/$conf_id"
    echo "$private_key" | jq -r '.value' | base64 --decode >! "$private_keyfile"
    chmod 400 "$private_keyfile"
  else
    echo "ERROR: invalid private key encoding"
    continue
  endif

  ## CONFIG SSH
  if ($config_ssh == "true") then
    echo "INFO: ($id): SSH configured" `echo "$node_state" | jq -c '.ssh'`
  else
    echo "INFO: ($id): configuring SSH"
    # perform ssh-copy-id using distribution default username and password
    set ssh_copy_id = "$TMP/ssh-copy-id.exp"
    cat "ssh-copy-id.tmpl" \
      | sed 's|%%CLIENT_IPADDR%%|'"${client_ipaddr}"'|g' \
      | sed 's|%%CLIENT_USERNAME%%|'"${CLIENT_USERNAME}"'|g' \
      | sed 's|%%CLIENT_PASSWORD%%|'"${CLIENT_PASSWORD}"'|g' \
      | sed 's|%%PUBLIC_KEYFILE%%|'"${public_keyfile}"'|g' \
      >! "$ssh_copy_id"
    if ($?DEBUG) echo "DEBUG: attempting ssh-copy-id ($public_keyfile) to device $id"
    set failed = ( `expect -f "$ssh_copy_id" |& egrep failure | sed 's/.*failure.*/failure/g'` )
    if ($#failed) then
      echo "INFO: target $id did not accept ${CLIENT_USERNAME}:${CLIENT_PASSWORD}; consider re-flashing"
      continue;
    endif
    echo "INFO: target $id accepted public key for configuration $conf_id"
    ## UPDATE CONFIGURATION
    set node_state = ( `jq '.nodes[]|select(.id=="'$id'")|.ssh={"id":"'"${conf_id}"'"}' "$config"` )
    if ($?DEBUG) echo "DEBUG: updating configuration $config"
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" >! "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    rm -f "$ssh_copy_id"
    rm -f "$public_keyfile"
    # get new status
    set config_ssh = ( `jq '.nodes[]|select(.id=="'$id'").ssh != null' "$config"` )
  endif
  # sanity
  if ($config_ssh != "true") then
    echo "WARN: ($id): SSH failed"
    continue
  endif

  ## CONFIG SECURITY
  if ($config_security == 'true') then
    echo "INFO: ($id): SECURITY configured" `echo "$node_state" | jq -c '.ssh'`
  else 
    echo "INFO: ($id): configuring SECURITY"
    # get node configuration specifics
    set device = ( `echo "$node_conf" | jq -r '.device'` )
    set token = ( `echo "$node_conf" | jq -r '.token'` )
    if ($#device == 0 || $#token == 0) then
      echo "WARN: ($id): node configuration device or token are unspecified: $node_conf"
      continue
    endif
    # create device and token script
    set config_script = "$TMP/config-ssh.sh"
    cat "config-ssh.tmpl" \
      | sed 's|%%DEVICE_NAME%%|'"${device}"'|g' \
      | sed 's|%%DEVICE_TOKEN%%|'"${token}"'|g' \
      >! "$config_script"
    if ($?DEBUG) echo "DEBUG: copying SSH script ($config_script)"
    scp -o "StrictHostKeyChecking false" -i "$private_keyfile" "$config_script" "${CLIENT_USERNAME}@${client_ipaddr}:." 
    if ($?DEBUG) echo "DEBUG: invoking SSH script ($config_script:t)"
    ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'sudo bash '"$config_script:t"
    ## UPDATE CONFIGURATION
    set node_state = ( `jq '.nodes[]|select(.id=="'$id'")|.ssh={"id":"'"$conf_id"'","token":"'"${token}"'","device":"'"${device}"'"}' "$config"` )
    if ($?DEBUG) echo "DEBUG: updating configuration $config"
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" >! "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    set config_security = `echo "$node_state" | jq '.ssh.device!=null'`
  endif
  # sanity
  if ($config_security != "true") then
    echo "WARN: ($id): SECURITY failed"
    continue
  endif

  ## CONFIG SOFTWARE
  if ($config_software == "true") then
    echo "INFO: ($id): SOFTWARE configured" `echo "$node_state" | jq -c '.software'`
  else
    echo "INFO: ($id): configuring SOFTWARE"
    # install software
    set result = ( `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'wget -qO - ibm.biz/horizon-setup | sudo bash -s' | jq '.'` )
    if ($#result) then
      # test for successful installation
      set hzn = `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'command -v hzn'`
      if ($#hzn == 0) then
	echo "ERROR: ($id): SOFTWARE failed"
        continue
      endif
      set results = ( `echo "$result" | jq '.|.command="'"$hzn"'"'` )
      set node_state = ( `jq '.nodes[]|select(.id=="'$id'")|.software='"$result" "$config"` )
      echo "$node_state"
      jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" >! "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    endif
    set config_software = ( `jq '.nodes[]|select(.id=="'$id'").software != null' "$config"` )
  endif
  # sanity
  if ($config_software != "true") then
    echo "WARN: ($id): SOFTWARE failed"
    continue
  endif

  ## CONFIG EXCHANGE
  if ($config_exchange == "true") then
    echo "INFO: ($id): EXCHANGE configured" `echo "$node_state" | jq -c '.exchange'`
  else
    # get exchange
    set exid = ( `echo "$conf" | jq -r '.exchange'` )
    if ($#exid == 0 || "$exid" == "null") then
      echo "ERROR: exchange not specified in configuration: $conf"
      continue
    endif
    set exchange = ( `jq '.exchanges[]|select(.id=="'$exid'")' "$config"` )
    if ($#exchange <= 1) then
      echo "ERROR: exchange $exid not found in exchanges"
      continue
    endif
    # credentials for exchange
    set ex_org = ( `echo "$exchange" | jq -r '.org'` )
    set ex_url = ( `echo "$exchange" | jq -r '.url'` )
    set ex_username = ( `echo "$exchange" | jq -r '.username'` )
    set ex_password = ( `echo "$exchange" | jq -r '.password'` )
    # check status
    set cmd = "hzn exchange status -o $ex_org -u ${ex_username}:${ex_password}"
    set result = `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" "$cmd"`
    if ($#result == 0) then
      echo "WARN: ($id): EXCHANGE failed; status not received"
      set result = 'null'
    endif
    set node_state = ( `jq '.nodes[]|select(.id=="'$id'")|.exchange.status='"$result" "$config"` )
    # check node list
    set result = `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'hzn node list'`
    if ($#result == 0) then
      echo "WARN: ($id): EXCHANGE failed; node list not received"
      set result = 'null'
    endif
    set node_state = ( `jq '.nodes[]|select(.id=="'$id'")|.exchange.node='"$result" "$config"` )
    # update node
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" >! "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    set config_exchange = ( `jq '.nodes[]|select(.id=="'$id'").exchange != null' "$config"` )
  endif
  # sanity
  if ($config_exchange != "true") then
    echo "WARN: ($id): EXCHANGE failed"
    continue
  endif

  ## CONFIG PATTERN
  if ($config_pattern == "true") then
    echo "INFO: ($id): PATTERN configured" `echo "$node_state" | jq -c '.pattern'`
  else 
    # get pattern
    set ptid = ( `echo "$conf" | jq -r '.pattern?'` )
    if ($#ptid == 0 || $ptid == 'null') then
      echo "ERROR: pattern not specified in configuration: $conf"
      continue
    endif
    set pattern = ( `jq '.patterns[]|select(.id=="'$ptid'")' "$config"` )
    if ($#pattern <= 1) then
      echo "ERROR: pattern $ptid not found in patterns"
      continue
    endif
    # pattern for registration
    set pt_id = ( `echo "$pattern" | jq -r '.id'` )
    set pt_org = ( `echo "$pattern" | jq -r '.org'` )
    set pt_url = ( `echo "$pattern" | jq -r '.url'` )
    set pt_vars = ( `echo "$conf" | jq '.variables'` )
    
    # test if node is identified in exchange
    set device = `echo "$node_state" | jq -r '.ssh.device'`
    set found = `echo "$node_state" | jq '.id=="'"$device"'")'`
    if ($found == "false") then
      echo "WARN: ($id): node not found in exchange"
    endif 

    # test if node is unconfigured in exchange
    set unconfigured = `echo "$node_state" | jq '.node.configstate.state?=="unconfigured"'`
    if ($unconfigured != 'true') then
      echo "ERROR: ($id): PATTERN failed; node is not in unconfigured state"
      continue
    endif

    # perform registration
    set input = "$TMP/input.json"
    echo '{"services": [{"org": "'"${pt_org}"'","url": "'"${pt_url}"'","versionRange": "[0.0.0,INFINITY)","variables": {' >> "${input}"
    set pvs = `echo "${pt_vars}" | jq -r '.[].env'`
    foreach pv in ${pvs}
      set value = `echo "${pt_vars}" | jq -r '.[]|select(.env="'"${pv}"'").value'`
      echo '"'"${pv}"':"'"${value}"'"' >> "${input}"
    end
    echo '}}]}' >> "${input}"
    # copy input to client
    scp -o "StrictHostKeyChecking false" -i "$private_keyfile" "${input}" "${CLIENT_USERNAME}@${client_ipaddr}:." 
    # set command to execute on client
    set cmd = "hzn register -n ${ex_id}:${ex_token} ${ex_org} ${pt_org}/${pt_id} -F ${input:t}"
    if ($?DEBUG) echo "DEBUG: registering with command: $cmd"
    set result = ( `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" "${cmd}"` )

    set result = `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'hzn node list' | jq '.'`
    while ( `echo "$result" | jq '.id?=="'"$device"'"'` == 'false' )
      if ($?DEBUG) echo "DEBUG: Waiting on registration (60)"
      sleep 60
      set result = `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'hzn node list' | jq '.'`
    end
    echo "INFO: Registration complete for ${ex_org}/${device}"

    set result = `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'hzn agreement list' | jq '.'`
    while ( `echo "$result" | jq '.?==[]'` == 'false' ) then
        if ($?DEBUG) echo "DEBUG: Waiting on agreement (60)"
        sleep 60
        set result = `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'hzn agreement list' | jq '.'`
    end
    echo "INFO: Agreement complete: $result" 

    if ($#result <= 1) then
      echo "ERROR: PATTERN failed; result: $result"
      continue"
    endif
    set node_state = ( `jq '.nodes[]|select(.id=="'$id'")|.pattern='"$result" "$config"` )
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" >! "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    set config_pattern = ( `jq '.nodes[]|select(.id=="'$id'").pattern != null' "$config"` )
  endif

end

done:
rm -fr "$TMP"
exit 0

cleanup:
rm -fr "$TMP"
exit 1
