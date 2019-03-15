# Open Horizon example _services_ and _patterns_

Open Horizon is a distributed, decentralized, automated system for the orchestration of workloads at the _edge_ of the *cloud*.  More information is available on [Github][open-horizon].  Devices with Horizon installed may _register_ for patterns using services provided by the IBM Cloud. 

[design-md]: https://github.com/dcmartin/open-horizon/tree/master/DESIGN.md

# 1. [Status][status-md] ([_beta_][beta-md])

![](https://img.shields.io/github/license/dcmartin/open-horizon.svg?style=flat)
![](https://img.shields.io/github/release/dcmartin/open-horizon.svg?style=flat)
[![Build Status](https://travis-ci.org/dcmartin/open-horizon.svg?branch=master)](https://travis-ci.org/dcmartin/open-horizon)
[![Coverage Status](https://coveralls.io/repos/github/dcmartin/open-horizon/badge.svg?branch=master)](https://coveralls.io/github/dcmartin/open-horizon?branch=master)

![](https://img.shields.io/github/repo-size/dcmartin/open-horizon.svg?style=flat)
![](https://img.shields.io/github/last-commit/dcmartin/open-horizon.svg?style=flat)
![](https://img.shields.io/github/commit-activity/w/dcmartin/open-horizon.svg?style=flat)
![](https://img.shields.io/github/contributors/dcmartin/open-horizon.svg?style=flat)
![](https://img.shields.io/github/issues/dcmartin/open-horizon.svg?style=flat)
![](https://img.shields.io/github/tag/dcmartin/open-horizon.svg?style=flat)

![Supports amd64 Architecture][amd64-shield]
![Supports aarch64 Architecture][arm64-shield]
![Supports armhf Architecture][arm-shield]

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## 1.1 Repository & Exchange

These services and patterns are built and pushed to public [repositories][docker-dcmartin] on [Docker Hub][docker-hub].  and available in the exchange.  Defaults:

+ `HZN_EXCHANGE_URL` is `https://alpha.edge-fabric.com/v1`
+ `HZN_ORG_ID` is `dcmartin@us.ibm.com`.
+ `DOCKER_HUB_ID` is [`dcmartin`][docker-dcmartin]
+ `URL` is [`com.github.dcmartin.open-horizon`][repository]

[docker-dcmartin]: https://hub.docker.com/?namespace=dcmartin

**NOTE**: build, push, and publish containers, services, and patterns using appropriate values.

# 2. Services & Patterns

Services are defined within a directory hierarchy of this [repository][repository]. Please refer to [`DESIGN.md`][design-md] for more information on the design of these examples services.


There are two services which are **available as a _pattern_** and may be registered for a node:

+ [`yolo2msgub`][yolo2msghub-service] - transmit `yolo`, `hal`, `cpu`, and `wan` information to Kafka
+ [`motion2mqtt`][motion2mqtt-service] - transmit motion detected images to MQTT

Other services include:

+ [`cpu`][cpu-service] - provide CPU usage as percentage (0-100)
+ [`wan`][wan-service] - provide Wide-Area-Network information
+ [`hal`][hal-service] - provide Hardware-Abstraction-Layer information
+ [`yolo`][yolo-service] - recognize entities from USB camera
+ [`mqtt`][mqtt-service] - MQTT message broker service
+ [`herald`][herald-service] - multi-cast data received from other heralds on local-area-network
+ [`hzncli`][hzncli] - service container with `hzn` command-line-interface installed
+ [`yolo4motion`][yolo4motion-service] - subscribe to MQTT _topics_ from `motion2mqtt`,  recognize entities, and publish results
+ [`mqtt2kafka`][mqtt2kafka-service] - relay specified MQTT traffic to Kafka
+ [`jetson-caffe`][jetson-caffe-service] - BVLC Caffe with CUDA and OpenCV for nVidia Jetson TX
+ [`jetson-yolo`][jetson-yolo-service] - Darknet YOLO with CUDA and OpenCV for nVidia Jetson TX

There are also two _base_ containers that are used by the other services:

+ [`base-alpine`][base-alpine] - base service container for Alpine LINUX
+ [`base-ubuntu`][base-ubuntu] - base service container for Ubuntu LINUX

[yolo-service]: https://github.com/dcmartin/open-horizon/tree/master/yolo/README.md
[hal-service]: https://github.com/dcmartin/open-horizon/tree/master/hal/README.md
[cpu-service]: https://github.com/dcmartin/open-horizon/tree/master/cpu/README.md
[wan-service]: https://github.com/dcmartin/open-horizon/tree/master/wan/README.md
[base-alpine]: https://github.com/dcmartin/open-horizon/tree/master/base-alpine/README.md
[base-ubuntu]: https://github.com/dcmartin/open-horizon/tree/master/base-ubuntu/README.md
[hzncli]: https://github.com/dcmartin/open-horizon/tree/master/hzncli/README.md

[herald-service]: https://github.com/dcmartin/open-horizon/tree/master/herald/README.md
[mqtt-service]: https://github.com/dcmartin/open-horizon/tree/master/mqtt/README.md

[yolo2msghub-service]: https://github.com/dcmartin/open-horizon/tree/master/yolo2msghub/README.md
[yolo4motion-service]: https://github.com/dcmartin/open-horizon/tree/master/yolo4motion/README.md
[motion2mqtt-service]: https://github.com/dcmartin/open-horizon/tree/master/motion2mqtt/README.md
[mqtt2kafka-service]: https://github.com/dcmartin/open-horizon/tree/master/mqtt2kafka/README.md
[jetson-caffe-service]: https://github.com/dcmartin/open-horizon/tree/master/jetson-caffe/README.md
[jetson-yolo-service]: https://github.com/dcmartin/open-horizon/tree/master/jetson-yolo/README.md

# 3. Build, Push & Publish

The services and patterns in this [repository][repository] may be built and tested either as a group or individually.  While all services in this repository share a common design (see [`DESIGN.md`][design-md]), that design is independent of the build automation process.   See [`SERVICE.md`][service-md] and [`PATTERN.md`][pattern-md] for more information on building services and patterns.

## 3.1 Clone, build and push (see [**video**][build-push-video]) 

[build-push-video]: https://www.youtube.com/watch?v=NHLen-lY7pw

The `make` program (see [`MAKE.md`][make-md] ) is used to build; software requirements are: `make`, `git`, `curl`, `jq`, and [`docker`][docker-start].  The default target for the `make` process will `build` the container images, `run` them locally, and `check` the status of each _service_.   More information is available at  [`BUILD.md`][build-md].

1. Clone this [repository][repository]
2. Set `DOCKER_HUB_ID` to the [Docker registry][docker-hub] login identifier
2. Login to Docker registry
4. Initiate build with `make` command

### 3.1.1 Video Script

```
mkdir ~/gitdir
cd ~/gitdir
git clone http://github.com/dcmartin/open-horizon
cd open-horizon/cpu
export DOCKER_HUB_ID=dcmsjc
make build
docker login
make push
make service-push
```

## 3.2 Build and push all containers (see [**video**][build-push-all-video])

[build-push-all-video]: https://youtu.be/d5JiB_aDxRY

1. Set `HZN_ORG_ID` to the exchange organization identifier
1. Change `service`, `pattern`, and `build` configuration template files (as necessary)

[docker-hub]: http://hub.docker.com/

```
# set environment variables
export DOCKER_HUB_ID="yourdockerhubid"
# login to Docker registry (e.g. hub.docker.com)
docker login
```
**NOTE**: on **macOS** the Docker application preferences should _not_ use the secure OSX keychain.

```
# login to Docker registry (e.g. hub.docker.com)
docker login
```

To `make` all container images for all architectures for each and every service use the `service-push` target:

### 3.2.1 Video Script

```
cd ~/gitdir/open-horizon
export DOCKER_HUB_ID=dcmsjc
docker login
make service-push
```


## 3.3 Publish services (see [**video**][publish-cpu-service-video])

[publish-cpu-service-video]: https://youtu.be/C47L1PWVp3E


1. Generate and download IBM Cloud API Key as `apiKey.json` ([cloud.ibm.com/iam][ibm-iam])
1. Install `hzn` command-line tool and create code signing keys (public and private)

```
hzn key create ${HZN_ORG_ID} you@yourdomain.tld
```
[ibm-iam]: http://cloud.ibm.com/iam

To publish a service to the exchange use the `service-publish` target; this target will fail if the service containers have not been successfully pushed to the Docker registry:

```
make service-publish
```

The following commands automatically replace the defaults in all configuration and build templates.

```
export HZN_ORG_ID="you@yourdomain.tld"
# change all configuration templates
for json in */service.json */pattern.json; do sed -i "s/dcmartin@us.ibm.com/${HORIZON_ORG_ID}/g" ${json}; done
# change all build specifications
for json in */build.json; do sed -i "s/dcmartin/${DOCKER_HUB_ID}/g" ${json}; done
```

### 3.3.1 Video Script

```
cd ~/gitdir/open-horizon
ls -al apiKey.json 
export DOCKER_HUB_ID=dcmsjc
docker login
export HZN_ORG_ID=dcmartin@us.ibm.com
hzn key create ${HZN_ORG_ID} $(whoami)@$(hostname)
mv -f *.key ${HZN_ORG_ID}.key
mv -f *.pem ${HZN_ORG_ID}.pem
make service-publish
```


# 4. Test

Each service may be tested individually using the following `make` targets:

+ `check` - check the service individually using `TEST_JQ_FILTER` for `jq` command; returns response JSON
+ `test` - test the service individually; tests status response JSON for conformance
+ `service-test` - test the service and all required services; tests status response JSON for conformance

# 5. Deploy (see [video][horizon-video-setup])

Pattern tests using deployed nodes may be utilized with appropriate client device node configuration.  Edge nodes for testing may be created using instructions in [`SETUP.md`][setup-md].

+ `nodes` - configure clients with _pattern_; devices IP/FQDN specified in `TEST_TMP_MACHINES` file
+ `list-nodes` - execute `hzn node list` and `docker ps` on client devices
+ `test-nodes` - process status API from client using `jq` command and `TEST_NODE_FILTER`expression
+ `undo-nodes` - unregister client devices as nodes

For more information see [`PATTERN.md`][pattern-md].

[horizon-video-setup]: https://youtu.be/IfR-XY603JY
[docker-start]: https://www.docker.com/get-started
[make-md]: https://github.com/dcmartin/open-horizon/blob/master/MAKE.md
[setup-md]: https://github.com/dcmartin/open-horizon/blob/master/setup/README.md
[network-md]: https://github.com/dcmartin/open-horizon/blob/master/setup/NETWORK.md
[makevars-md]: https://github.com/dcmartin/open-horizon/blob/master/MAKEVARS.md
[build-md]: https://github.com/dcmartin/open-horizon/blob/master/BUILD.md
[travis-yaml]: https://github.com/dcmartin/open-horizon/blob/master/.travis.yml
[travis-ci]: https://travis-ci.org/
[build-pattern-video]: https://youtu.be/cv_rOdxXidA

# 6. Open Horizon

Open Horizon is available for a variety of architectures and platforms.  For more information please refer to the [`setup/README.md`][setup-readme-md].  

A _quick-start_ for Ubuntu/Debian/Raspbian LINUX below.

```
wget -qO - ibm.biz/horizon-setup | sudo bash
```

[setup-readme-md]: https://github.com/dcmartin/open-horizon/blob/master/setup/README.md

## 6.1 Credentials

Credentials are required to participate; request access on the IBM Applied Sciences [Slack][edge-slack] by providing your [IBMid][ibm-registration] email and IBM Cloud account GUID.

## 6.2 Further Information 

Refer to the following for more information on [getting started][edge-fabric] and [installation][edge-install].

# Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

David C Martin (github@dcmartin.com)

[commits]: https://github.com/dcmartin/open-horizon/commits/master
[contributors]: https://github.com/dcmartin/open-horizon/graphs/contributors
[dcmartin]: https://github.com/dcmartin
[edge-fabric]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/getting-started.html
[edge-install]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/adding-devices.html
[edge-slack]: https://ibm-cloudplatform.slack.com/messages/edge-fabric-users/
[ibm-apikeys]: https://console.bluemix.net/iam/#/apikeys
[ibm-registration]: https://console.bluemix.net/registration/
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup-readme-md]: https://github.com/dcmartin/open-horizon/blob/master/setup/README.md
[service-md]: https://github.com/dcmartin/open-horizon/blob/master/SERVICE.md
[pattern-md]: https://github.com/dcmartin/open-horizon/blob/master/PATTERN.md
[status-md]: https://github.com/dcmartin/open-horizon/blob/master/STATUS.md
[beta-md]: https://github.com/dcmartin/open-horizon/blob/master/BETA.md

## [`CLOC.md`][cloc-md]

[cloc-md]: https://github.com/dcmartin/open-horizon/blob/master/CLOC.md

Language|files|blank|comment|code
:-------|-------:|-------:|-------:|-------:
JSON|101|2|0|10840
Markdown|28|991|0|5352
Bourne Shell|59|721|727|5120
Dockerfile|14|163|101|617
make|2|72|51|194
Bourne Again Shell|3|15|15|106
Python|1|10|20|48
YAML|1|0|2|28
Expect|1|0|0|5
--------|--------|--------|--------|--------
SUM:|210|1974|916|22310
