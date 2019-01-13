#!/bin/bash
if [ -z $(command -v "lspci") ]; then
  echo '{"lspci":null}'
  exit 1
fi
echo -n '{"lspci":['
lspci -mm -nn | sed 's| "|,"|g' | sed 's| -[^ ,]*||g' | while read -r; do
  if [ -n "${VAL:-}" ]; then echo -n ','; fi

  echo -n '{'

  SLOT=$(echo "$REPLY" | awk -F, '{ print $1 }')
  echo -n '"slot": "'$SLOT'"'
  VMM=$(lspci -vmm | egrep -A 5 "$SLOT")
  VAL=$(echo "$VMM" | egrep "Rev:" | sed 's|.*Rev:[ \t]*\([^ \t]*\).*|\1|')
  if [ -n "${VAL}" ]; then echo -n ',''"revision": "'$VAL'"'; fi
  VAL=$(echo "$VMM" | egrep "ProgIf" | sed 's|.*ProgIf:[ \t]*\([^ \t]*\).*|\1|')
  if [ -n "${VAL}" ]; then echo -n ',''"interface": "'$VAL'"'; fi

  VAL=$(echo "$REPLY" | awk -F, '{ print $2 }' | sed 's|"\(.*\) \[\(.*\)\]"|"device_class_id": "\2","device_class":"\1"|')
  if [ "${VAL}" != "${REPLY}" ]; then echo -n ','"${VAL}"; fi

  VAL=$(echo "$REPLY" | awk -F, '{ print $3 }' | sed 's|"\(.*\) \[\(.*\)\]"|"vendor_class_id": "\2","vendor_class":"\1"|')
  if [ "${VAL}" != "${REPLY}" ]; then echo -n ','"${VAL}"; fi

  VAL=$(echo "$REPLY" | awk -F, '{ print $4 }' | sed 's|"\(.*\) \[\(.*\)\]"|"device_id": "\2","device_name":"\1"|')
  if [ "${VAL}" != "${REPLY}" ]; then echo -n ','"${VAL}"; fi

  VAL=$(echo "$REPLY" | awk -F, '{ print $5 }')
  if [ ! -z "${VAL}" ] && [ "${VAL}" != "" ]; then
    VAL=$(echo "${VAL}" | sed 's|"\(.*\) \[\(.*\)\]"|"vendor_id": "\2","vendor_name":"\1"|')
    if [ "${VAL}" != "${VAL}" ]; then echo -n ','"${VAL}"; fi
  fi

  echo -n '}'
done
echo ']}'
exit 0
