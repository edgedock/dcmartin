#!/bin/bash

REPO=updates
LIST=/etc/apt/sources.list.d/bluehorizon.list
URL=http://pkg.bluehorizon.network
KEY=${URL}/bluehorizon.network-public.key
wget -qO - ${KEY} | sudo apt-key add -
echo "deb [arch=armhf,arm64,amd64] ${URL}/linux/ubuntu xenial-${REPO} main" > /tmp/$$ && sudo mv /tmp/$$ ${LIST}
sudo apt-get update -y && sudo apt-get install -y bluehorizon
