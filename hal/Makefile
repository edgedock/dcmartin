## ARCHITECTURE
ARCH=$(shell uname -m | sed -e 's/aarch64.*/arm64/' -e 's/x86_64.*/amd64/' -e 's/armv.*/arm/')
BUILD_ARCH=$(shell arch)

## BUILD
BUILD_FROM=$(shell jq -r ".build_from.${BUILD_ARCH}" build.json)

## SERVICE
ORG=$(shell jq -r '.org' service.json)
URL=$(shell jq -r '.url' service.json)
LABEL=$(shell jq -r '.label' service.json)
VERSION=$(shell jq -r '.version' service.json)
SERVICE_TAG="${ORG}/${URL}_${VERSION}_${ARCH}"

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
	docker build --build-arg BUILD_ARCH=$(BUILD_ARCH) --build-arg BUILD_FROM=$(BUILD_FROM) . -t "$(DOCKER_TAG)"

run: stop 
	# docker run -d --name $(DOCKER_NAME) --publish=$(PORT):80 --volume `pwd`':/data' $(DOCKER_TAG)
	docker run -d --name $(DOCKER_NAME) --publish=$(PORT):80 $(DOCKER_TAG)

stop:
	-docker rm -f $(DOCKER_NAME) 2> /dev/null || :

check:	
	sleep 2
	curl -sSL "http://localhost:$(PORT)" | jq -c '.'

push: build
	docker push ${DOCKER_TAG}

publish:
	jq '.|.arch="'${ARCH}'"|.deployment.services.'${LABEL}'.image="'${DOCKER_TAG}'"' service.json > service-${ARCH}.json
	hzn exchange service publish  -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE} -f service-${ARCH}.json -o ${ORG} -u iamapikey:${APIKEY}

verify:
	# "dcmartin@us.ibm.com/com.github.dcmartin.open-horizon.hal_0.0.1_arm64"
	hzn exchange service list -o ${ORG} -u iamapikey:${APIKEY} | jq '.|to_entries[]|select(.value=="'${SERVICE_TAG}'")!=null'
	hzn exchange service verify --public-key-file ${PUBLIC_KEY_FILE} -o ${ORG} -u iamapikey:${APIKEY} "${SERVICE_TAG}"

clean:
	-docker rm -f $(DOCKER_NAME) 2> /dev/null || :
	-docker rmi $(DOCKER_TAG) 2> /dev/null || :

.PHONY: default all build run check stop push publish clean
