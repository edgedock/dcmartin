## ARCHITECTURE
ARCH=$(shell uname -m | sed -e 's/aarch64.*/arm64/' -e 's/x86_64.*/amd64/' -e 's/armv.*/arm/')
BUILD_ARCH=$(shell arch)

## HZN
HZN := $(if $(HZN),$(HZN),$(shell hzn node list | jq -r '.configuration.exchange_api'))
HZN := $(if $(HZN),$(HZN),"https://alpha.edge-fabric.com/v1/")

## BUILD
BUILD_FROM=$(shell jq -r ".build_from.${BUILD_ARCH}" build.json)

## HORIZON
ORG ?= $(shell jq -r '.org' service.json)

## SERVICE
SERVICE_LABEL = $(shell jq -r '.label' service.json)
SERVICE_VERSION = $(shell jq -r '.version' service.json)
SERVICE_TAG = "${ORG}/${URL}_${SERVICE_VERSION}_${ARCH}"
SERVICE_PORT = $(shell jq -r '.deployment.services.'${SERVICE_LABEL}'.specific_ports?|first|.HostPort' service.json | sed 's|/tcp||')
SERVICE_URL := $(if $(URL),$(URL).$(SERVICE_LABEL),$(shell jq -r '.url' service.json))

## KEYS
PRIVATE_KEY_FILE := $(if $(wildcard ../IBM-*.key),$(wildcard ../IBM-*.key),PRIVATE_KEY_FILE)
PUBLIC_KEY_FILE := $(if $(wildcard ../IBM-*.pem),$(wildcard ../IBM-*.pem),PUBLIC_KEY_FILE)
KEYS = $(PRIVATE_KEY_FILE) $(PUBLIC_KEY_FILE)

## IBM Cloud API Key
APIKEY := $(if $(wildcard ../apiKey.json),$(shell jq -r '.apiKey' ../apiKey.json > APIKEY),APIKEY)

## docker
DOCKER_ID := $(if $(DOCKER_ID),$(DOCKER_ID),$(shell whoami))
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

publish: build test $(KEYS) $(APIKEY)
	export HZN_EXCHANGE_URL=${HZN} && hzn exchange service publish  -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE} -f test/service.definition.json -o ${ORG} -u iamapikey:$(shell cat APIKEY)

verify: publish $(KEYS) $(APIKEY)
	# should return 'true'
	export HZN_EXCHANGE_URL=${HZN} && hzn exchange service list -o ${ORG} -u iamapikey:$(shell cat {APIKEY) | jq '.|to_entries[]|select(.value=="'${SERVICE_TAG}'")!=null'
	# should return 'All signatures verified'
	export HZN_EXCHANGE_URL=${HZN} && hzn exchange service verify --public-key-file ${PUBLIC_KEY_FILE} -o ${ORG} -u iamapikey:$(shell cat APIKEY) "${SERVICE_TAG}"

test: service.json userinput.json
	rm -fr test/
	export HZN_EXCHANGE_URL=${HZN} && hzn dev service new -o "${ORG}" -d test
	jq '.arch="'${ARCH}'"|.deployment.services.'${SERVICE_LABEL}'.image="'${DOCKER_TAG}'"' service.json | sed "s/{arch}/${ARCH}/g" > test/service.definition.json
	# for reqs in $$(jq -r '.requiredServices[]|.'
	cp -f userinput.json test/userinput.json
	for evar in $$(jq -r '.userInput[]|select(.defaultValue==null).name' service.json); do VAL=$$(jq -r '.services[]|select(.url=="'${SERVICE_URL}'").variables|to_entries[]|select(.key=="'$${evar}'").value' test/userinput.json) && if [ $${VAL} = "null" ]; then if [ ! -s $${evar} ]; then echo "*** ERROR: variable $${evar} has no default and value is null; edit userinput.json"; exit 1; else VAL=$$(cat $${evar}) && UI=$$(jq '(.services[]|select(.url=="'${SERVICE_URL}'").variables.'$${evar}')|='$${VAL} test/userinput.json) && echo "$${UI}" > test/userinput.json; echo "+++ INFO: $${evar} is $${VAL}"; fi; fi; done

depend: test APIKEY
	export HZN_EXCHANGE_URL=${HZN} HZN_EXCHANGE_USERAUTH=${ORG}/iamapikey:$(shell cat APIKEY) && ../mkdepend.sh test/

start: remove stop publish depend
	export HZN_EXCHANGE_URL=${HZN} && hzn dev service verify -d test/
	export HZN_EXCHANGE_URL=${HZN} && hzn dev service start -d test/

stop: test
	-export HZN_EXCHANGE_URL=${HZN} && hzn dev service stop -d test/

pattern: publish pattern.json APIKEY
	export HZN_EXCHANGE_URL=${HZN} && hzn exchange pattern publish -o "${ORG}" -u iamapikey:$(shell cat APIKEY) -f pattern.json -p ${SERVICE_LABEL} -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE}
	

clean: remove stop
	rm -fr test/ check.*
	-docker rmi $(DOCKER_TAG) 2> /dev/null || :

.PHONY: default all build run check stop push publish verify clean depend start
