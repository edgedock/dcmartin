#!/bin/bash
TYPE=linux
DIST=ubuntu
#RELEASE=$(lsb_release -cs)
RELEASE=xenial
REPO=updates
LIST=/etc/apt/sources.list.d/bluehorizon.list
URL=http://pkg.bluehorizon.network
KEY=${URL}/bluehorizon.network-public.key
wget -qO - ${KEY} | sudo apt-key add -
sudo add-apt-repository "deb [arch=armhf,arm64,amd64,ppc64el] ${URL}/${TYPE}/${DIST} ${RELEASE}-${REPO} main"
sudo apt-get update -qq && sudo apt-get install -y -qq --no-install-recommend bluehorizon
