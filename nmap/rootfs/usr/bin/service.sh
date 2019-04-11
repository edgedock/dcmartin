#!/bin/sh

if [ -z "${NMAP_LAN:-}" ]; then NMAP_LAN='192.168.1.0'; fi
if [ -z "${NMAP_SUB:-}" ]; then NMAP_SUB=24; fi
if [ -z "${NMAP_PERIOD:-}" ]; then NMAP_PERIOD=30; fi

# don't update statistics more than once per (in seconds)
SECONDS=$(date "+%s")
DATE=$(echo ${SECONDS} \/ ${NMAP_PERIOD} \* ${NMAP_PERIOD} | bc)

# output target
OUTPUT="/tmp/${0##*/}.$$.${DATE}.json"
# test if been-there-done-that
if [ ! -s "${OUTPUT}" ]; then
  # remove old output
  rm -f "/tmp/${0##*/}".*
  nmap -sn -T5 ${NMAP_LAN}/${NMAP_SUB} | gawk -f /usr/bin/nmap.awk > ${OUTPUT}
fi

echo "HTTP/1.1 200 OK"
echo
cat ${OUTPUT}
