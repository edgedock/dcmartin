#!/bin/sh

exec 0>&- # close stdin
exec 1>&- # close stdout
exec 2>&- # close stderr

socat TCP4-LISTEN:8585,fork EXEC:./node-id.sh &
