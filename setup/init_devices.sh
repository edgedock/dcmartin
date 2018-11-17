#!/bin/tcsh

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

set TTL = 30000
set SECONDS = `date "+%s"`
set DATE = `echo $SECONDS \/ $TTL \* $TTL | bc`
set out = "/tmp/$0:t.$DATE.txt"

if (! -e "$out") then
  rm -f "$out:r:r".*
  /usr/bin/sudo nmap -sn -T5 "$net" >! "$out"
endif

if (! -e "$out") then
  echo 'No nmap(8) output for '"$net" >& /dev/stderr
  exit 1
endif

set macs = ( `egrep MAC "$out" | sed 's/.*: \([^ ]*\) .*/\1/'` )

echo "DEBUG: found $#macs devices by MAC"

set i = 1
foreach mac ( $macs )
  unset id device token pattern_org pattern_url exchange_org exchange_url

  # search for device by mac
  set id = `jq -r '.nodes[]|select(.mac=="'$mac'").id' "$config"`
  if ($#id == 0) then
    @ i++
    continue
  endif

  set client_ipaddr = `egrep -B 2 "$mac" "$out" | egrep "Nmap scan" | awk '{ print $5 }'`
  echo "FOUND ($id): MAC $mac; IP $client_ipaddr"

  # find configuration which includes device
  set conf = `jq '.configurations[]|select(.nodes[].id=="'$id'")' "$config"`
  if ($#conf == 0) then
    echo "ERROR: Cannot find node configuration for device: $id"
    exit 1
  endif

  # get configuration id and keys
  set conf_id = ( `echo "$conf" | jq -r '.id'` )
  set public_key = ( `echo "$conf" | jq '.public_key'` )
  set private_key = ( `echo "$conf" | jq '.private_key'` )
  if ($#public_key > 1 && $#private_key > 1) then
    echo "DEBUG: public $public_key private $private_key"
  else
    # generate new key if none
    ssh-keygen -t rsa -f "$conf_id" -N ""
    if (! -s "$conf_id" || ! -s "$conf_id.pub") then
      echo "ERROR: failed to create key files for $conf_id"
      exit 1
    endif
    set public_key = '{ "encoding": "base64", "value": "'`${BASE64_ENCODE} "${conf_id}.pub"`'" }'
    jq '(.configurations[]|select(.id=="'$conf_id'").public_key)|='"$public_key" "$config" >! /tmp/$0:t.$$.json; mv -f /tmp/$0:t.$$.json "$config"
    set private_key = '{ "encoding": "base64", "value": "'`${BASE64_ENCODE} "$conf_id"`'" }'
    jq '(.configurations[]|select(.id=="'$conf_id'").private_key)|='"$private_key" "$config" >! /tmp/$0:t.$$.json; mv -f /tmp/$0:t.$$.json "$config"
    # cleanup
    rm -f "$conf_id" "${conf_id}.pub"
  endif

  # get node configuration
  set node = (  `echo "$conf" | jq '.nodes[]|select(.id=="'"$id"'")'` )
  # find node state (cannot fail)
  set node_state = ( `jq '.nodes[]|select(.id=="'$id'")' "$config"` )

  ## test if ssh configured
  if ( `echo "$node_state" | jq '.ssh'` != 'null' ) then
    # device has ssh configured
    echo "DEVICE ($id) has ssh configured"
    set config_ssh = true
  else
    set config_ssh = false
  endif

  ## test if software configured
  if ( `echo "$node_state" | jq '.software'` != 'null' ) then
    # device has software configured
    echo "DEVICE ($id) has software configured"
    set config_software = true
  else
    set config_software = false
  endif

  ## test if pattern configured
  if ( `echo "$node_state" | jq '.pattern'` != 'null' ) then
    # device has ssh configured
    echo "DEVICE ($id) has pattern configured"
    set config_pattern = true
  else
    # attempt to configure pattern on device
    set config_pattern = false
  endif

  ## test if network configured
  if ( `echo "$node_state" | jq '.network'` != 'null' ) then
    # device has network configured
    echo "DEVICE ($id) has network configured" `echo "$node_state" | jq -c '.network'`
    set config_network = true
  else
    # attempt to configure network on device
    set config_network = false
  endif

  echo "DEBUG: device ($id): SSH $config_ssh SOFTWARE $config_software PATTERN $config_pattern"

  ## CONFIG SSH
  if ($config_ssh == "true") then
    echo "INFO: Device $id has ssh configured" `echo "$node_state" | jq -c '.ssh'`
  else
    # get node configuration specifics
    set device = ( `echo "$node" | jq -r '.device'` )
    set token = ( `echo "$node" | jq -r '.token'` )
    # process public key for device
    set pke = ( `echo "$public_key" | jq -r '.encoding'` )
    if ($#pke && "$pke" == "base64") then
      set public_keyfile = /tmp/$0:t.$$.pub
      echo "$public_key" | jq -r '.value' | base64 --decode >! "$public_keyfile"
      chmod 400 "$public_keyfile"
      set private_keyfile = /tmp/$0:t.$$.pri
      echo "$private_key" | jq -r '.value' | base64 --decode >! "$private_keyfile"
      chmod 400 "$private_keyfile"
    else
      echo "ERROR: No device key or public key"
      exit 1
    endif
    # perform ssh-copy-id using distribution default username and password
    set ssh_copy_id = /tmp/$0:t.$$.exp
    cat "ssh-copy-id.tmpl" \
      | sed 's|%%CLIENT_IPADDR%%|'"${client_ipaddr}"'|g' \
      | sed 's|%%CLIENT_USERNAME%%|'"${CLIENT_USERNAME}"'|g' \
      | sed 's|%%CLIENT_PASSWORD%%|'"${CLIENT_PASSWORD}"'|g' \
      | sed 's|%%PUBLIC_KEYFILE%%|'"${public_keyfile}"'|g' \
      >! "$ssh_copy_id"
    set failed = ( `expect -d -f "$ssh_copy_id" |& egrep failure | sed 's/.*failure.*/failure/g'` )
    if ($#failed) then
      echo "FAILURE: ${device}: ssh_copy_id ${client_ipaddr} ${CLIENT_USERNAME} ${CLIENT_PASSWORD} ${public_keyfile}"
    else
      echo "SUCCESS: ${device}: ssh_copy_id ${client_ipaddr} ${CLIENT_USERNAME} ${CLIENT_PASSWORD} ${public_keyfile}"
      ## UPDATE NODE
      set node_state = ( `jq '.nodes[]|select(.id=="'$id'")|.ssh={"token":"'"${CLIENT_PASSWORD}"'","key":'"${public_key}"',"ip":"'"$client_ipaddr"'"}' "$config"` )
      ## UPDATE CONFIGURATION
      jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" >! /tmp/$0:t.$$.json; mv -f /tmp/$0:t.$$.json "$config"
    endif 
    rm -f "$ssh_copy_id"
    rm -f "$public_keyfile"
    rm -f "$private_keyfile"
    # get new status
    set config_ssh = ( `jq '.nodes[]|select(.id=="'$id'").ssh != null' "$config"` )
  endif

  ## CONFIG SOFTWARE
  if ($config_software == "true") then
    echo "INFO: Device $id has software configured" `echo "$node" | jq -c '.software'`
  else if ($config_ssh != "true") then
    # echo "DEBUG: device $id does not have ssh configured"
  else
    # get private key
    set private_key = ( `echo "$conf" | jq '.private_key'` )
    set private_keyfile = /tmp/$0:t.$$.pri
    echo "$private_key" | jq -r '.value' | base64 --decode >! "$private_keyfile"
    chmod 400 "$private_keyfile"
    # install software
    set result = ( `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'wget -qO - ibm.biz/horizon-setup | sudo bash -s' | jq '.'` )
    if ($#result == 0) then
      echo "FAILURE: Cannot install software onto ${device}"
    else
      set node_state = ( `jq '.nodes[]|select(.id=="'$id'")|.software='"$result" "$config"` )
      jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" >! /tmp/$0:t.$$.json; mv -f /tmp/$0:t.$$.json "$config"
    endif
    set config_software = ( `jq '.nodes[]|select(.id=="'$id'").software != null' "$config"` )
  else
    # echo "DEBUG: SSH $config_ssh SOFTWARE $config_software"
  endif

  ## CONFIG PATTERN
  if ($config_pattern == "true") then
    echo "INFO: Device $id has pattern configured"
  else if ($config_ssh == true && $config_software == true) then
    # get pattern
    set patid = ( `echo "$conf" | jq -r '.pattern?'` )
    if ($#patid) then
      set pattern = ( `jq '.patterns[]|select(.id=="'$patid'")' "$config"` )
      if ($#pattern) then
	set pattern_id = ( `echo "$pattern" | jq -r '.id'` )
	set pattern_org = ( `echo "$pattern" | jq -r '.org'` )
	set pattern_url = ( `echo "$pattern" | jq -r '.url'` )
      else
	echo "ERROR: Did not find pattern for $patid"
        exit 1
      endif
    else
      echo "ERROR: Did not find pattern in configuration: $conf"
      exit 1
    endif
    # get exchange
    set excid = ( `echo "$conf" | jq -r '.exchange?'` )
    if ($#excid) then
      set exchange = ( `jq '.exchanges[]|select(.id=="'$excid'")' "$config"` )
      if ($#exchange) then
	set exchange_org = ( `echo "$exchange" | jq -r '.org'` )
	set exchange_url = ( `echo "$exchange" | jq -r '.url'` )
	set exchange_username = ( `echo "$exchange" | jq -r '.username'` )
	set exchange_password = ( `echo "$exchange" | jq -r '.password'` )
      else
	echo "ERROR: Did not find exchange $excid"
	exit 1
      endif
    else
      echo "ERROR: Did not find exchange in configuration: $conf"
      exit 1
    endif
    # test for software
    set hzn = `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'command -v hzn'`
    if ($#hzn == 0) then
      echo "ERROR: Horizon software not installed"
      exit 1
    endif
    # get node status
    set result = `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$CLIENT_USERNAME"@"$client_ipaddr" 'hzn node list'`
    if ($#result == 0) then
      echo "FAILURE: Cannot install software onto ${device}"
    else
      set node_state = ( `jq '.nodes[]|select(.id=="'$id'")|.pattern='"$result" "$config"` )
      jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "$config" >! /tmp/$0:t.$$.json; mv -f /tmp/$0:t.$$.json "$config"
    endif
    set config_pattern = ( `jq '.nodes[]|select(.id=="'$id'").pattern != null' "$config"` )
  else
    echo "DEBUG: SSH $config_ssh SOFTWARE $config_software PATTERN $config_pattern"
  endif

  # go to next
  @ i++
end

rm -f /tmp/$0:t.$$.*
exit 0

cleanup:
  rm -f /tmp/$0:t.$$.*
  exit 1
