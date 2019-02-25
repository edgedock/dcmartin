## ARCHITECTURE
BUILD_ARCH ?= $(shell uname -m | sed -e 's/aarch64.*/arm64/' -e 's/x86_64.*/amd64/' -e 's/armv.*/arm/')

## HZN
CMD := $(shell whereis hzn | awk '{ print $1 }')
HEU := $(if ${HEU},${HEU},$(if $(CMD),$(shell $(CMD) node list 2> /dev/null | jq -r '.configuration.exchange_api'),))
HEU := $(if ${HEU},${HEU},"https://alpha.edge-fabric.com/v1")
DIR ?= horizon
TAG ?= $(if $(wildcard ../TAG),$(shell cat ../TAG),)

## SERVICE
SERVICE_ORG := $(if ${ORG},${ORG},$(shell jq -r '.org' service.json))
SERVICE_LABEL = $(shell jq -r '.label' service.json)
SERVICE_NAME = $(if ${TAG},${SERVICE_LABEL}-${TAG},${SERVICE_LABEL})
SERVICE_VERSION = $(shell jq -r '.version' service.json)
SERVICE_TAG = "${SERVICE_ORG}/${SERVICE_URL}_${SERVICE_VERSION}_${BUILD_ARCH}"
SERVICE_PORT = $(shell jq -r '.deployment.services.'${SERVICE_LABEL}'.specific_ports?|first|.HostPort' service.json | sed 's|/tcp||')
SERVICE_URI := $(shell jq -r '.url' service.json)
SERVICE_URL := $(if $(URL),$(URL).$(SERVICE_NAME),$(if ${TAG},${SERVICE_URI}-${TAG},${SERVICE_URI}))
SERVICE_REQVARS := $(shell jq -r '.userInput[]|select(.defaultValue==null).name' service.json)
SERVICE_VARIABLES := $(shell jq -r '.userInput[].name' service.json)
SERVICE_ARCH_SUPPORT = $(shell jq -r '.build_from|to_entries[].key' build.json)

## KEYS
PRIVATE_KEY_FILE := $(if $(wildcard ../IBM-*.key),$(wildcard ../IBM-*.key),PRIVATE_KEY_FILE)
PUBLIC_KEY_FILE := $(if $(wildcard ../IBM-*.pem),$(wildcard ../IBM-*.pem),PUBLIC_KEY_FILE)
KEYS = $(PRIVATE_KEY_FILE) $(PUBLIC_KEY_FILE)

## IBM Cloud API Key
APIKEY := $(if $(wildcard ../apiKey.json),$(shell jq -r '.apiKey' ../apiKey.json > APIKEY && echo APIKEY),APIKEY)

## docker
DOCKER_ID := $(if $(DOCKER_ID),$(DOCKER_ID),$(shell whoami))
DOCKER_LOGIN := $(if $(wildcard ~/.docker/config.json),,Please_login_to_docker_hub)
DOCKER_NAME = $(BUILD_ARCH)_$(SERVICE_NAME)
DOCKER_TAG = $(DOCKER_ID)/$(DOCKER_NAME):$(SERVICE_VERSION)
DOCKER_PORT = $(shell jq -r '.ports?|to_entries|first|.value?' service.json)

## BUILD
BUILD_BASE=$(shell jq -r ".build_from.${BUILD_ARCH}" build.json)
BUILD_ORG=$(shell echo $(BUILD_BASE) | sed "s|\([^/]*\)/.*|\1|")
SAME_ORG=$(shell if [ $(BUILD_ORG) = $(DOCKER_ID) ]; then echo ${DOCKER_ID}; else echo ""; fi)
BUILD_PKG=$(shell echo $(BUILD_BASE) | sed "s|[^/]*/\([^:]*\):.*|\1|")
BUILD_TAG=$(shell echo $(BUILD_BASE) | sed "s|[^/]*/[^:]*:\(.*\)|\1|")
BUILD_FROM=$(if ${TAG},$(if ${SAME_ORG},${BUILD_ORG}/${BUILD_PKG}-${TAG}:${BUILD_TAG},${BUILD_BASE}),${BUILD_BASE})

## TEST
TEST_JQ_FILTER ?= $(if $(wildcard TEST_JQ_FILTER),$(shell head -1 TEST_JQ_FILTER),)
TEST_NODE_FILTER ?= $(if $(wildcard TEST_NODE_FILTER),$(shell head -1 TEST_NODE_FILTER),)
TEST_NODE_TIMEOUT = 10
# temporary
TEST_NODE_NAMES = $(if $(wildcard TEST_TMP_MACHINES),$(shell cat TEST_TMP_MACHINES),localhost)

##
## targets
##

default: build run check

all: build run check service-publish service-start service-test pattern-publish pattern-validate

##
## support
##

$(PRIVATE_KEY_FILE) $(PUBLIC_KEY_FILE):
	@echo "*** ERROR -- cannot locate $@; use command \"hzn key create\" to create keys; exiting" && exit 1

## development

${DIR}: service.json userinput.json $(SERVICE_REQVARS) $(APIKEY)
	@echo "--- INFO -- building temporary directory $(DIR)/"
	@rm -fr ${DIR}/ && mkdir -p ${DIR}/
	@export HZN_EXCHANGE_URL=${HEU} && hzn dev service new -o "${SERVICE_ORG}" -d ${DIR}
	@jq '.label="'${SERVICE_LABEL}'"|.arch="'${BUILD_ARCH}'"|.url="'${SERVICE_URL}'"|.deployment.services=([.deployment.services|to_entries[]|select(.key=="'${SERVICE_LABEL}'")|.key="'${SERVICE_LABEL}'"|.value.image="'${DOCKER_TAG}'"]|from_entries)' service.json > ${DIR}/service.definition.json
	@cp -f userinput.json ${DIR}/userinput.json
	@export HZN_EXCHANGE_URL=${HEU} HZN_EXCHANGE_USERAUTH=${SERVICE_ORG}/iamapikey:$(shell cat $(APIKEY)) TAG=${TAG} && ./mkdepend.sh ${DIR}

##
## CONTAINERS
##

build: Dockerfile build.json service.json rootfs Makefile
	@echo "--- INFO -- building service ${SERVICE_NAME} with Docker tag ${DOCKER_TAG}"
	@docker build --build-arg BUILD_REF=$$(git rev-parse --short HEAD) --build-arg BUILD_DATE=$$(date -u +"%Y-%m-%dT%H:%M:%SZ") --build-arg BUILD_ARCH="$(BUILD_ARCH)" --build-arg BUILD_FROM="$(BUILD_FROM)" --build-arg BUILD_VERSION="${SERVICE_VERSION}" . -t "$(DOCKER_TAG)" > build.out

build-all:
	@echo "--- INFO -- building service ${SERVICE_NAME} for architectures ${SERVICE_ARCH_SUPPORT}"
	@for arch in $(SERVICE_ARCH_SUPPORT); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) BUILD_ARCH="$${arch}" build; \
	done

logs:
	@docker logs -f "${DOCKER_NAME}"

stop:
	@docker stop "${DOCKER_NAME}"

run: remove service-stop
	@echo "--- INFO -- running container ${DOCKER_NAME} for service ${SERVICE_NAME}"
	@./docker-run.sh "$(DOCKER_NAME)" "$(DOCKER_TAG)"

remove:
	@echo "--- INFO -- removing container ${DOCKER_NAME} for service ${SERVICE_NAME}"
	-@docker rm -f $(DOCKER_NAME) 2> /dev/null || :

check:
	@echo "--- INFO -- checking ${SERVICE_NAME} on ${DOCKER_PORT}"
	@rm -f check.json
	@export JQ_FILTER="$(TEST_JQ_FILTER)" && curl -sSL "http://localhost:${DOCKER_PORT}" -o check.json && jq -c "$${JQ_FILTER}" check.json

push: build $(DOCKER_LOGIN)
	@echo "--- INFO -- pushing container ${DOCKER_TAG} for service ${SERVICE_NAME}"
	@docker push ${DOCKER_TAG}

push-all:
	@echo "--- INFO -- pushing service ${SERVICE_NAME} for architectures ${SERVICE_ARCH_SUPPORT}"
	@for arch in $(SERVICE_ARCH_SUPPORT); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) BUILD_ARCH="$${arch}" push; \
	done

##
## SERVICES
##

${SERVICE_ARCH_SUPPORT}:
	@echo "--- INFO -- building service ${SERVICE_NAME} for architecture $@ with tag ${DOCKER_TAG}"
	@$(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) BUILD_ARCH="$@" build

service-start: remove service-stop ${DIR}
	@echo "--- INFO -- starting ${SERVICE_NAME} from $(DIR)"
	@./checkvars.sh ${DIR}
	@export HZN_EXCHANGE_URL=${HEU} && hzn dev service verify -d ${DIR}
	@export HZN_EXCHANGE_URL=${HEU} && hzn dev service start -d ${DIR}

service-test:
	@echo "--- INFO -- testing ${SERVICE_NAME} on $(SERVICE_PORT)"
	@./test.sh

service-stop: 
	-@if [ -d "${DIR}" ]; then export HZN_EXCHANGE_URL=${HEU} && hzn dev service stop -d ${DIR}; fi
	
service-publish: build $(APIKEY) $(KEYS) ${DIR} $(SERVICE_ARCH_SUPPORT)
	@echo "--- INFO -- publishing service $(SERVICE_NAME)"
	@export HZN_EXCHANGE_URL=${HEU} && ./service-test.sh 
	@export HZN_EXCHANGE_URL=${HEU} && hzn exchange service publish  -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE} -f ${DIR}/service.definition.json -o ${SERVICE_ORG} -u iamapikey:$(shell cat $(APIKEY))

service-publish-all:
	@echo "--- INFO -- publishing services for pattern ${SERVICE_NAME} for architectures ${SERVICE_ARCH_SUPPORT}"
	@for arch in $(SERVICE_ARCH_SUPPORT); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) BUILD_ARCH="$${arch}" service-publish; \
	done

service-verify: $(APIKEY) $(KEYS)
	@echo "--- INFO -- verifying service $(SERVICE_NAME) in ${SERVICE_ORG}"
	@export HZN_EXCHANGE_URL=${HEU} && hzn exchange service list -o ${SERVICE_ORG} -u iamapikey:$(shell cat $(APIKEY)) | jq '.|to_entries[]|select(.value=="'${SERVICE_TAG}'")!=null'
	@export HZN_EXCHANGE_URL=${HEU} && hzn exchange service verify --public-key-file ${PUBLIC_KEY_FILE} -o ${SERVICE_ORG} -u iamapikey:$(shell cat $(APIKEY)) "${SERVICE_TAG}"

##
## PATTERNS
##

${DIR}/pattern.json: pattern.json ${DIR}
	@echo "--- INFO -- updating pattern ${SERVICE_NAME} for ${SERVICE_ORG} on ${HEU}"
	@export TAG=${TAG} && ./fixpattern.sh ${DIR}

pattern-publish: ${APIKEY} ${DIR}/pattern.json service-publish-all
	@export HZN_EXCHANGE_URL=${HEU} && ./pattern-test.sh 
	@export HZN_EXCHANGE_URL=${HEU} && hzn exchange pattern publish -o "${SERVICE_ORG}" -u iamapikey:$(shell cat $(APIKEY)) -f ${DIR}/pattern.json -p ${SERVICE_NAME} -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE}

pattern-validate:
	@echo "--- INFO -- validating pattern ${SERVICE_NAME} for ${SERVICE_ORG} on ${HEU}"
	@export HZN_EXCHANGE_URL=${HEU} && hzn exchange pattern verify -o "${SERVICE_ORG}" -u iamapikey:$(shell cat $(APIKEY)) --public-key-file ${PUBLIC_KEY_FILE} ${SERVICE_NAME}
	@export HZN_EXCHANGE_URL=${HEU} && FOUND=false && for pattern in $$(hzn exchange pattern list -o "${SERVICE_ORG}" -u iamapikey:$(shell cat $(APIKEY)) | jq -r '.[]'); do if [ "$${pattern}" = "${SERVICE_ORG}/${SERVICE_NAME}" ]; then found=true; break; fi; done && if [ -z $${found} ]; then echo "Did not find $(SERVICE_ORG)/$(SERVICE_NAME)"; exit 1; else echo "Found pattern $${pattern}"; fi

##
## TESTING
##

testnodes: $(TEST_NODE_NAMES)
	@echo "--- INFO -- finish testing $(SERVICE_NAME) on ${TEST_NODE_NAMES} at $$(date)"

$(TEST_NODE_NAMES):
	@echo "--- INFO -- start testing ${SERVICE_NAME} on ${@} port $(SERVICE_PORT) at $$(date)"
	-@export JQ_FILTER="$(TEST_NODE_FILTER)" && START=$$(date +%s) && curl -m 30 --connect-timeout $(TEST_NODE_TIMEOUT) -fsSL "http://${@}:${DOCKER_PORT}" -o check.json && FINISH=$$(date +%s) && echo "ELAPSED:" $$((FINISH-START)) && jq -c "$${JQ_FILTER}" check.json | jq -c '.test'

unregister:
	@echo "--- INFO -- unregistering ${TEST_NODE_NAMES}"
	@for machine in $(TEST_NODE_NAMES); do \
	  echo "--- INFO -- unregistering $${machine}" $$(date); \
	  ssh $${machine} 'hzn unregister -fr &> /dev/null &'; \
	done

##
## CLEANUP
##

clean: remove service-stop
	@echo "--- INFO -- cleaning service ${SERVICE_NAME} including image for ${DOCKER_TAG}"
	@rm -fr ${DIR} check.json build.out 
	-@docker rmi $(DOCKER_TAG) 2> /dev/null || :

distclean: clean
	@echo "--- INFO -- cleaning for distribution"
	@rm -fr $(KEYS) $(APIKEY) $(SERVICE_REQVARS) ${SERVICE_VARIABLES} TEST_TMP_*

##
## BOOKKEEPING
##

.PHONY: default all build run check push depend service-start service-stop service-test service-publish service-publish-all service-verify $(TEST_NODE_NAMES) $(SERVICE_ARCH_SUPPORT) clean distclean
