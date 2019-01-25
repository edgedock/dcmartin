# YOLO2MSGHUB service & pattern

Sens YOLO as-a-service ReSTful API to MSGHUB

This service pattern takes no input values; periodically calls the `yolo` service and sends the result to IBM MessageHub

## User Input

A valid IBM MessageHub API key must be provided.

## Service Tag

Other Horizon services can require the `yolo` service through service tag:

1. Intel/AMD 64-bit: `dcmartin@us.ibm.com/com.github.dcmartin.open-horizon.yolo_0.0.1_amd64`
1. ARMv7x32: `dcmartin@us.ibm.com/com.github.dcmartin.open-horizon.yolo_0.0.1_arm`
1. ARMv8x64: `dcmartin@us.ibm.com/com.github.dcmartin.open-horizon.yolo_0.0.1_arm64`

## RESTful API

This service provisions no API

## Example

