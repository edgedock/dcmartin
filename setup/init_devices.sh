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

set ips = ( `egrep "Nmap scan" "$out" | awk '{ print $5 }'` )
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
      # get nodes
      set node = (  `echo "$conf" | jq '.nodes[]|select(.id=="'"$id"'")'` )
      if ($#node) then
        set device = ( `echo "$node" | jq -r '.device'` )
        set token = ( `echo "$node" | jq -r '.token'` )
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
      if ($token != null) then
        echo "CONFIGURED: MAC $mac; IP $ips[$i]; id $id; node $device with token $token; exchange ${exchange_username}:${exchange_password} in $exchange_org at $exchange_url; pattern $pattern_org/$pattern_id @ $pattern_url"
      else
        echo "SETUP: MAC $mac; IP $ips[$i]; id $id; node $device; exchange ${exchange_username}:${exchange_password} in $exchange_org at $exchange_url; pattern $pattern_org/$pattern_id @ $pattern_url"
        echo "CONF: $conf"
        set pke = ( `echo "$conf" | jq -r '.public_key.encoding'` )
        if ($#pke && "$pke" == "base64") then
          set public_keyfile = /tmp/$0:t.$$.pub
          echo "$conf" | jq -r '.public_key.value' | base64 -D >! "$public_keyfile"
          echo "PUBLIC_KEYFILE: $public_keyfile"
        else
          echo "ERROR: No public key found"
          exit
        endif
        set client_ipaddr = $ips[$i]
        set client_username = "pi"
        set client_password = "raspberry"
        set ssh_copy_id = /tmp/$0:t.$$.exp
        cat "ssh-copy-id.tmpl" \
          | sed 's|%%CLIENT_IPADDR%%|'"${client_ipaddr}"'|g' \
          | sed 's|%%CLIENT_USERNAME%%|'"${client_username}"'|g' \
          | sed 's|%%CLIENT_PASSWORD%%|'"${client_password}"'|g' \
          | sed 's|%%PUBLIC_KEYFILE%%|'"${public_keyfile}"'|g' \
          >! "$ssh_copy_id"
        if (-s "$ssh_copy_id") then
          echo "SSH_COPY_ID: $ssh_copy_id"
          set result = ( `expect -d -f "$ssh_copy_id" |& egrep failure | sed 's/.*failure.*/failure/g'` )
          echo "$result"
        else
          echo "ERROR: Failure to communicate""
          exit
        endif
      endif
    else
      echo "ERROR: failure"
      exit
    endif
  endif
  @ i++
end

cleanup:
