#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

if [ -z "${MOTION_LOG_LEVEL:-}" ]; then MOTION_LOG_LEVEL=2; fi
if [ -z "${MOTION_LOG_TYPE:-}" ]; then MOTION_LOG_TYPE="all"; fi

# mkdir -p ${TMP}/motion
# ln -s ${TMP}/motion /var/lib/motion 

# start motion
motion -b -n ${MOTION_LOG_LEVEL} -k ${MOTION_LOG_TYPE} -c /etc/motion/motion.conf -l /dev/stderr
