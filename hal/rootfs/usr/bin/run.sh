#!/bin/sh

socat TCP4-LISTEN:54331,fork EXEC:./service.sh

