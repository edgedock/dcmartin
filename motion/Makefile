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
export MYDOMAIN := $(shell jq -r '.url' config.json)

DOCKER_NAME ?= $(ARCH)_$(SERVICE_NAME)
DOCKER_HUB_ID ?= openhorizon
export MYDOMAIN ?= github.com/open-horizon/examples/wiki
TEST_PORT ?= 7999

DOCKER_TAG ?= $(DOCKER_HUB_ID)/$(DOCKER_NAME):$(SERVICE_VERSION)

default: all

all: build run check

build:
	docker build -t $(DOCKER_TAG) -f ./Dockerfile.$(ARCH) .

run:
	-docker rm -f $(DOCKER_NAME) 2> /dev/null || :
	docker-run.sh "${DOCKER_NAME}" "${DOCKER_TAG}"

check:
	curl -sSL http://localhost:$(TEST_PORT)

stop:
	-docker rm -f $(DOCKER_NAME) 2> /dev/null || :

# To publish you must have write access to the docker hub DOCKER_HUB_ID user
docker-push: build
	docker push $(DOCKER_TAG)

# Create/update the metadata in the exchange for this service
publish-service: build
	: $${HZN_EXCHANGE_USER_AUTH:?} $${PRIVATE_KEY_FILE:?} $${PUBLIC_KEY_FILE:?}   # this verifies these env vars are set
	hzn exchange service publish -k $$PRIVATE_KEY_FILE -K $$PUBLIC_KEY_FILE -f horizon/service.definition.json

clean:
	-docker rm -f $(DOCKER_NAME) 2> /dev/null || :
	-docker rmi $(DOCKER_TAG) 2> /dev/null || :

.PHONY: default all build run check stop publish publish-service clean
