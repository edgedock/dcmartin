## ARCHITECTURE
ARCH=$(shell uname -m | sed -e 's/aarch64.*/arm64/' -e 's/x86_64.*/amd64/' -e 's/armv.*/arm/')

## BUILD
BUILD_FROM=$(shell jq -r ".build_from.${ARCH}" build.json)

## SERVICE
ORG=$(shell jq -r '.org' service.json)
LABEL=$(shell jq -r '.label' service.json)
VERSION=$(shell jq -r '.version' service.json)

## TEST PORT
PORT=8585

## KEYS
PRIVATE_KEY_FILE=../IBM-6d570b1519a1030ea94879bbe827db0616b9f554-private.key
PUBLIC_KEY_FILE=../IBM-6d570b1519a1030ea94879bbe827db0616b9f554-public.pem
APIKEY_JSON=../apiKey.json

## IBM CLOUD PLATFORM API KEY
APIKEY=$(shell jq -r '.apiKey' ${APIKEY_JSON})

## docker
DOCKER_HUB_ID=dcmartin
DOCKER_NAME=$(ARCH)_$(LABEL)
DOCKER_TAG=$(DOCKER_HUB_ID)/$(DOCKER_NAME):$(VERSION)

default: all

all: build run check

build: build.json service.json
	docker build --build-arg BUILD_ARCH=$(ARCH) --build-arg BUILD_FROM=$(BUILD_FROM) . -t "$(DOCKER_TAG)"

run: stop 
	docker run -d --name $(DOCKER_NAME) --publish=$(PORT):80 --volume `pwd`':/data' $(DOCKER_TAG)

stop:
	-docker rm -f $(DOCKER_NAME) 2> /dev/null || :

check:	
	sleep 2
	curl -sSL "http://localhost:$(PORT)" | jq -c '.'

push: build
	docker push ${DOCKER_TAG}

publish:
	hzn --verbose exchange service publish  -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE} -f service.json -o ${ORG} -u iamapikey:${APIKEY}

clean:
	-docker rm -f $(DOCKER_NAME) 2> /dev/null || :
	-docker rmi $(DOCKER_TAG) 2> /dev/null || :

.PHONY: default all build run check stop push publish clean
