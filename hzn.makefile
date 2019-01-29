## ARCHITECTURE
ARCH=$(shell uname -m | sed -e 's/aarch64.*/arm64/' -e 's/x86_64.*/amd64/' -e 's/armv.*/arm/')
BUILD_ARCH=$(shell arch)

## HZN
HEU := $(if $(HEU),$(HEU),$(shell hzn node list | jq -r '.configuration.exchange_api'))

## BUILD
BUILD_FROM=$(shell jq -r ".build_from.${BUILD_ARCH}" build.json)

## HORIZON
HZN_ORG ?= $(shell jq -r '.org' service.json)

## SERVICE
SERVICE_LABEL = $(shell jq -r '.label' service.json)
SERVICE_VERSION = $(shell jq -r '.version' service.json)
SERVICE_TAG = "${HZN_ORG}/${URL}_${SERVICE_VERSION}_${ARCH}"
SERVICE_PORT = $(shell jq -r '.deployment.services.'${SERVICE_LABEL}'.specific_ports?|first|.HostPort' service.json | sed 's|/tcp||')
SERVICE_URL := $(if $(HZN_URL),$(HZN_URL).$(SERVICE_LABEL),$(shell jq -r '.url' service.json))

## KEYS
PRIVATE_KEY_FILE = $(wildcard ../IBM-*.key)
PUBLIC_KEY_FILE = $(wildcard ../IBM-*.pem)
APIKEY = $(shell jq -r '.apiKey' ../apiKey.json)
KEYS = $(PRIVATE_KEY_FILE) $(PUBLIC_KEY_FILE) $(APIKEY)

## docker
DOCKER_ID = $(if $(DOCKER_ID),$(DOCKER_ID),$(whoami))
DOCKER_NAME = $(ARCH)_$(SERVICE_LABEL)
DOCKER_TAG = $(DOCKER_ID)/$(DOCKER_NAME):$(SERVICE_VERSION)
DOCKER_PORT = $(shell jq -r '.ports?|to_entries|first|.key?' service.json | sed 's|/tcp||') 

default: build run check

all: publish verify start validate

build: build.json service.json
	docker build --build-arg BUILD_ARCH=$(BUILD_ARCH) --build-arg BUILD_FROM=$(BUILD_FROM) . -t "$(DOCKER_TAG)"

run: remove
	../docker-run.sh "$(DOCKER_NAME)" "$(DOCKER_TAG)"

remove:
	-docker rm -f $(DOCKER_NAME) 2> /dev/null || :

check: service.json
	rm -f check.json
	curl -sSL 'http://localhost:'${DOCKER_PORT} -o check.json && jq '.' check.json

push: build
	docker push ${DOCKER_TAG}

publish: build test $(KEYS)
	hzn exchange service publish  -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE} -f test/service.definition.json -o ${HZN_ORG} -u iamapikey:${APIKEY}

verify: publish
	# should return 'true'
	hzn exchange service list -o ${HZN_ORG} -u iamapikey:${APIKEY} | jq '.|to_entries[]|select(.value=="'${SERVICE_TAG}'")!=null'
	# should return 'All signatures verified'
	hzn exchange service verify --public-key-file ${PUBLIC_KEY_FILE} -o ${HZN_ORG} -u iamapikey:${APIKEY} "${SERVICE_TAG}"

test: service.json userinput.json
	rm -fr test/
	export HZN_EXCHANGE_URL=${HEU} && hzn dev service new -o "${HZN_ORG}" -d test
	jq '.arch="'${ARCH}'"|.deployment.services.'${SERVICE_LABEL}'.image="'${DOCKER_TAG}'"' service.json | sed "s/{arch}/${ARCH}/g" > test/service.definition.json
	cp -f userinput.json test/userinput.json

depend: test
	export HZN_EXCHANGE_URL=${HEU} HZN_EXCHANGE_USERAUTH=${HZN_ORG}/iamapikey:${APIKEY} && ../mkdepend.sh test/

start: remove stop publish depend
	export HZN_EXCHANGE_URL=${HEU} && hzn dev service verify -d test/
	export HZN_EXCHANGE_URL=${HEU} && hzn dev service start -d test/

stop: test
	-export HZN_EXCHANGE_URL=${HEU} && hzn dev service stop -d test/

clean: remove stop
	rm -fr test/ check.*
	-docker rmi $(DOCKER_TAG) 2> /dev/null || :

.PHONY: default all build run check stop push publish verify clean depend start
