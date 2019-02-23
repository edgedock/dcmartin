#!/bin/bash
JPG="${1}"
# get image
if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- listening to ${YOLO4MQTT_HOST} on topic: ${YOLO4MQTT_TOPIC}" &> /dev/stderr; fi
mosquitto_sub -h ${YOLO4MQTT_HOST} -t ${YOLO4MQTT_TOPIC} 2> /dev/stderr | base64 | base64 --decode > "${JPG}"
