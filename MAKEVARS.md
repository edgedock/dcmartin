# `MAKEVARS.md` - variables defined in `make` files

**This content is informational only; there is usually no need to specify any of these variables when executing the build process.**

# Horizon controls

+ `CMD` - location of `hzn` command
+ `HZN` - Open Horizon _exchange_ URL; defaults to  `https://alpha.edge-fabric.com/v1/`
+ `DIR` - directory name for temporary build files; defaults to `horizon`

## `ORG`, `URL`
These variables are used to control which organization services and patterns are directed.  The `URL` provides a unique path for services.  These variables should be changed prior to attempting to `publish` either a service or a pattern.

+ `ORG` - organization in which the services and patterns are published, e.g. `dcmartin@us.ibm.com`
+ `URL` - base of identifier for each service, e.g. `com.github.dcmartin.open-horizon`

## `TAG`
This variable is used to control naming of artefacts.

+ `TAG` - tag, if any, for build artefacts; defaults to empty unless `TAG` file found or specified as environment variable

## `BUILD_ARCH`
This variable controls the architecture for which artefacts are built; options are defined in the `build.json` configuration file.

+ `BUILD_ARCH` -  may be one of `arm`, `arm64`, or `amd64`

This variable may be used on the command-line to control the build, for example:

```
% make BUILD_ARCH=arm64 TAG=test publish start
```

## Service definitions

+ `SERVICE_ORG` - _organization_ for service; defaults to `org` from `service.json`
+ `SERVICE_LABEL` - _label_ for service; defaults to `label` from `service.json`
+ `SERVICE_NAME` - name to use for service artefacts w/ `TAG` if exists; defaults to `SERVICE_LABEL`
+ `SERVICE_VERSION` - semantic version `#.#.#` for service; defaults to `version` from `service.json`
+ `SERVICE_TAG` - identifier for service as recorded in Open Horizon _exchange_ [**automatic**]
+ `SERVICE_PORT` - status port for service; identified as first entry from `specific_ports` in `service.json` [**automatic**]
+ `SERVICE_URI` - unique identifier for _service_ in _exchange_; defaults to `url` from `service.json` [**automatic**]
+ `SERVICE_URL` - unique identifier for _service_ in _exchange_ w/ `TAG` if exists; defaults to `SERVICE_URI` [**automatic**]
+ `SERVICE_REQVARS` - list of required variables from `service.json`; [**automatic**]

## Code signing

+ `PRIVATE_KEY_FILE` - filename of private key for code signing; defaults to `IBM-*.key` or `PRIVATE_KEY_FILE`
+ `PUBLIC_KEY_FILE` - filename of public key for code signing; defaults to `IBM-*.pem` or `PUBLIC_KEY_FILE`

## IBM Cloud API Key

+ `APIKEY`- IBM Cloud platform API key; defaults to `apiKey` from `apiKey.json` or contents of `APIKEY` file

## Docker

+ `DOCKER_ID` - identifier for login to container registry; defaults to output of `whoami`
+ `DOCKER_NAME` - identifier for container; defaults to `${BUILD_ARCH}/${SERVICE_NAME}` [**automatic**]
+ `DOCKER_TAG` - tag for container; defaults to `$(DOCKER_ID)/$(DOCKER_NAME):$(SERVICE_VERSION)` [**automatic**]
+ `DOCKER_PORT` - port mapping for local container; from default is first from `ports` in `service.json`

## BUILD

These variables are complicated and subject to change.

Define `BUILD_FROM` according to `TAG` if and only if the original `BUILD_BASE` is from the same `DOCKER_ID` (i.e. use base images with same `TAG`).

```
BUILD_BASE=$(shell jq -r ".build_from.${BUILD_ARCH}" build.json)
BUILD_ORG=$(shell echo $(BUILD_BASE) | sed "s|\([^/]*\)/.*|\1|")
SAME_ORG=$(shell if [ $(BUILD_ORG) = $(DOCKER_ID) ]; then echo ${DOCKER_ID}; else echo ""; fi)
BUILD_PKG=$(shell echo $(BUILD_BASE) | sed "s|[^/]*/\([^:]*\):.*|\1|")
BUILD_TAG=$(shell echo $(BUILD_BASE) | sed "s|[^/]*/[^:]*:\(.*\)|\1|")
BUILD_FROM=$(if ${TAG},$(if ${SAME_ORG},${BUILD_ORG}/${BUILD_PKG}-${TAG}:${BUILD_TAG},${BUILD_BASE}),${BUILD_BASE})
```
