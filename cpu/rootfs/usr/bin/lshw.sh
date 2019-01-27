#!/bin/bash
if [ -z $(command -v "lshw") ]; then
  echo '{"lshw":null}'
  exit 1
fi
echo -n '{"lshw":' $(lshw -json) '}'
exit 0
