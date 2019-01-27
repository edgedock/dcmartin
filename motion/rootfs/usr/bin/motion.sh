#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

if [ -n "${MOTION_LOG_LEVEL}" ]; then MOTION_LOG_LEVEL=2; fi
if [ -n "${MOTION_LOG_TYPE}" ]; then MOTION_LOG_TYPE="all"; fi

# mkdir -p ${TMP}/motion
# ln -s ${TMP}/motion /var/lib/motion 

# start motion
motion -b -d ${MOTION_LOG_LEVEL} -k ${MOTION_LOG_TYPE} -c /etc/motion/motion.conf -l /dev/stderr
