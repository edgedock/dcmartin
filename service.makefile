## ARCHITECTURE
BUILD_ARCH ?= $(if $(wildcard BUILD_ARCH),$(shell cat BUILD_ARCH),$(shell uname -m | sed -e 's/aarch64.*/arm64/' -e 's/x86_64.*/amd64/' -e 's/armv.*/arm/'))

## IDENTIFICATION
HZN_ORG_ID ?= $(if $(wildcard ../HZN_ORG_ID),$(shell cat ../HZN_ORG_ID),HZN_ORG_ID_UNSPECIFIED)

## GIT
GIT_REMOTE_URL=$(shell git remote get-url origin)

## HZN
CMD := $(shell whereis hzn | awk '{ print $1 }')
HEU := $(if ${HZN_EXCHANGE_URL},${HZN_EXCHANGE_URL},$(if $(CMD),$(shell $(CMD) node list 2> /dev/null | jq -r '.configuration.exchange_api'),))
HEU := $(if ${HEU},${HEU},"https://alpha.edge-fabric.com/v1")
IBM ?= $(shell ibmcloud account show | egrep "Account Owner" | sed 's/.*:[ ]*\([^ ]*\) /\1/g')
DIR ?= horizon
TAG ?= $(if $(wildcard ../TAG),$(shell cat ../TAG),)

## SERVICE
SERVICE_LABEL := $(shell jq -r '.deployment.services|to_entries|first|.key' service.json)
SERVICE_LABEL := $(if $(SERVICE_LABEL),$(SERVICE_LABEL),$(shell pwd -P | sed 's|.*/||'))
SERVICE_NAME = $(if ${TAG},${SERVICE_LABEL}-${TAG},${SERVICE_LABEL})
SERVICE_VERSION = $(shell jq -r '.version' service.json | envsubst)
SERVICE_TAG = "${HZN_ORG_ID}/${SERVICE_URL}_${SERVICE_VERSION}_${BUILD_ARCH}"
SERVICE_PORT := $(shell jq -r '.deployment.services.'hello'.specific_ports?|first|.HostPort' service.json | sed 's/\([^:]*\):\([^\/]*\).*/\2/')
SERVICE_URI := $(shell jq -r '.url' service.json | envsubst)
SERVICE_URL = $(if ${TAG},${SERVICE_URI}-${TAG},${SERVICE_URI})
SERVICE_REQVARS := $(shell jq -r '.userInput[]|select(.defaultValue==null).name' service.json 2> /dev/null)
SERVICE_VARIABLES := $(shell jq -r '.userInput[].name' service.json 2> /dev/null)
SERVICE_ARCH_SUPPORT := $(shell jq -r '.build_from|to_entries[]|select(.value!=null).key' build.json 2> /dev/null)

## KEYS
PRIVATE_KEY_FILE := $(if $(wildcard ../${HZN_ORG_ID}*.key),$(wildcard ../${HZN_ORG_ID}*.key),MISSING_PRIVATE_KEY_FILE)
PUBLIC_KEY_FILE := $(if $(wildcard ../${HZN_ORG_ID}*.pem),$(wildcard ../${HZN_ORG_ID}*.pem),MISSING_PUBLIC_KEY_FILE)
KEYS := $(PRIVATE_KEY_FILE) $(PUBLIC_KEY_FILE)

## IBM Cloud API Key
APIKEY := $(if $(wildcard ../APIKEY),$(shell cat ../APIKEY > APIKEY && echo APIKEY),$(if $(wildcard ../apiKey.json),$(shell jq -r '.apiKey' ../apiKey.json > APIKEY && echo APIKEY),APIKEY_NOT_FOUND))

## docker
DOCKER_REGISTRY ?= $(if $(wildcard ../DOCKER_REGISTRY),$(shell cat ../DOCKER_REGISTRY),$(if $(wildcard ../registry.json),$(shell jq -r '.registry' ../registry.json),))
DOCKER_NAMESPACE ?= $(if $(wildcard ../DOCKER_NAMESPACE),$(shell cat ../DOCKER_NAMESPACE),$(if $(wildcard ../registry.json),$(shell jq -r '.namespace' ../registry.json),))
DOCKER_REPOSITORY ?= $(if $(DOCKER_REGISTRY),$(DOCKER_REGISTRY)/$(DOCKER_NAMESPACE),$(DOCKER_NAMESPACE))
DOCKER_LOGIN := $(if $(wildcard ../DOCKER_LOGIN),$(shell cat ../DOCKER_LOGIN),$(if $(wildcard ../registry.json),token,))
DOCKER_PASSWORD := $(if $(wildcard ../DOCKER_PASSWORD),$(shell cat ../DOCKER_PASSWORD),$(if $(wildcard ../registry.json),$(shell jq -r '.private' ../registry.json),))
DOCKER_PUBLICKEY := $(if $(wildcard ../DOCKER_PUBLICKEY),$(shell cat ../DOCKER_PUBLICKEY),$(if $(wildcard ../registry.json),$(shell jq -r '.public' ../registry.json),))
DOCKER_SERVER := $(if $(DOCKER_REGISTRY),$(DOCKER_REGISTRY),"docker.io")
DOCKER_CONFIG := $(if $(wildcard ~/.docker/config.json),$(shell jq -r '.auths|to_entries[]|select(.key|test("'$(DOCKER_SERVER)'"))' ~/.docker/config.json 2> /dev/null),)
DOCKER_LOGIN ?= $(if $(DOCKER_CONFIG),$(shell echo $(DOCKER_CONFIG) | jq -r '.value.auth' | base64 --decode | awk -F: '${ print $1 }'),)
DOCKER_PASSWORD ?= $(if $(DOCKER_CONFIG),$(shell echo $(DOCKER_CONFIG) | jq -r '.value.auth' | base64 --decode | awk -F: '${ print $2 }'),)
DOCKER_NAME = $(BUILD_ARCH)_$(SERVICE_URL)
DOCKER_TAG := $(DOCKER_REPOSITORY)/$(DOCKER_NAME):$(SERVICE_VERSION)
DOCKER_PORT ?= $(shell jq -r '.ports?|to_entries?|first|.value?' service.json)
DOCKER_PORT := $(if ${DOCKER_PORT},${DOCKER_PORT},12345)

## BUILD
BUILD_BASE=$(shell export DOCKER_REGISTRY=$(DOCKER_REGISTRY) DOCKER_NAMESPACE=${DOCKER_NAMESPACE} DOCKER_REPOSITORY=$(DOCKER_REPOSITORY) && jq -r ".build_from.${BUILD_ARCH}" build.json | envsubst)
BUILD_ORG=$(shell echo $(BUILD_BASE) | sed "s|\(.*\)/[^/]*|\1|")
SAME_ORG=$(shell if [ $(BUILD_ORG) = $(DOCKER_REPOSITORY) ]; then echo ${DOCKER_REPOSITORY}; else echo ""; fi)
BUILD_PKG=$(shell echo $(BUILD_BASE) | sed "s|.*/\([^:]*\):.*|\1|")
BUILD_TAG=$(shell echo $(BUILD_BASE) | sed "s|.*/[^:]*:\(.*\)|\1|")
BUILD_FROM=$(if ${TAG},$(if ${SAME_ORG},${BUILD_ORG}/${BUILD_PKG}-${TAG}:${BUILD_TAG},${BUILD_BASE}),${BUILD_BASE})

## TEST
TEST_JQ_FILTER ?= $(if $(wildcard TEST_JQ_FILTER),$(shell egrep -v '^\#' TEST_JQ_FILTER | head -1),".")
TEST_NODE_FILTER ?= $(if $(wildcard TEST_NODE_FILTER),$(shell egrep -v '^\#' TEST_NODE_FILTER | head -1),".test=.")
TEST_NODE_TIMEOUT = 10
# temporary
TEST_NODE_NAMES = $(if $(wildcard TEST_TMP_MACHINES),$(shell egrep -v '^\#' TEST_TMP_MACHINES),localhost)

##
## targets
##

default: build run check

all: service-push service-publish service-verify pattern-publish pattern-validate

##
## support
##

$(PRIVATE_KEY_FILE) $(PUBLIC_KEY_FILE):
	@echo "*** ERROR -- cannot locate $@; use command \"hzn key create\" to create keys; exiting"  &> /dev/stderr && exit 1

## development

${DIR}: service.json userinput.json $(APIKEY)
	@rm -fr ${DIR}/ && mkdir -p ${DIR}/
	@export HZN_ORG_ID=${HZN_ORG_ID} HZN_EXCHANGE_URL=${HEU} && hzn dev service new -d ${DIR}
	@jq '.org="'${HZN_ORG_ID}'"|.label="'${SERVICE_LABEL}'"|.arch="'${BUILD_ARCH}'"|.url="'${SERVICE_URL}'"|.deployment.services=([.deployment.services|to_entries[]|select(.key=="'${SERVICE_LABEL}'")|.key="'${SERVICE_LABEL}'"|.value.image="'${DOCKER_TAG}'"]|from_entries)' service.json > ${DIR}/service.definition.json
	@export SERVICE_URL=${SERVICE_URL} HZN_ORG_ID=${HZN_ORG_ID} && cat userinput.json | envsubst > ${DIR}/userinput.json
	@export HZN_EXCHANGE_URL=${HEU} TAG=${TAG} && ./sh/fixservice.sh ${DIR}

#${DIR}/userinput.json: userinput.json ${DIR}
#	@export SERVICE_URL=${SERVICE_URL} HZN_ORG_ID=${HZN_ORG_ID} && cat userinput.json | envsubst > ${DIR}/userinput.json
#	@./sh/checkvars.sh ${DIR}

#${DIR}/pattern.json: pattern.json ${DIR}
#	@export TAG=${TAG} HZN_ORG_ID=${HZN_ORG_ID} SERVICE_LABEL=${SERVICE_LABEL} SERVICE_VERSION=${SERVICE_VERSION} SERVICE_URL=${SERVICE_URL} && ./sh/fixpattern.sh ${DIR}

depend: $(APIKEY) ${DIR}
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- fetching dependencies; service: ${SERVICE_LABEL}; dir: ${DIR}""${NC}" &> /dev/stderr
	@export HZN_ORG_ID=${HZN_ORG_ID} HZN_EXCHANGE_URL=${HEU} HZN_EXCHANGE_USERAUTH=${HZN_ORG_ID}/iamapikey:$(shell cat $(APIKEY)) TAG=${TAG} && ./sh/mkdepend.sh ${DIR}

##
## CONTAINERS
##

logs:
	@docker logs -f "${DOCKER_NAME}"

run: remove stop-service
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- running container: ${DOCKER_TAG}; name: ${DOCKER_NAME}""${NC}" &> /dev/stderr
	@export DOCKER_PORT=$(DOCKER_PORT) SERVICE_PORT=$(SERVICE_PORT) && ./sh/docker-run.sh "$(DOCKER_NAME)" "$(DOCKER_TAG)"
	@sleep 2

remove:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- removing container named: ${DOCKER_NAME}""${NC}" &> /dev/stderr
	-@docker rm -f $(DOCKER_NAME) &> /dev/null

check:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- checking container: ${DOCKER_TAG}; URL: http://localhost:${DOCKER_PORT}""${NC}" &> /dev/stderr
	@rm -f check.json
	@export JQ_FILTER="$(TEST_JQ_FILTER)" && curl -sSL "http://localhost:${DOCKER_PORT}" -o check.json && jq "$${JQ_FILTER}" check.json

login: ~/.docker/config.json
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- login to $(DOCKER_SERVER)""${NC}" &> /dev/stderr
	@echo $(DOCKER_PASSWORD) | docker login -u ${DOCKER_LOGIN} --password-stdin  ${DOCKER_SERVER} 2> /dev/null \
	    || docker login 2> /dev/null \
	    || echo "${RED}>>>${NC} MAKE **" $$(date +%T) "** docker login failed ${DOCKER_SERVER}""${NC}" &> /dev/stderr; \

push: build login
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- pushing container: ${DOCKER_TAG}""${NC}" &> /dev/stderr
	@docker push ${DOCKER_TAG}

##
## TEST
##

TEST_RESULT = ./test.${BUILD_ARCH}_${SERVICE_URL}_${SERVICE_VERSION}.out
TEST_OUTPUT = ./test.${BUILD_ARCH}_${SERVICE_URL}_${SERVICE_VERSION}.json

##
## SERVICES
##

## build

BUILD_OUT = build.${BUILD_ARCH}_${SERVICE_URL}_${SERVICE_VERSION}.out

build: Dockerfile build.json service.json rootfs Makefile
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- $(SERVICE_LABEL) building: ${SERVICE_NAME}; tag: ${DOCKER_TAG}""${NC}" &> /dev/stderr
	@export DOCKER_TAG="${DOCKER_TAG}" && docker build --build-arg BUILD_REF=$$(git rev-parse --short HEAD) --build-arg BUILD_DATE=$$(date -u +"%Y-%m-%dT%H:%M:%SZ") --build-arg BUILD_ARCH="$(BUILD_ARCH)" --build-arg BUILD_FROM="$(BUILD_FROM)" --build-arg BUILD_VERSION="${SERVICE_VERSION}" . -t "$(DOCKER_TAG)" > ${BUILD_OUT}


build-service: build
	@if [ -s "${BUILD_OUT}" ]; then cat "${BUILD_OUT}"; else echo "${RED}*** ERROR -- no build output: ${BUILD_OUT}${NC}" &> /dev/stderr; fi

service-build:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- building service: ${SERVICE_NAME}; architectures: ${SERVICE_ARCH_SUPPORT}""${NC}" &> /dev/stderr
	@for arch in $(SERVICE_ARCH_SUPPORT); do \
	  $(MAKE) TAG=$(TAG) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_REPOSITORY=$(DOCKER_REPOSITORY) BUILD_ARCH="$${arch}" build-service; \
	done

## push

push-service: 
	@$(MAKE) TAG=$(TAG) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_REPOSITORY=$(DOCKER_REPOSITORY) BUILD_ARCH=$(BUILD_ARCH) push

service-push: 
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- pushing service: ${SERVICE_NAME}; architectures: ${SERVICE_ARCH_SUPPORT}""${NC}" &> /dev/stderr
	@for arch in $(SERVICE_ARCH_SUPPORT); do \
	  $(MAKE) TAG=$(TAG) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_REPOSITORY=$(DOCKER_REPOSITORY) BUILD_ARCH="$${arch}" push-service; \
	done

## start & stop

service-start: start-service
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- started service: ${SERVICE_NAME}; directory: $(DIR)/""${NC}" &> /dev/stderr

start-service: remove stop-service depend
	@./sh/checkvars.sh ${DIR}
	@export HZN_ORG_ID=$(HZN_ORG_ID) HZN_EXCHANGE_URL=${HEU} && hzn dev service verify -d ${DIR}
	@export HZN_ORG_ID=$(HZN_ORG_ID) HZN_EXCHANGE_URL=${HEU} && hzn dev service start -S -d ${DIR}

start:

service-stop:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- stopped service: ${SERVICE_NAME}; directory: $(DIR)/""${NC}" &> /dev/stderr

stop-service: 
	-@if [ -d "${DIR}" ]; then export HZN_ORG_ID=$(HZN_ORG_ID) HZN_EXCHANGE_URL=${HEU} && hzn dev service stop -d ${DIR}; fi
	-@$(MAKE) DOCKER_NAME=$(DOCKER_NAME) stop

stop:
	@docker stop "${DOCKER_NAME}"

	
## test

service-test:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- testing service: ${SERVICE_NAME}; architectures: ${SERVICE_ARCH_SUPPORT}""${NC}" &> /dev/stderr
	@for arch in $(SERVICE_ARCH_SUPPORT); do \
	  $(MAKE) TAG=$(TAG) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_REPOSITORY=$(DOCKER_REPOSITORY) BUILD_ARCH="$${arch}" test-service; \
	done

test-service: start-service
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- testing service: ${SERVICE_NAME}; version: ${SERVICE_VERSION}; arch: $(BUILD_ARCH)""${NC}" &> /dev/stderr
	-@$(MAKE) test > $(TEST_RESULT)
	-@${MAKE} stop-service

test:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- testing container: ${DOCKER_TAG}""${NC}" &> /dev/stderr
	@./sh/test.sh "${DOCKER_TAG}"
 
## publish & verify

service-publish: 
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- publishing service: ${SERVICE_NAME}; architectures: ${SERVICE_ARCH_SUPPORT}""${NC}" &> /dev/stderr
	@for arch in $(SERVICE_ARCH_SUPPORT); do \
	  $(MAKE) TAG=$(TAG) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_REPOSITORY=$(DOCKER_REPOSITORY) BUILD_ARCH="$${arch}" publish-service; \
	done

publish-service: publish
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- published service: $(SERVICE_NAME); architecture: ${BUILD_ARCH}""${NC}" &> /dev/stderr

publish: ${DIR} $(APIKEY) $(KEYS)
	@export HZN_ORG_ID=$(HZN_ORG_ID) HZN_EXCHANGE_URL=${HEU} && if [ ! -z "$(DOCKER_PUBLICKEY)" ]; then ARGS="-r $(DOCKER_REGISTRY):iamapikey:$(DOCKER_PUBLICKEY)"; fi && hzn exchange service publish  -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE} -f ${DIR}/service.definition.json -o ${HZN_ORG_ID} -u iamapikey:$(shell cat $(APIKEY)) $${ARGS:-}

service-verify: 
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- verifying service: ${SERVICE_NAME}; architectures: ${SERVICE_ARCH_SUPPORT}""${NC}" &> /dev/stderr
	@for arch in $(SERVICE_ARCH_SUPPORT); do \
	  $(MAKE) TAG=$(TAG) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_REPOSITORY=$(DOCKER_REPOSITORY) BUILD_ARCH="$${arch}" verify-service; \
	done

verify-service: verify
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- verified service: $(SERVICE_NAME); architecture: ${BUILD_ARCH}""${NC}" &> /dev/stderr

verify:$(APIKEY) $(KEYS)
	@export HZN_ORG_ID=$(HZN_ORG_ID) HZN_EXCHANGE_URL=${HEU} && hzn exchange service verify --public-key-file ${PUBLIC_KEY_FILE} -o ${HZN_ORG_ID} -u iamapikey:$(shell cat $(APIKEY)) "${SERVICE_TAG}"

## clean local & exchange

service-clean:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- service-clean: ${SERVICE_NAME}; architectures: ${SERVICE_ARCH_SUPPORT}""${NC}" &> /dev/stderr
	@for arch in $(SERVICE_ARCH_SUPPORT); do \
	  $(MAKE) TAG=$(TAG) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_REPOSITORY=$(DOCKER_REPOSITORY) BUILD_ARCH="$${arch}" clean; \
	done

exchange-clean: ${DIR}
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- exchange-clean: $(SERVICE_NAME); organization: ${HZN_ORG_ID}""${NC}" &> /dev/stderr
	@./sh/service-clean.sh

##
## PATTERNS
##

pattern-test:
	@export HZN_EXCHANGE_URL=${HEU} && ./sh/pattern-test.sh 

pattern-publish: ${APIKEY} pattern.json
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- publishing: ${SERVICE_NAME}; organization: ${HZN_ORG_ID}; exchange: ${HEU}""${NC}" &> /dev/stderr
	@export TAG=${TAG} HZN_ORG_ID=${HZN_ORG_ID} SERVICE_LABEL=${SERVICE_LABEL} SERVICE_VERSION=${SERVICE_VERSION} SERVICE_URL=${SERVICE_URL} && ./sh/fixpattern.sh ${DIR}
	@export HZN_ORG_ID=$(HZN_ORG_ID) HZN_EXCHANGE_URL=${HEU} && hzn exchange pattern publish -o "${HZN_ORG_ID}" -u iamapikey:$(shell cat $(APIKEY)) -f ${DIR}/pattern.json -p ${SERVICE_NAME} -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE}

pattern-validate: pattern.json
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- validating: ${SERVICE_NAME}; organization: ${HZN_ORG_ID}; exchange: ${HEU}""${NC}" &> /dev/stderr
	@export HZN_ORG_ID=$(HZN_ORG_ID) HZN_EXCHANGE_URL=${HEU} && hzn exchange pattern verify -o "${HZN_ORG_ID}" -u iamapikey:$(shell cat $(APIKEY)) --public-key-file ${PUBLIC_KEY_FILE} ${SERVICE_NAME}
	@export HZN_ORG_ID=$(HZN_ORG_ID) HZN_EXCHANGE_URL=${HEU} && FOUND=false && for pattern in $$(hzn exchange pattern list -o "${HZN_ORG_ID}" -u iamapikey:$(shell cat $(APIKEY)) | jq -r '.[]'); do if [ "$${pattern}" = "${HZN_ORG_ID}/${SERVICE_NAME}" ]; then found=true; break; fi; done && if [ -z $${found} ]; then echo "Did not find $(HZN_ORG_ID)/$(SERVICE_NAME)"; exit 1; else echo "Found pattern $${pattern}"; fi

##
## NODES
##

nodes-test: $(TEST_NODE_NAMES)
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- tested: $(SERVICE_NAME); nodes: ${TEST_NODE_NAMES}; date: $$(date)""${NC}" &> /dev/stderr

$(TEST_NODE_NAMES):
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- testing: ${SERVICE_NAME}; node: ${@}; port: $(SERVICE_PORT); date: $$(date)""${NC}" &> /dev/stderr
	-@export JQ_FILTER="$(TEST_NODE_FILTER)" && START=$$(date +%s) && curl --connect-timeout $(TEST_NODE_TIMEOUT) -fsSL "http://${@}:${SERVICE_PORT}" -o test.${@}.json && FINISH=$$(date +%s) && echo "ELAPSED:" $$((FINISH-START)) && jq -c "$${JQ_FILTER}" test.${@}.json | jq -c '.test'

nodes-list:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- listing nodes: ${TEST_NODE_NAMES}""${NC}" &> /dev/stderr
	@for machine in $(TEST_NODE_NAMES); do \
	  echo "${MC}>>> MAKE --" $$(date +%T) "-- listing $${machine}""${NC}" &> /dev/stderr; \
          ping -W 1 -c 1 $${machine} &> /dev/null \
	    && ssh $${machine} 'hzn node list' | jq -c '{"node":.id}' \
	    && ssh $${machine} 'hzn agreement list' | jq -c '{"agreements":[.[].workload_to_run]}' \
	    && ssh $${machine} 'hzn service list 2> /dev/null' | jq -c '{"services":[.[]?.url]}' \
	    && ssh $${machine} 'docker ps --format "{{.Names}},{{.Image}}"' | awk -F, '{ printf("{\"name\":\"%s\",\"image\":\"%s\"}\n", $$1, $$2) }' | jq -c '{"container":.name}' \
	    || echo "${RED}>>> MAKE **" $$(date +%T) "** not found $${machine}""${NC}" &> /dev/stderr; \
	done

nodes: ${DIR}/userinput.json
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- registering nodes: ${TEST_NODE_NAMES}""${NC}" &> /dev/stderr
	@./sh/checkvars.sh ${DIR}
	@for machine in $(TEST_NODE_NAMES); do \
	  echo "${MC}>>> MAKE --" $$(date +%T) "-- registering $${machine}" "${NC}"; \
	  export HZN_ORG_ID=${HZN_ORG_ID} HZN_EXCHANGE_APIKEY=$(shell cat $(APIKEY)) && ./sh/nodereg.sh $${machine} ${SERVICE_NAME} ${DIR}/userinput.json; \
	done

nodes-undo:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- unregistering nodes: ${TEST_NODE_NAMES}""${NC}" &> /dev/stderr
	@for machine in $(TEST_NODE_NAMES); do \
	  echo "${MC}>>> MAKE --" $$(date +%T) "-- unregistering $${machine}" "${NC}"; \
	  ping -W 1 -c 1 $${machine} &> /dev/null \
	    && ssh $${machine} 'hzn unregister -fr &> ~/undo.log &' \
	    || echo "${RED}>>> MAKE **" $$(date +%T) "** not found $${machine}""${NC}" &> /dev/stderr; \
	done

nodes-clean: nodes-undo
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- cleaning nodes: ${TEST_NODE_NAMES}""${NC}" &> /dev/stderr
	@for machine in $(TEST_NODE_NAMES); do \
	  echo "${MC}>>> MAKE --" $$(date +%T) "-- cleaning $${machine}" "${NC}"; \
	  ping -W 1 -c 1 $${machine} &> /dev/null \
	    && ssh $${machine} 'IDS=$$(docker ps --format "{{.ID}}") && if [ ! -z "${IDS}" ]; then docker rm -f ${IDS}; fi || docker system prune -fa &> ~/prune.log &' \
	    || echo "${RED}>>> MAKE **" $$(date +%T) "** not found $${machine}""${NC}" &> /dev/stderr; \
	done

nodes-purge: nodes-undo nodes-clean
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- purging nodes: ${TEST_NODE_NAMES}""${NC}" &> /dev/stderr
	@for machine in $(TEST_NODE_NAMES); do \
	  echo "${MC}>>> MAKE --" $$(date +%T) "-- purging $${machine}" "${NC}" &> /dev/stderr; \
	  ping -W 1 -c 1 $${machine} &> /dev/null \
	    && ssh $${machine} 'sudo apt-get remove -y bluehorizon horizon horizon-cli &> ~/remove.log || sudo apt-get purge -y bluehorizon horizon horizon-cli &> ~/purge.log &' \
	    || echo "${RED}"">>> MAKE **" $$(date +%T) "** not found $${machine}""${NC}" &> /dev/stderr; \
	done

##
## CLEANUP
##

clean: remove stop-service
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- cleaning: ${SERVICE_NAME}; tag: ${DOCKER_TAG}""${NC}" &> /dev/stderr
	@rm -fr ${DIR} check.json build.*.out test.*.out test.*.json test.*.jpeg make.out
	-@docker rmi $(DOCKER_TAG) 2> /dev/null || :

distclean: service-clean
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- cleaning: distribution""${NC}" &> /dev/stderr
	@rm -fr $(KEYS) $(APIKEY) $(SERVICE_REQVARS) ${SERVICE_VARIABLES} TEST_TMP_*

##
## BOOKKEEPING
##

.PHONY: default all build run check test push start-service stop-service service-start service-stop service-test test-service service-publish publish-service service-verify $(TEST_NODE_NAMES) clean distclean depend 

##
## COLORS
##
MC=${LIGHT_CYAN}
NC=${NO_COLOR}

NO_COLOR=\033[0m
BLACK=\033[0;30m
RED=\033[0;31m
GREEN=\033[0;32m
BROWN_ORANGE=\033[0;33m
BLUE=\033[0;34m
PURPLE=\033[0;35m
CYAN=\033[0;36m
LIGHT_GRAY=\033[0;37m

DARK_GRAY=\033[1;30m
LIGHT_RED=\033[1;31m
LIGHT_GREEN=\033[1;32m
YELLOW=\033[1;33m
LIGHT_BLUE=\033[1;34m
LIGHT_PURPLE=\033[1;35m
LIGHT_CYAN=\033[1;36m
WHITE=\034[1;37m
