#!/bin/tcsh

if (! -e "/usr/local/bin/nmap" && ! -e "/usr/bin/nmap") then
  /bin/echo 'No nmap(8); install using brew or apt' >& /dev/stderr
  exit
endif

onintr cleanup

if ($#argv > 0) then
  set config = $argv[1]
else
  set config = "horizon.json"
endif
if (! -s "$config" ) then
  echo "Cannot find configuration file"
  exit
endif

if ($#argv > 1) then
  set net = $argv[2]
else
  echo -n "$0 <net> (default 192.168.1.0/24):"
  set net = $<
  if ($#net == 0 || $net == "") then
    set net = "192.168.1.0/24"
  endif
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
  exit
endif

set macs = ( `egrep MAC "$out" | sed "s/.*: \([^ ]*\) .*/\1/"` )

set i = 1
foreach mac ( $macs )
  unset id device token pattern_org pattern_url exchange_org exchange_url
  # search for device by mac
  set id = `jq -r '.nodes[]|select(.mac=="'$mac'").id' "$config"`
  if ($#id) then
    # find configuration for device
    set conf = `jq '.configurations[]|select(.nodes[].id=="'$id'")' "$config"`
    if ($#conf) then
      set conf_id = ( `echo "$conf" | jq -r '.id'` )
      # get nodes
      set node = (  `echo "$conf" | jq '.nodes[]|select(.id=="'"$id"'")'` )
      if ($#node) then
        set device = ( `echo "$node" | jq -r '.device'` )
        set token = ( `echo "$node" | jq -r '.token'` )
        set client_key = ( `echo "$node" | jq -r '.key'` )
      endif
      # get pattern
      set patid = ( `echo "$conf" | jq -r '.pattern?'` )
      if ($#patid) then
        set pattern = ( `jq '.patterns[]|select(.id=="'$patid'")' "$config"` )
        if ($#pattern) then
          set pattern_id = ( `echo "$pattern" | jq -r '.id'` )
          set pattern_org = ( `echo "$pattern" | jq -r '.org'` )
          set pattern_url = ( `echo "$pattern" | jq -r '.url'` )
        else
          echo "Did not find pattern for $patid"
        endif
      else
        echo "Did not find pattern in configuration: $conf"
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
          echo "Did not find exchange $excid"
        endif
      else
        echo "Did not find exchange in configuration: $conf"
      endif
    else
      echo "Cannot find configuration for device: $id"
    endif
    if ($?device && $?token && $?pattern_org && $?pattern_url && $?exchange_org && $?exchange_url) then
      set client_ipaddr = `egrep -B 2 "$mac" "$out" | egrep "Nmap scan" | awk '{ print $5 }'`
      echo "FOUND ($id): MAC $mac; IP $client_ipaddr"
      # get keys 
      set public_key = ( `echo "$conf" | jq -r '.public_key'` )
      if ($#public_key && "$public_key" != null ) then
	set device_key = "$public_key"
	set private_key = ( `echo "$conf" | jq -r '.private_key'` )
      endif
      # generate new key if none
      if ($?device_key == 0) then
	ssh-keygen -t rsa -f "$conf_id" -N ""
	set private_key = '{ "encoding": "base64", "value": "'`base64 "$conf_id"`'" }'
	set public_key = '{ "encoding": "base64", "value": "'`base64 "$conf_id.pub"`'" }'
	rm -f "$conf_id" "$conf_id.pub"
	# update configuration
	jq '(.configurations[]|select(.id=="'$conf_id'").public_key)|='"$public_key" "$config" >! /tmp/$0:t.$$.json; mv -f /tmp/$0:t.$$.json "$config"
	jq '(.configurations[]|select(.id=="'$conf_id'").private_key)|='"$private_key" "$config" >! /tmp/$0:t.$$.json; mv -f /tmp/$0:t.$$.json "$config"
	# use public key of configuration
	set device_key = "$public_key"
      endif
      # process public key for device
      set pke = ( `echo "$device_key" | jq -r '.encoding'` )
      if ($#pke && "$pke" == "base64") then
	set private_keyfile = /tmp/$0:t.$$.pri
	set device_keyfile = /tmp/$0:t.$$.pub
	echo "$device_key" | jq -r '.value' | base64 -D >! "$device_keyfile"
	echo "$private_key" | jq -r '.value' | base64 -D >! "$private_keyfile"
	chmod 400 "$device_keyfile" "$private_keyfile"
      else
	echo "No device key or public key"
      endif
      if ($token != null) then
        echo "CONFIGURED ($id); node: $node"
        set hzn = `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'command -v hzn'`
        if ($#hzn == 0) then
          ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'wget -qO - ibm.biz/horizon-setup | sudo bash -s'
        endif
        set hnl = `ssh -o "StrictHostKeyChecking false" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'hzn node list'`
        if ($#hnl) then
          echo "Node list: $hnl"
        endif
      else
        echo "CONFIGURING ($id); node $node"
        # get client specifics
        set client_username = "pi"
        set client_password = "raspberry"
        set ssh_copy_id = /tmp/$0:t.$$.exp
        cat "ssh-copy-id.tmpl" \
          | sed 's|%%CLIENT_IPADDR%%|'"${client_ipaddr}"'|g' \
          | sed 's|%%CLIENT_USERNAME%%|'"${client_username}"'|g' \
          | sed 's|%%CLIENT_PASSWORD%%|'"${client_password}"'|g' \
          | sed 's|%%PUBLIC_KEYFILE%%|'"${device_keyfile}"'|g' \
          >! "$ssh_copy_id"
        if (-s "$ssh_copy_id") then
          set failed = ( `expect -d -f "$ssh_copy_id" |& egrep failure | sed 's/.*failure.*/failure/g'` )
          if ($#failed) then
            echo "FAILURE: ${device}: ssh_copy_id ${client_ipaddr} ${client_username} ${client_password} ${device_keyfile}"
          else
            echo "SUCCESS: ${device}: ssh_copy_id ${client_ipaddr} ${client_username} ${client_password} ${device_keyfile}"
            set node = ( `jq '.configurations[].nodes[]|select(.id=="'$id'")|.token="'"${client_password}"'"|.key='"${device_key}"'|.ip="'"$client_ipaddr"'"' "$config"` )
            jq '(.configurations[].nodes[]|select(.id=="'$id'"))|='"$node" "$config" >! /tmp/$0:t.$$.json; mv -f /tmp/$0:t.$$.json "$config"
          endif 
          rm -f "$ssh_copy_id"
          rm -f "$device_keyfile"
        else
          echo "ERROR: Failure to communicate"
          exit
        endif
      endif
    else
      echo "ERROR: configuration file $config is malformed"
      exit
    endif
  endif
  @ i++
end

cleanup:
