###
### MAKEFILE
###

## architecture
ARCH := $(shell uname -m | sed -e 's/aarch64.*/arm64/' -e 's/x86_64.*/amd64/' -e 's/armv.*/arm/')

## build
BUILD_FROM = $(shell jq -r ".build_from.${ARCH}" build.json)

## service
LABEL := $(shell jq -r '.label' service.json)
VERSION := $(shell jq -r '.version' service.json)
PORT := 8585 # this should be defined in service.json

## docker
DOCKER_HUB_ID ?= dcmartin
DOCKER_NAME ?= $(ARCH)_$(LABEL)
DOCKER_TAG ?= $(DOCKER_HUB_ID)/$(DOCKER_NAME):$(VERSION)

default: all

all:	build run check

build:	service.json build.json
	docker build --build-arg BUILD_FROM=$(BUILD_FROM) . -t "$(DOCKER_TAG)"

run:	stop 
	# docker run -d --name ${DOCKER_NAME} ${OPTIONS} --volume "${VOLUME}"':/data' "${DOCKER_TAG}"
	-docker-run.sh "$(DOCKER_NAME)" "$(DOCKER_TAG)"

stop:
	-docker stop $(DOCKER_TAG)
	-docker rm -f $(DOCKER_NAME)

check:
	curl -sSL http://localhost:$(SERVICE_PORT)

docker-push: build
	: $${DOCKER_TAG:?}
	docker push $(DOCKER_TAG)

# Create/update the metadata in the exchange for this service
publish-service: build service.json
	: $${HZN_EXCHANGE_USER_AUTH:?} $${PRIVATE_KEY_FILE:?} $${PUBLIC_KEY_FILE:?}   # this verifies these env vars are set
	hzn exchange service publish -k $$PRIVATE_KEY_FILE -K $$PUBLIC_KEY_FILE -f service.json

clean:
	-docker rm -f $(DOCKER_NAME) 2> /dev/null || :
	-docker rmi $(DOCKER_TAG) 2> /dev/null || :

.PHONY: default all build run check stop publish publish-service clean
