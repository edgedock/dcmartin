## ARCHITECTURE
ARCH=$(shell uname -m | sed -e 's/aarch64.*/arm64/' -e 's/x86_64.*/amd64/' -e 's/armv.*/arm/')
BUILD_ARCH=$(shell arch)

## HZN
CMD := $(shell whereis hzn | awk '{ print $1 }')
HZN := $(if $(HZN),$(HZN),$(if $(CMD),$(shell $(CMD) node list 2> /dev/null | jq -r '.configuration.exchange_api'),))
HZN := $(if $(HZN),$(HZN),"https://alpha.edge-fabric.com/v1/")
DIR ?= horizon

## BUILD
BUILD_FROM=$(shell jq -r ".build_from.${BUILD_ARCH}" build.json)

## SERVICE
SERVICE_ORG := $(if ${ORG},${ORG},$(shell jq -r '.org' service.json))
SERVICE_LABEL = $(shell jq -r '.label' service.json)
SERVICE_NAME = $(if ${TAG},${SERVICE_LABEL}-${TAG},${SERVICE_LABEL})
SERVICE_VERSION = $(shell jq -r '.version' service.json)
SERVICE_TAG = "${SERVICE_ORG}/${SERVICE_URL}_${SERVICE_VERSION}_${ARCH}"
SERVICE_PORT = $(shell jq -r '.deployment.services.'${SERVICE_LABEL}'.specific_ports?|first|.HostPort' service.json | sed 's|/tcp||')
SERVICE_URI := $(shell jq -r '.url' service.json)
SERVICE_URL := $(if $(URL),$(URL).$(SERVICE_NAME),$(if ${TAG},${SERVICE_URI}-${TAG},${SERVICE_URI}))
SERVICE_REQVARS := $(shell jq -r '.userInput[]|select(.defaultValue==null).name' service.json)

## KEYS
PRIVATE_KEY_FILE := $(if $(wildcard ../IBM-*.key),$(wildcard ../IBM-*.key),PRIVATE_KEY_FILE)
PUBLIC_KEY_FILE := $(if $(wildcard ../IBM-*.pem),$(wildcard ../IBM-*.pem),PUBLIC_KEY_FILE)
KEYS = $(PRIVATE_KEY_FILE) $(PUBLIC_KEY_FILE)

## IBM Cloud API Key
APIKEY := $(if $(wildcard ../apiKey.json),$(shell jq -r '.apiKey' ../apiKey.json > APIKEY && echo APIKEY),APIKEY)

## docker
DOCKER_ID := $(if $(DOCKER_ID),$(DOCKER_ID),$(shell whoami))
DOCKER_LOGIN := $(if $(wildcard ~/.docker/config.json),,LOGIN_DOCKER_HUB)
DOCKER_NAME = $(ARCH)_$(SERVICE_NAME)
DOCKER_TAG = $(DOCKER_ID)/$(DOCKER_NAME):$(SERVICE_VERSION)
DOCKER_PORT = $(shell jq -r '.ports?|to_entries|first|.key?' service.json | sed 's|/tcp||') 

##
## targets
##

default: build run check

all: build run check publish start test pattern validate

build: Dockerfile build.json service.json
	@docker build --build-arg BUILD_ARCH=$(BUILD_ARCH) --build-arg BUILD_FROM=$(BUILD_FROM) . -t "$(DOCKER_TAG)" > build.out

run: remove
	@../docker-run.sh "$(DOCKER_NAME)" "$(DOCKER_TAG)"

remove:
	-@docker rm -f $(DOCKER_NAME) 2> /dev/null || :

check: service.json
	@rm -f check.json
	@curl -sSL 'http://localhost:'${DOCKER_PORT} -o check.json && jq '.' check.json

push: build $(DOCKER_LOGIN)
	@docker push ${DOCKER_TAG}

publish: ${DIR} $(KEYS) $(APIKEY) push
	@export HZN_EXCHANGE_URL=${HZN} && hzn exchange service publish  -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE} -f ${DIR}/service.definition.json -o ${SERVICE_ORG} -u iamapikey:$(shell cat APIKEY)

verify: $(KEYS) $(APIKEY)
	@export HZN_EXCHANGE_URL=${HZN} && hzn exchange service list -o ${SERVICE_ORG} -u iamapikey:$(shell cat APIKEY) | jq '.|to_entries[]|select(.value=="'${SERVICE_TAG}'")!=null'
	@export HZN_EXCHANGE_URL=${HZN} && hzn exchange service verify --public-key-file ${PUBLIC_KEY_FILE} -o ${SERVICE_ORG} -u iamapikey:$(shell cat APIKEY) "${SERVICE_TAG}"

${DIR}: service.json userinput.json $(SERVICE_REQVARS) APIKEY
	@rm -fr ${DIR}/
	@export HZN_EXCHANGE_URL=${HZN} && hzn dev service new -o "${SERVICE_ORG}" -d ${DIR}
	@jq '.label="'${SERVICE_LABEL}'"|.arch="'${ARCH}'"|.url="'${SERVICE_URL}'"|.deployment.services=([.deployment.services|to_entries[]|select(.key=="'${SERVICE_LABEL}'")|.key="'${SERVICE_LABEL}'"|.value.image="'${DOCKER_TAG}'"]|from_entries)' service.json > ${DIR}/service.definition.json
	@cp -f userinput.json ${DIR}/userinput.json
	@../checkvars.sh ${DIR}
	@export HZN_EXCHANGE_URL=${HZN} HZN_EXCHANGE_USERAUTH=${SERVICE_ORG}/iamapikey:$(shell cat APIKEY) && ../mkdepend.sh ${DIR}

start: remove stop publish
	@../checkvars.sh ${DIR} 
	@export HZN_EXCHANGE_URL=${HZN} && hzn dev service verify -d ${DIR}
	@export HZN_EXCHANGE_URL=${HZN} && hzn dev service start -d ${DIR}

test: service.json
	@../test.sh 127.0.0.1:$(DOCKER_PORT)

stop: 
	-@if [ -d "${DIR}" ]; then export HZN_EXCHANGE_URL=${HZN} && hzn dev service stop -d ${DIR}; fi

pattern: publish pattern.json APIKEY
	@export HZN_EXCHANGE_URL=${HZN} && hzn exchange pattern publish -o "${SERVICE_ORG}" -u iamapikey:$(shell cat APIKEY) -f pattern.json -p ${SERVICE_NAME} -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE}

validate:
	@export HZN_EXCHANGE_URL=${HZN} && hzn exchange pattern verify -o "${SERVICE_ORG}" -u iamapikey:$(shell cat APIKEY) --public-key-file ${PUBLIC_KEY_FILE} ${SERVICE_NAME}
	@export HZN_EXCHANGE_URL=${HZN} && FOUND=false && for pattern in $$(hzn exchange pattern list -o "${SERVICE_ORG}" -u iamapikey:$(shell cat APIKEY) | jq -r '.[]'); do if [ "$${pattern}" = "${SERVICE_ORG}/${SERVICE_NAME}" ]; then found=true; break; fi; done && if [ -z $${found} ]; then echo "Did not find $(SERVICE_ORG)/$(SERVICE_NAME)"; exit 1; else echo "Found pattern $${pattern}"; fi

clean: remove stop
	@rm -fr ${DIR} check.json build.out
	-@docker rmi $(DOCKER_TAG) 2> /dev/null || :

dist-clean: clean
	@rm -fr $(KEYS) $(APIKEY) $(SERVICE_REQVARS)

.PHONY: default all build run check stop push publish verify clean start
