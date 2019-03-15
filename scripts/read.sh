#!/bin/bash

if [ -z "${1}" ]; then SCRIPT="script.txt"; else SCRIPT="${1}"; fi
if [ ! -s "${SCRIPT}" ]; then echo "No ${SCRIPT} to read" &> /dev/stderr; exit 1; fi

echo -n "Counting down " &> /dev/stderr
for ((i=0; i<10; i++)); do echo -n '.' &> /dev/stderr; sleep 0.1; done
echo ' done' &> /dev/stderr

clear

cat "${SCRIPT}" | while read; do 
  echo -n $(date +%T) '$ '
  for ((i=0; i<${#REPLY}; i++)); do echo "after 200" | tclsh; printf "${REPLY:$i:1}"; done
  echo ""
  eval "${REPLY}"
done
