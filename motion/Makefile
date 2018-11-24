###
### MAKEFILE FOR HORIZON SERVICE
###


# Transform the machine arch into some standard values: "arm", "arm64", or "amd64"
SYSTEM_ARCH := $(shell uname -m | sed -e 's/aarch64.*/arm64/' -e 's/x86_64.*/amd64/' -e 's/armv.*/arm/')

# To build for an arch different from the current system, set this env var to 1 of the values in the comment above
export ARCH ?= $(SYSTEM_ARCH)

# These variables can be overridden from the environment
export SERVICE_NAME := $(shell jq -r '.slug' config.json)
export SERVICE_VERSION := $(shell jq -r '.version' config.json)
export SERVICE_DOMAIN := $(shell jq -r '.url' config.json | base64)

export SERVICE_ORG := $(shell jq -r '.org' build.json)

BUILD_FROM := $(shell jq -r .build_from.$(ARCH) build.json)

DOCKER_NAME ?= $(ARCH)_$(SERVICE_NAME)
DOCKER_HUB_ID ?= openhorizon
DOCKER_TAG ?= $(DOCKER_HUB_ID)/$(DOCKER_NAME):$(SERVICE_VERSION)

TEST_PORT ?= 7999

default: all

all: build run check

build:
	docker build --build-arg BUILD_FROM=$(BUILD_FROM) .

run:
	-docker rm -f $(DOCKER_NAME) 2> /dev/null || :
	docker-run.sh "${DOCKER_NAME}" "${DOCKER_TAG}"

check:
	curl -sSL http://localhost:$(TEST_PORT)

stop:
	-docker rm -f $(DOCKER_NAME) 2> /dev/null || :

# To publish you must have write access to the docker hub DOCKER_HUB_ID user
docker-push: build
	: $${DOCKER_TAG:?}
	docker push $(DOCKER_TAG)

#{
#  "org": "$SERVICE_ORG",
#  "label": "$SERVICE_NAME for $ARCH",
#  "description": "Provides motion-project.io as service",
#  "public": true,
#  "url": "https://$SERVICE_DOMAIN/service-$SERVICE_NAME",
#  "version": "$SERVICE_VERSION",
#  "arch": "$ARCH",
#  "sharable": "single",
#  "requiredServices": [],
#  "userInput": [],
#  "deployment": {
#    "services": {
#      "motion": {
#        "image": "$DOCKER_HUB_ID/${ARCH}_$SERVICE_NAME:$SERVICE_VERSION"
#      }
#    }
#  }
#}

service.json: service.tmpl config.json
	: $${SERVICE_ORG:?} $${SERVICE_NAME:?} $${SERVICE_DOMAIN:?} $${SERVICE_VERSION:?}
	cat service.tmpl > service.json

# Create/update the metadata in the exchange for this service
publish-service: build service.json
	: $${HZN_EXCHANGE_USER_AUTH:?} $${PRIVATE_KEY_FILE:?} $${PUBLIC_KEY_FILE:?}   # this verifies these env vars are set
	# hzn exchange service publish -k $$PRIVATE_KEY_FILE -K $$PUBLIC_KEY_FILE -f horizon/service.definition.json
	hzn exchange service publish -k $$PRIVATE_KEY_FILE -K $$PUBLIC_KEY_FILE -f service.json

clean:
	-docker rm -f $(DOCKER_NAME) 2> /dev/null || :
	-docker rmi $(DOCKER_TAG) 2> /dev/null || :

.PHONY: default all build run check stop publish publish-service clean
