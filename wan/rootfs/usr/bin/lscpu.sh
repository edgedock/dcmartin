#!/bin/bash
if [ -z $(command -v "lscpu") ]; then
  echo '{"lscpu":null}'
  exit 1
fi
echo -n '{"lscpu":{'
lscpu | while read -r; do
  KEY=$(echo "$REPLY" | sed 's|^\([^:]*\):.*|\1|')
  VAL=$(echo "$REPLY" | sed 's|^[^:]*:[ \t]*\(.*\)|\1|')
  if [ -n "${VALUE:-}" ]; then echo -n ','; fi
  VALUE='"'${KEY}'": "'${VAL}'"'
  echo -n "${VALUE}"
done
echo '}}'
exit 0
