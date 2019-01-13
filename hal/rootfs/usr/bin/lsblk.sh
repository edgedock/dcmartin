#!/bin/bash
if [ -z $(command -v "lsblk") ]; then
  echo '{"lsblk":null}'
  exit 1
fi
echo -n '{"lsblk":' $(lsblk -J | jq '.blockdevices') '}'
exit 0
