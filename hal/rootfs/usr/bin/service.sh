#!/bin/sh

# Get the currect CPU consumption, then construct the HTTP response message
HEADERS="Content-Type: application/json; charset=ISO-8859-1"
BODY='{"lsusb":'$(lsusb.sh|jq '.lsusb?')',"lscpu":'$(lscpu.sh|jq '.lscpu?')',"lspci":'$(lspci.sh|jq '.lspci?')',"lsblk":'$(lsblk.sh|jq '.lsblk?')'}'
HTTP="HTTP/1.1 200 OK\r\n${HEADERS}\r\n\r\n${BODY}\r\n"

# Emit the HTTP response
echo $HTTP
