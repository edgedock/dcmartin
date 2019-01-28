## ARCHITECTURE
ARCH=$(shell uname -m | sed -e 's/aarch64.*/arm64/' -e 's/x86_64.*/amd64/' -e 's/armv.*/arm/')
BUILD_ARCH=$(shell arch)

## HZN
HEU=$(shell hzn node list | jq -r '.configuration.exchange_api') 

## BUILD
BUILD_FROM=$(shell jq -r ".build_from.${BUILD_ARCH}" build.json)

## SERVICE
ORG?=$(shell jq -r '.org' service.json)
URL=$(shell jq -r '.url' service.json)
LABEL=$(shell jq -r '.label' service.json)
VERSION=$(shell jq -r '.version' service.json)
SERVICE_TAG="${ORG}/${URL}_${VERSION}_${ARCH}"

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
DOCKER_PORT=$(shell jq -r '.ports?|to_entries|first|.key?' service.json | sed 's|/tcp||') 

default: all

all: build run check

build: build.json service.json
	docker build --build-arg BUILD_ARCH=$(BUILD_ARCH) --build-arg BUILD_FROM=$(BUILD_FROM) . -t "$(DOCKER_TAG)"

run: remove
	./docker-run.sh "$(DOCKER_NAME)" "$(DOCKER_TAG)"

remove:
	-docker rm -f $(DOCKER_NAME) 2> /dev/null || :

check: service.json
	rm -f check.json
	curl -sSL 'http://localhost:'${DOCKER_PORT} -o check.json && jq '.' check.json

push: build
	docker push ${DOCKER_TAG}

publish: build test
	hzn exchange service publish  -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE} -f test/service.definition.json -o ${ORG} -u iamapikey:${APIKEY}

verify: publish
	# should return 'true'
	hzn exchange service list -o ${ORG} -u iamapikey:${APIKEY} | jq '.|to_entries[]|select(.value=="'${SERVICE_TAG}'")!=null'
	# should return 'All signatures verified'
	hzn exchange service verify --public-key-file ${PUBLIC_KEY_FILE} -o ${ORG} -u iamapikey:${APIKEY} "${SERVICE_TAG}"

test: service.json userinput.json
	rm -fr test/
	export HZN_EXCHANGE_URL=${HEU} && hzn dev service new -o "${ORG}" -d test
	jq '.deployment.services.'${LABEL}'.image="'${DOCKER_TAG}'"' service.json | sed "s|{arch}|${ARCH}|g" > test/service.definition.json
	cp -f userinput.json test/userinput.json

depend: test
	export HZN_EXCHANGE_URL=${HEU} && hzn dev dependency fetch -d test/ --org "${ORG}" --url "${URL}" -u ${ORG}/iamapikey:${APIKEY}
	export HZN_EXCHANGE_URL=${HEU} && hzn dev service verify -d test/

start: depend stop
	export HZN_EXCHANGE_URL=${HEU} && hzn dev service start -d test/

stop:
	export HZN_EXCHANGE_URL=${HEU} && hzn dev service stop -d test/

clean:
	rm -f check.json check.jpg service-${ARCH}.json
	-docker rm -f $(DOCKER_NAME) 2> /dev/null || :
	-docker rmi $(DOCKER_TAG) 2> /dev/null || :

.PHONY: default all build run check stop push publish verify clean depend start
