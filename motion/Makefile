###
### MAKEFILE FOR HORIZON SERVICE
###

##
## architecture
##
SYSTEM_ARCH := $(shell uname -m | sed -e 's/aarch64.*/arm64/' -e 's/x86_64.*/amd64/' -e 's/armv.*/arm/')
export ARCH ?= $(SYSTEM_ARCH)

##
## build
##
BUILD_FROM = $(shell jq -r ".build_from.${ARCH}" build.json)

##
## configuration
##
SERVICE_ORG := $(shell jq -r '.org' config.json)
SERVICE_NAME := $(shell jq -r '.slug' config.json)
SERVICE_VERSION := $(shell jq -r '.version' config.json)
SERVICE_DOMAIN := $(shell jq -r '.url' config.json)
SERVICE_PORT := $(shell jq -r '.ports|to_entries|first|.value' config.json)


DOCKER_HUB_ID ?= dcmartin
DOCKER_NAME ?= $(ARCH)_$(SERVICE_NAME)
DOCKER_TAG ?= $(DOCKER_HUB_ID)/$(DOCKER_NAME):$(SERVICE_VERSION)

default: all


all:	build run check

build:	service.json build.json
	docker build --build-arg BUILD_FROM=$(BUILD_FROM) . -t "$(DOCKER_TAG)"

run:	stop 
	-docker-run.sh "$(DOCKER_NAME)" "$(DOCKER_TAG)"

stop:
	-docker stop $(DOCKER_TAG)
	-docker rm -f $(DOCKER_NAME)

check:
	curl -sSL http://localhost:$(SERVICE_PORT)

docker-push: build
	: $${DOCKER_TAG:?}
	docker push $(DOCKER_TAG)

service.json: service.tmpl config.json build.json
	# : $${SERVICE_ORG:?} $${SERVICE_NAME:?} $${SERVICE_DOMAIN:?} $${DOCKER_HUB_ID:?} $${SERVICE_VERSION:?}
	sed -e "s|%%DOCKER_HUB_ID%%|$(DOCKER_HUB_ID)|g" -e "s|%%SERVICE_ORG%%|$(SERVICE_ORG)|g" -e "s|%%SERVICE_NAME%%|$(SERVICE_NAME)|g" -e "s|%%SERVICE_DOMAIN%%|$(SERVICE_DOMAIN)|g" -e "s|%%SERVICE_VERSION%%|$(SERVICE_VERSION)|g" -e "s|%%ARCH%%|$(ARCH)|g" service.tmpl > service.json
	# jq '.|.org="$(SERVICE_ORG)"|.label="$(SERVICE_NAME) for $(ARCH)"|.url="$(SERVICE_DOMAIN)/service-$(SERVICE_NAME)"|.version="$(SERVICE_VERSION)"|.arch="$(ARCH)"|.deployment.services.motion.image="$(DOCKER_HUB_ID)/$(ARCH)_$(SERVICE_NAME):$(SERVICE_VERSION)"' service.tmpl > service.json

# Create/update the metadata in the exchange for this service
publish-service: build service.json
	: $${HZN_EXCHANGE_USER_AUTH:?} $${PRIVATE_KEY_FILE:?} $${PUBLIC_KEY_FILE:?}   # this verifies these env vars are set
	# hzn exchange service publish -k $$PRIVATE_KEY_FILE -K $$PUBLIC_KEY_FILE -f horizon/service.definition.json
	hzn exchange service publish -k $$PRIVATE_KEY_FILE -K $$PUBLIC_KEY_FILE -f service.json

clean:
	-docker rm -f $(DOCKER_NAME) 2> /dev/null || :
	-docker rmi $(DOCKER_TAG) 2> /dev/null || :

.PHONY: default all build run check stop publish publish-service clean
