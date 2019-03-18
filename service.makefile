## ARCHITECTURE
BUILD_ARCH ?= $(if $(wildcard BUILD_ARCH),$(shell cat BUILD_ARCH),$(shell uname -m | sed -e 's/aarch64.*/arm64/' -e 's/x86_64.*/amd64/' -e 's/armv.*/arm/'))

## IDENTIFICATION
HZN_ORG_ID ?= $(if $(wildcard ../HZN_ORG_ID),$(shell cat ../HZN_ORG_ID),HZN_ORG_ID_UNSPECIFIED)
DOCKER_HUB_ID ?= $(if $(wildcard ../DOCKER_HUB_ID),$(shell cat ../DOCKER_HUB_ID),$(shell whoami))

## GIT
GIT_REMOTE_URL=$(shell git remote get-url origin)

## HZN
CMD := $(shell whereis hzn | awk '{ print $1 }')
HEU := $(if ${HZN_EXCHANGE_URL},${HZN_EXCHANGE_URL},$(if $(CMD),$(shell $(CMD) node list 2> /dev/null | jq -r '.configuration.exchange_api'),))
HEU := $(if ${HEU},${HEU},"https://alpha.edge-fabric.com/v1")
DIR ?= horizon
TAG ?= $(if $(wildcard ../TAG),$(shell cat ../TAG),)

## SERVICE
SERVICE_ORG := $(if ${HZN_ORG_ID},${HZN_ORG_ID},$(shell jq -r '.org' service.json))
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
PRIVATE_KEY_FILE := $(if $(wildcard ../${HZN_ORG_ID}*.key),$(wildcard ../${HZN_ORG_ID}*.key),HZN_ORG_ID_PRIVATE_KEY_FILE)
PUBLIC_KEY_FILE := $(if $(wildcard ../${HZN_ORG_ID}*.pem),$(wildcard ../${HZN_ORG_ID}*.pem),HZN_ORG_ID_PUBLIC_KEY_FILE)
KEYS = $(PRIVATE_KEY_FILE) $(PUBLIC_KEY_FILE)

## IBM Cloud API Key
APIKEY := $(if $(wildcard ../apiKey.json),$(shell jq -r '.apiKey' ../apiKey.json > APIKEY && echo APIKEY),APIKEY)

## docker
DOCKER_HUB_ID := $(if $(DOCKER_HUB_ID),$(DOCKER_HUB_ID),$(shell whoami))
DOCKER_LOGIN := $(if $(wildcard ~/.docker/config.json),,Please_login_to_docker_hub)
DOCKER_NAME = $(BUILD_ARCH)_$(SERVICE_URL)
DOCKER_TAG = $(DOCKER_HUB_ID)/$(DOCKER_NAME):$(SERVICE_VERSION)
DOCKER_PORT = $(shell jq -r '.ports?|to_entries|first|.value?' service.json)

## BUILD
BUILD_BASE=$(shell jq -r ".build_from.${BUILD_ARCH}" build.json)
BUILD_ORG=$(shell echo $(BUILD_BASE) | sed "s|\([^/]*\)/.*|\1|")
SAME_ORG=$(shell if [ $(BUILD_ORG) = $(DOCKER_HUB_ID) ]; then echo ${DOCKER_HUB_ID}; else echo ""; fi)
BUILD_PKG=$(shell echo $(BUILD_BASE) | sed "s|[^/]*/\([^:]*\):.*|\1|")
BUILD_TAG=$(shell echo $(BUILD_BASE) | sed "s|[^/]*/[^:]*:\(.*\)|\1|")
BUILD_FROM=$(if ${TAG},$(if ${SAME_ORG},${BUILD_ORG}/${BUILD_PKG}-${TAG}:${BUILD_TAG},${BUILD_BASE}),${BUILD_BASE})

## TEST
TEST_JQ_FILTER ?= $(if $(wildcard TEST_JQ_FILTER),$(shell egrep -v '^\#' TEST_JQ_FILTER | head -1),)
TEST_NODE_FILTER ?= $(if $(wildcard TEST_NODE_FILTER),$(shell egrep -v '^\#' TEST_NODE_FILTER | head -1),)
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
	@export HZN_EXCHANGE_URL=${HEU} && hzn dev service new -o "${SERVICE_ORG}" -d ${DIR}
	@jq '.org="'${HZN_ORG_ID}'"|.label="'${SERVICE_LABEL}'"|.arch="'${BUILD_ARCH}'"|.url="'${SERVICE_URL}'"|.deployment.services=([.deployment.services|to_entries[]|select(.key=="'${SERVICE_LABEL}'")|.key="'${SERVICE_LABEL}'"|.value.image="'${DOCKER_TAG}'"]|from_entries)' service.json > ${DIR}/service.definition.json
	@cp -f userinput.json ${DIR}/userinput.json
	@export HZN_EXCHANGE_URL=${HEU} TAG=${TAG} && ./fixservice.sh ${DIR}

${DIR}/userinput.json: userinput.json ${DIR}
	@./checkvars.sh ${DIR}

depend: $(APIKEY) ${DIR}
	@export HZN_EXCHANGE_URL=${HEU} HZN_EXCHANGE_USERAUTH=${SERVICE_ORG}/iamapikey:$(shell cat $(APIKEY)) TAG=${TAG} && ./mkdepend.sh ${DIR}

##
## CONTAINERS
##

build: Dockerfile build.json service.json rootfs Makefile
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- building: ${SERVICE_NAME}; architecture: ${BUILD_ARCH}; tag: ${DOCKER_TAG}""${NC}" &> /dev/stderr
	@docker build --build-arg BUILD_REF=$$(git rev-parse --short HEAD) --build-arg BUILD_DATE=$$(date -u +"%Y-%m-%dT%H:%M:%SZ") --build-arg BUILD_ARCH="$(BUILD_ARCH)" --build-arg BUILD_FROM="$(BUILD_FROM)" --build-arg BUILD_VERSION="${SERVICE_VERSION}" . -t "$(DOCKER_TAG)" > build.out

logs:
	@docker logs -f "${DOCKER_NAME}"

stop:
	@docker stop "${DOCKER_NAME}"

run: remove service-stop
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- running: ${SERVICE_NAME}; container: ${DOCKER_NAME}""${NC}" &> /dev/stderr
	@./docker-run.sh "$(DOCKER_NAME)" "$(DOCKER_TAG)"

remove:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- removing: ${SERVICE_NAME}; container: ${DOCKER_NAME}""${NC}" &> /dev/stderr
	-@docker rm -f $(DOCKER_NAME) 2> /dev/null || :

check:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- checking: ${SERVICE_NAME}; URL: http://localhost:${DOCKER_PORT}""${NC}" &> /dev/stderr
	@rm -f check.json
	@export JQ_FILTER="$(TEST_JQ_FILTER)" && curl -sSL "http://localhost:${DOCKER_PORT}" -o check.json && jq "$${JQ_FILTER}" check.json

push: build $(DOCKER_LOGIN)
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- pushing: ${SERVICE_NAME}; tag ${DOCKER_TAG}""${NC}" &> /dev/stderr
	@docker push ${DOCKER_TAG}

test:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- testing: ${SERVICE_NAME}; tag: ${DOCKER_TAG}""${NC}" &> /dev/stderr
	./test.sh "${DOCKER_TAG}"

##
## SERVICES
##

${SERVICE_ARCH_SUPPORT}:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- making: ${SERVICE_NAME}; architecture: $@""${NC}" &> /dev/stderr
	@$(MAKE) TAG=$(TAG) URL=$(URL) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_HUB_ID=$(DOCKER_HUB_ID) BUILD_ARCH="$@" build

service-build: ${SERVICE_ARCH_SUPPORT}

service-push: 
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- pushing: ${SERVICE_NAME}; architectures: ${SERVICE_ARCH_SUPPORT}""${NC}" &> /dev/stderr
	@for arch in $(SERVICE_ARCH_SUPPORT); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_HUB_ID=$(DOCKER_HUB_ID) BUILD_ARCH="$${arch}" push; \
	done

service-start: remove service-stop depend # $(SERVICE_REQVARS) 
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- starting: ${SERVICE_NAME}; directory: $(DIR)/""${NC}" &> /dev/stderr
	@./checkvars.sh ${DIR}
	@export HZN_EXCHANGE_URL=${HEU} && hzn dev service verify -d ${DIR}
	@export HZN_EXCHANGE_URL=${HEU} && hzn dev service start -d ${DIR}

service-test: ./test.${SERVICE_VERSION}.${BUILD_ARCH}.out
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- tested: ${SERVICE_NAME}; version: ${SERVICE_VERSION}; arch: ${BUILD_ARCH}" $$(tail -f $<) "${NC}" &> /dev/stderr
	-@${MAKE} service-stop
	@export HZN_EXCHANGE_URL=${HEU} && ./service-test.sh 

test.${SERVICE_VERSION}.${BUILD_ARCH}.out: service-start
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- testing service ${SERVICE_NAME} version ${SERVICE_VERSION} for $(BUILD_ARCH)""${NC}" &> /dev/stderr
	-@$(MAKE) test > ./test.${SERVICE_VERSION}.${BUILD_ARCH}.out
	@${MAKE} service-stop

service-stop: 
	-@if [ -d "${DIR}" ]; then export HZN_EXCHANGE_URL=${HEU} && hzn dev service stop -d ${DIR}; fi
	
publish-service: ${DIR} $(APIKEY) $(KEYS)
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- publishing: $(SERVICE_NAME); architecture: ${BUILD_ARCH}""${NC}" &> /dev/stderr
	@export HZN_EXCHANGE_URL=${HEU} && hzn exchange service publish  -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE} -f ${DIR}/service.definition.json -o ${SERVICE_ORG} -u iamapikey:$(shell cat $(APIKEY))

service-publish: 
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- publishing: ${SERVICE_NAME}; architectures: ${SERVICE_ARCH_SUPPORT}""${NC}" &> /dev/stderr
	@for arch in $(SERVICE_ARCH_SUPPORT); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_HUB_ID=$(DOCKER_HUB_ID) BUILD_ARCH="$${arch}" publish-service; \
	done

service-verify: $(APIKEY) $(KEYS)
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- verifying: $(SERVICE_NAME); organization: ${SERVICE_ORG}""${NC}" &> /dev/stderr
	@export HZN_EXCHANGE_URL=${HEU} && hzn exchange service list -o ${SERVICE_ORG} -u iamapikey:$(shell cat $(APIKEY)) | jq '.|to_entries[]|select(.value=="'${SERVICE_TAG}'")!=null'
	@export HZN_EXCHANGE_URL=${HEU} && hzn exchange service verify --public-key-file ${PUBLIC_KEY_FILE} -o ${SERVICE_ORG} -u iamapikey:$(shell cat $(APIKEY)) "${SERVICE_TAG}"

service-clean: ${DIR}
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- cleaning: $(SERVICE_NAME); organization: ${SERVICE_ORG}""${NC}" &> /dev/stderr
	@./service-clean.sh

##
## PATTERNS
##

pattern-test:
	@export HZN_EXCHANGE_URL=${HEU} && ./pattern-test.sh 

pattern-publish: ${APIKEY} pattern.json
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- publishing: ${SERVICE_NAME}; organization: ${SERVICE_ORG}; exchange: ${HEU}""${NC}" &> /dev/stderr
	@export TAG=${TAG} && ./fixpattern.sh ${DIR}
	@export HZN_EXCHANGE_URL=${HEU} && hzn exchange pattern publish -o "${SERVICE_ORG}" -u iamapikey:$(shell cat $(APIKEY)) -f ${DIR}/pattern.json -p ${SERVICE_NAME} -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE}

pattern-validate: pattern.json
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- validating: ${SERVICE_NAME}; organization: ${SERVICE_ORG}; exchange: ${HEU}""${NC}" &> /dev/stderr
	@export HZN_EXCHANGE_URL=${HEU} && hzn exchange pattern verify -o "${SERVICE_ORG}" -u iamapikey:$(shell cat $(APIKEY)) --public-key-file ${PUBLIC_KEY_FILE} ${SERVICE_NAME}
	@export HZN_EXCHANGE_URL=${HEU} && FOUND=false && for pattern in $$(hzn exchange pattern list -o "${SERVICE_ORG}" -u iamapikey:$(shell cat $(APIKEY)) | jq -r '.[]'); do if [ "$${pattern}" = "${SERVICE_ORG}/${SERVICE_NAME}" ]; then found=true; break; fi; done && if [ -z $${found} ]; then echo "Did not find $(SERVICE_ORG)/$(SERVICE_NAME)"; exit 1; else echo "Found pattern $${pattern}"; fi

##
## TESTING
##

nodes-test: $(TEST_NODE_NAMES)
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- tested: $(SERVICE_NAME); nodes: ${TEST_NODE_NAMES}; date: $$(date)""${NC}" &> /dev/stderr

$(TEST_NODE_NAMES):
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- testing: ${SERVICE_NAME}; node: ${@}; port: $(SERVICE_PORT); date: $$(date)""${NC}" &> /dev/stderr
	-@export JQ_FILTER="$(TEST_NODE_FILTER)" && START=$$(date +%s) && curl --connect-timeout $(TEST_NODE_TIMEOUT) -fsSL "http://${@}:${DOCKER_PORT}" -o test.${@}.json && FINISH=$$(date +%s) && echo "ELAPSED:" $$((FINISH-START)) && jq -c "$${JQ_FILTER}" test.${@}.json | jq -c '.test'

nodes-list:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- listing nodes: ${TEST_NODE_NAMES}""${NC}" &> /dev/stderr
	@for machine in $(TEST_NODE_NAMES); do \
	  echo "${MC}>>> MAKE --" $$(date +%T) "-- listing $${machine}""${NC}" &> /dev/stderr; \
          ping -W 1 -c 1 $${machine} &> /dev/null \
	    && ssh $${machine} 'hzn node list' | jq -c '{"node":.id}' \
	    && ssh $${machine} 'hzn agreement list' | jq -c '{"agreements":[.[].workload_to_run]}' \
	    && ssh $${machine} 'hzn service list 2> /dev/null' | jq -c '{"services":[.[]?.url]}' \
	    && ssh $${machine} 'docker ps --format "{{.Names}},{{.Image}}"' | awk -F, '{ printf("{\"name\":\"%s\",\"image\":\"%s\"}\n", $$1, $$2) }' | jq -c '{"container":.name}' \
	    || echo "${RED}>>>${NC} MAKE **" $$(date +%T) "** not found $${machine}""${NC}" &> /dev/stderr; \
	done

CONFIG := ../setup/horizon.json

# export PATTERN=$$(jq -r '. as $$d|.configurations[]|select(.nodes[]?.device=="test-cpu-2").pattern as $$p|$$d|.patterns[]|select(.id==$$p).name' ${CONFIG}); 

nodes: ${DIR}/userinput.json
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- registering nodes: ${TEST_NODE_NAMES}""${NC}" &> /dev/stderr
	@./checkvars.sh ${DIR}
	@for machine in $(TEST_NODE_NAMES); do \
	  echo "${MC}>>> MAKE --" $$(date +%T) "-- registering $${machine}" "${NC}"; \
	  export HZN_ORG_ID=${HZN_ORG_ID} HZN_EXCHANGE_APIKEY=$(shell cat $(APIKEY)) && ./nodereg.sh $${machine} ${SERVICE_NAME} ${DIR}/userinput.json; \
	done

nodes-undo:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- unregistering nodes: ${TEST_NODE_NAMES}""${NC}" &> /dev/stderr
	@for machine in $(TEST_NODE_NAMES); do \
	  echo "${MC}>>> MAKE --" $$(date +%T) "-- unregistering $${machine}" "${NC}"; \
	  ping -W 1 -c 1 $${machine} &> /dev/null && ssh $${machine} 'hzn unregister -fr &> /dev/null || docker system prune -fa &> /dev/null &' \
	    || echo "${RED}>>>${NC} MAKE **" $$(date +%T) "** not found $${machine}""${NC}" &> /dev/stderr; \
	done

nodes-purge:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- purging nodes: ${TEST_NODE_NAMES}""${NC}" &> /dev/stderr
	@for machine in $(TEST_NODE_NAMES); do \
	  if [ $$(ping -W 1 -c 1 $${machine} && true || false) ]; then \
	    echo "${MC}>>> MAKE --" $$(date +%T) "-- unregistering $${machine}" "${NC}" \
	    ssh $${machine} 'hzn unregister -fr'; \
	    ssh $${machine} 'sudo apt-get remove -y bluehorizon horizon horizon-cli'; \
	    ssh $${machine} 'sudo apt-get purge -y bluehorizon horizon horizon-cli'; \
	  else \
	    echo "${RED}>>>${NC} MAKE **" $$(date +%T) "** not found $${machine}""${NC}" &> /dev/stderr; \
	  fi; \
	done

##
## CLEANUP
##

clean: remove service-stop
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- cleaning: ${SERVICE_NAME}; tag: ${DOCKER_TAG}""${NC}" &> /dev/stderr
	@rm -fr ${DIR} check.json build.out test.*.out
	-@docker rmi $(DOCKER_TAG) 2> /dev/null || :

distclean: clean
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- cleaning: distribution""${NC}" &> /dev/stderr
	@rm -fr $(KEYS) $(APIKEY) $(SERVICE_REQVARS) ${SERVICE_VARIABLES} TEST_TMP_*

##
## BOOKKEEPING
##

.PHONY: default all build run check test push service-start service-stop service-test service-publish publish-service service-verify $(TEST_NODE_NAMES) $(SERVICE_ARCH_SUPPORT) clean distclean depend

##
## COLORS
##
MC=${LIGHT_BLUE}
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
