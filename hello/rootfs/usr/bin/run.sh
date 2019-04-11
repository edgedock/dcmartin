#!/bin/sh
socat TCP4-LISTEN:81,fork EXEC:/usr/bin/service.sh
