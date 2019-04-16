#
# Makefile for Edge Fabric Gateway (efgateway)
#

VERSION:= '0.0.1'
EXEC:= rpi_i2c_oled

ARCH:= $(shell hzn node list | jq .configuration.architecture)
HOST_IP:= $(shell hostname -I | cut -d ' ' -f1)

all: build debug
#all: build

build:
	docker build -f DockerfileUbuntu.$(ARCH) -t $(EXEC) .

debug:
#	docker run --env HOST_IP=$(HOST_IP) --device=/dev/i2c-1:/dev/i2c-1 -it $(EXEC)
#       docker run -it --volume `pwd`:/outside $(EXEC) /bin/sh
	docker run --device=/dev/i2c-1:/dev/i2c-1 -it $(EXEC)

run:
        -docker rm -f $(EXEC) 2>/dev/null || :
        docker run --device=/dev/i2c-1:/dev/i2c-1 -d  $(EXEC)
