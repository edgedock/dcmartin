#!/bin/bash

echo $(date) "$0 $*" >&2

###
### START MOTION
###

if [ -n "${MOTION_LOG_LEVEL}" ]; then MOTION_LOG_LEVEL=2; fi

if [ -n "${MOTION_LOG_TYPE}" ]; then MOTION_LOG_TYPE="all"; fi

# start motion
motion -b -d ${MOTION_LOG_LEVEL} -k ${MOTION_LOG_TYPE} -c /etc/motion/motion.conf -l /dev/stderr
