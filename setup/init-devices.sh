#!/bin/tcsh

setenv DEBUG
unsetenv VERBOSE

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

if ($#argv > 1) then
  set net = $argv[2]
else
  set net = "192.168.1.0/24"
endif
echo "INFO: executing $0 $config $net" >&! /dev/stderr

set TTL = 14400 # seconds
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

## DISTRIBUTION config

set CLIENT_USERNAME = `jq -r '.distribution.client.username' "$config"`
set CLIENT_PASSWORD = `jq -r '.distribution.client.password' "$config"`
set CLIENT_HOSTNAME = `jq -r '.distribution.client.hostname' "$config"`
set CLIENT_DISTRIBUTION = `jq '.distribution|{"id":.id,"kernel_version":.kernel_version,"release_date":.release_date,"version":.version}' "$config"`

###
### ITERATE OVER ALL MACS on LAN
###

foreach mac ( $macs )
  # get ipaddr
  set client_ipaddr = `egrep -B 2 "$mac" "$out" | egrep "Nmap scan" | awk '{ print $5 }'`
  # search for device by mac
  set id = `jq -r '.nodes[]|select(.mac=="'$mac'").id' "$config"`
  if ($#id == 0) then
    if ($?VERBOSE) echo "VERBOSE: ($id): NOT FOUND; MAC: $mac; IP: $client_ipaddr"
    continue
  else
    # get ip address from nmap output file
    if ($?DEBUG) echo "DEBUG: ($id): FOUND ($id); MAC: $mac; IP $client_ipaddr"
  endif

  # find configuration which includes device
  set conf = `jq '.configurations[]|select(.nodes[].id=="'$id'")' "$config"`
  if ($#conf == 0) then
    echo "WARN: ($id): Cannot find node configuration for device: $id"
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

  ## CONFIGURATION KEYS
  if ($config_keys != 'true') then
    if ($?DEBUG) echo "DEBUG: ($id): configuring KEYS for $conf_id"
    # generate new key
    ssh-keygen -t rsa -f "$conf_id" -N "" >& /dev/null
    # test for success
    if (! -s "$conf_id" || ! -s "$conf_id.pub") then
      echo "ERROR: ($id): failed to create key files for $conf_id"
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
    echo "WARN: ($id): failure to configure keys for $conf_id"
    continue
  else
    set public_key = ( `echo "$conf" | jq '.public_key'` )
    set private_key = ( `echo "$conf" | jq '.private_key'` )
    if ($?DEBUG) echo "DEBUG: ($id): KEYS configured: $conf_id"
  endif

  # process public key for device
  set pke = ( `echo "$public_key" | jq -r '.encoding'` )
  if ($#pke && "$pke" == "base64") then
    set public_keyfile = "$TMP/$conf_id.pub"
    echo "$public_key" | jq -r '.value' | base64 --decode >! "$public_keyfile"
    chmod 400 "$public_keyfile"
  else
    echo "FATAL: ($id): invalid public key encoding"
    exit 1
  endif

  # process private key for device
  set pke = ( `echo "$private_key" | jq -r '.encoding'` )
  if ($#pke && "$pke" == "base64") then
    set private_keyfile = "$TMP/$conf_id"
    echo "$private_key" | jq -r '.value' | base64 --decode >! "$private_keyfile"
    chmod 400 "$private_keyfile"
  else
    echo "FATAL: ($id): invalid private key encoding"
    exit 1
  endif

  ## CONFIG SSH
  if ($config_ssh != "true") then
    echo "INFO: ($id): configuring SSH"
    # perform ssh-copy-id using distribution default username and password
    set ssh_copy_id = "$TMP/ssh-copy-id.exp"
    cat "ssh-copy-id.tmpl" \
      | sed 's|%%CLIENT_IPADDR%%|'"${client_ipaddr}"'|g' \
      | sed 's|%%CLIENT_USERNAME%%|'"${CLIENT_USERNAME}"'|g' \
      | sed 's|%%CLIENT_PASSWORD%%|'"${CLIENT_PASSWORD}"'|g' \
      | sed 's|%%PUBLIC_KEYFILE%%|'"${public_keyfile}"'|g' \
      >! "$ssh_copy_id"
    if ($?DEBUG) echo "DEBUG: ($id): attempting ssh-copy-id ($public_keyfile) to device $id"
    set failed = ( `expect -f "$ssh_copy_id" |& egrep failure | sed 's/.*failure.*/failure/g'` )
    if ($#failed) then
      echo "WARN: ($id) SSH failed; consider re-flashing"
      continue;
    endif
    echo "INFO: target $id accepted public key for configuration $conf_id"
    ## UPDATE CONFIGURATION
    set node_state = ( `jq '.nodes[]|select(.id=="'$id'")|.ssh={"id":"'"${conf_id}"'"}' "$config"` )
    if ($?DEBUG) echo "DEBUG: ($id): updating configuration $config"
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
  else
    echo "INFO: ($id): SSH configured" `echo "$node_state" | jq '.ssh'`
  endif

  ## CONFIG SECURITY
  if ($config_security != 'true') then
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
      | sed 's|%%CLIENT_HOSTNAME%%|'"${CLIENT_HOSTNAME}"'|g' \
      | sed 's|%%DEVICE_TOKEN%%|'"${token}"'|g' \
      >! "$config_script"
    if ($?DEBUG) echo "DEBUG: ($id): copying SSH script ($config_script)"
    scp -o "StrictHostKeyChecking false" -i "$private_keyfile" "$config_script" "${CLIENT_USERNAME}@${client_ipaddr}:." 
    if ($?DEBUG) echo "DEBUG: ($id): invoking SSH script ($config_script:t)"
    ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'sudo bash '"$config_script:t"
    ## UPDATE CONFIGURATION
    set node_state = ( `jq '.nodes[]|select(.id=="'$id'")|.ssh={"id":"'"$conf_id"'","token":"'"${token}"'","device":"'"${device}"'"}' "$config"` )
    if ($?DEBUG) echo "DEBUG: ($id): updating configuration $config"
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" >! "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    set config_security = `echo "$node_state" | jq '.ssh.device!=null'`
  endif
  # sanity
  if ($config_security != "true") then
    echo "WARN: ($id): SECURITY failed"
    continue
  else
    set ssh = `echo "$node_state" | jq '.ssh'`
    echo "INFO: ($id): SECURITY configured $ssh" 
    set device = ( `echo "$ssh" | jq -r '.device'` )
    set token = ( `echo "$ssh" | jq -r '.token'` )
  endif

  ## CONFIG SOFTWARE
  if ($config_software != "true") then
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
      # add location of hzn command
      set result = ( `echo "$result" | jq '.command="'"$hzn"'"'` )
      # add distribution information
      set result = ( `echo "$result" | jq '.distribution='"${CLIENT_DISTRIBUTION}"` )
      # update node state
      set node_state = ( `jq '.nodes[]|select(.id=="'$id'")|.software='"$result" "$config"` )
      # update configuration file
      jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" >! "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    endif
    set config_software = ( `jq '.nodes[]|select(.id=="'$id'").software != null' "$config"` )
  endif
  # sanity
  if ($config_software != "true") then
    echo "WARN: ($id): SOFTWARE failed"
    continue
  else
    echo "INFO: ($id): SOFTWARE configured" `echo "$node_state" | jq '.software'`
  endif

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
      set ex_status = 'null'
    else
      set ex_status = "$result"
    endif
    # check node list
    set result = `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'hzn node list'`
    if ($#result == 0) then
      echo "WARN: ($id): EXCHANGE failed; node list not received"
      set ex_node = 'null'
    else
      set ex_node = "$result"
    endif

    set exchange = '{"id":"'"$ex_id"'","status":'"$ex_status"',"node":'"$ex_node"'}'
    set node_state = ( `jq '.nodes[]|select(.id=="'$id'")|.exchange='"$exchange" "$config"` )

    # update node
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" >! "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    set config_exchange = ( `jq '.nodes[]|select(.id=="'$id'").exchange != null' "$config"` )
  endif
  # sanity
  if ($config_exchange != "true") then
    echo "WARN: ($id): EXCHANGE failed"
    continue
  else
    echo "INFO: ($id): EXCHANGE configured" `echo "$node_state" | jq '.exchange'`
  endif

  ## CONFIG PATTERN
  if ($config_pattern != "true") then
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
    
    # test if node is identified in exchange 
    set device = `echo "$node_state" | jq -r '.ssh.device'`
    set found = `echo "$node_state" | jq '.exchange.node.id=="'"$device"'"'`
    if ($found == "false") then
      echo "WARN: ($id): node not found in exchange"
    else
      if ($?DEBUG) echo "DEBUG: ($id): node found in exchange"
    endif 

    set ex_id = `echo "$node_state" | jq -r '.exchange.id'`
    set ex_org = `jq -r '.exchanges[]|select(.id=="'"$ex_id"'").org' "$config"`
    set ex_username = `jq -r '.exchanges[]|select(.id=="'"$ex_id"'").username' "$config"`
    set ex_password = `jq -r '.exchanges[]|select(.id=="'"$ex_id"'").password' "$config"`

    # test if node is configured with pattern
    set node_status = `echo "$node_state" | jq -r '.exchange.node.configstate.state'`
    set node_pattern = `echo "$node_state" | jq -r '.exchange.node.pattern'`

    # unregister node iff
    if ($node_status == "configured" && $node_pattern == "${pt_org}/${pt_id}") then
      if ($?DEBUG) echo "DEBUG: ($id): node is configured with pattern"
    else if ($node_status != "unconfigured") then
      # unregister client
      ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'hzn unregister -f'
      # POLL client for node list information; wait until device identifier matches requested
      set result = `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'hzn node list' | jq '.'`
      while ( `echo "$result" | jq '.exchange.node.configstate.state=="unconfigured"'` == false)
	if ($?DEBUG) echo "DEBUG: ($id): waiting on unregistration (60): $result"
	sleep 60
	set result = `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'hzn node list' | jq '.'`
      end
      set node_state = ( `jq '.nodes[]|select(.id=="'$id'")|.node='"$result" "$config"` )
    else
      if ($?DEBUG) echo "DEBUG: ($id): node is unconfigured"
    endif

    # register node iff
    if (`echo "$node_state" | jq '.exchange.node.configstate.state=="unconfigured"'` == true) then
      if ($?DEBUG) echo "DEBUG: ($id): node is in unconfigured state"
      # create pattern registration file
      set input = "$TMP/input.json"
      echo '{"services": [{"org": "'"${pt_org}"'","url": "'"${pt_url}"'","versionRange": "[0.0.0,INFINITY)","variables": {' >> "${input}"
      # process all variables 
      set pvs = `echo "${pt_vars}" | jq -r '.[].key'`
      foreach pv ( ${pvs} )
        set value = `echo "${pt_vars}" | jq -r '.[]|select(.key="'"${pv}"'").value'`
        echo '"'"${pv}"'":"'"${value}"'"' >> "${input}"
      end
      echo '}}]}' >> "${input}"

      # copy pattern registration file to client
      scp -o "StrictHostKeyChecking false" -i "$private_keyfile" "${input}" "${CLIENT_USERNAME}@${client_ipaddr}:." 
      # create command to execute on client
      set cmd = "hzn register -n ${device}:${token} ${ex_org} -u ${ex_username}:${ex_password} ${pt_org}/${pt_id} -f ${input:t}"
      if ($?DEBUG) echo "DEBUG: ($id): registering with command: $cmd"
      # perform registration
      set result = ( `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" "${cmd}"` )
    endif

    # POLL client for node list information; wait until device identifier matches requested
    set result = `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'hzn node list' | jq '.'`
    while ( `echo "$result" | jq '.id?=="'"$device"'"'` == 'false' )
      if ($?DEBUG) echo "DEBUG: ($id): waiting on registration (60): $result"
      sleep 60
      set result = `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'hzn node list' | jq '.'`
    end
    # update node state
    set node_state = ( `jq '.nodes[]|select(.id=="'$id'")|.node='"$result" "$config"` )
    if ($?DEBUG) echo "DEBUG: registration complete for ${ex_org}/${device}"

    # POLL client for agreementlist information; wait until agreement exists
    set result = `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'hzn agreement list' | jq '.'`
    while ( $#result <= 1) 
      if ($?DEBUG) echo "DEBUG: ($id): waiting on agreement (60): $result"
      sleep 60
      set result = `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'hzn agreement list' | jq '.'`
    end
    # update node state
    set node_state = ( `jq '.nodes[]|select(.id=="'$id'")|.pattern='"$result" "$config"` )
    if ($?DEBUG) echo "DEBUG: agreement complete: $result" 

    # update configuration
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" >! "$TMP/$config:t"; mv -f "$TMP/$config:t" "$config"
    set config_pattern = ( `jq '.nodes[]|select(.id=="'$id'").pattern != null' "$config"` )
  endif
  # sanity
  if ($config_pattern != "true") then
    echo "WARN: ($id): PATTERN failed"
    continue
  else
    echo "INFO: ($id): PATTERN configured" `echo "$node_state" | jq '.pattern'`
  else 

  ## CONFIG NETWORK
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
    scp -o "StrictHostKeyChecking false" -i "$private_keyfile" "$config_script" "${CLIENT_USERNAME}@${client_ipaddr}:." 
    if ($?DEBUG) echo "DEBUG: ($id): invoking script ($config_script:t)"
    ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'sudo mv '"$config_script:t"' /etc/wpa_supplicant/wpa_supplicant.conf'
    set result = '{ "ssid": "'"${nw_ssid}"'","password":"'"${nw_password}"'"}'
    set node_state = ( `jq '.nodes[]|select(.id=="'$id'")|.network='"$result" "$config"` )
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

  if ($?DEBUG) echo "DEBUG: ($id): KEYS $config_keys SSH $config_ssh SOFTWARE $config_software EXCHANGE $config_network PATTERN $config_pattern NETWORK $config_network"

end

done:
rm -fr "$TMP"
exit 0

cleanup:
rm -fr "$TMP"
exit 1
