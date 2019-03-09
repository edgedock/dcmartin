# Open Horizon example _services_ and _patterns_

Open Horizon is a distributed, decentralized, automated system for the orchestration of workloads at the _edge_ of the *cloud*.  More information is available on [Github][open-horizon].  Devices with Horizon installed may _register_ for patterns using services provided by the IBM Cloud.  Please refer to [`DESIGN.md`][design-md] for more information on the design of these examples services.

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

# 2. Services & Patterns

Services are defined within a directory hierarchy of this [repository][repository].

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
+ [`jetson-caffe`][jetson-caffe-service] - BLVC Caffe with CUDA and OpenCV for nVidia Jetson TX

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

# 3. Build, Test & Deploy

The services and patterns in this [repository][repository] may be built and tested either as a group or individually.  While all services in this repository share a common design (see [`DESIGN.md`][design-md]), that design is independent of the build automation process.   See [`SERVICE.md`][service-md] and [`PATTERN.md`][pattern-md] for more information on building services and patterns.

## 3.1 Build

The `make` program is used to build; software requirements are: `make`, `git`, `curl`, `jq`, and [`docker`][docker-start].  The default target for the `make` process will `build` the container images, `run` them locally, and `check` the status of each _service_.   More information is available at  [`BUILD.md`][build-md].

1. Clone this [repository][repository]
2. Initiate build with `make` command (see [`MAKE.md`][make-md] )

**To push containers to a Docker registry:**

2. Create file `HZN_ORG_ID` the Open Horizon organization identifier
3. Create file `DOCKER_HUB_ID` with Docker Hub login identifier
1. Change `build`, `service`, and `pattern` configuration template files

```
# set environment variables
export HZN_ORG_ID="you@yourdomain.tld"
export DOCKER_HUB_ID="yourdockerhubid"
# change all configuration templates
sed -i "s/dcmartin@us.ibm.com/${HORIZON_ORG_ID}/g" */service.json
sed -i "s/dcmartin@us.ibm.com/${HORIZON_ORG_ID}/g" */pattern.json
sed -i "s/dcmartin/${DOCKER_HUB_ID}/g" */build.json
```

**To `make` any _service_ or _pattern_ target perform the following:** (see [`SERVICE.md`][service-md])

3. Install `hzn` command-line tool and create code signing keys (public and private)
4. Generate and download IBM Cloud API Key as `apiKey.json`
5. Publish service(s) with `make service-publish`
6. Publish pattern(s) with `make pattern-publish`

## 3.2 Test

Each service may be tested individually using the following `make` targets:

+ `check` - check the service individually using `TEST_JQ_FILTER` for `jq` command; returns response JSON
+ `test` - test the service individually; tests status response JSON for conformance
+ `service-test` - test the service and all required services; tests status response JSON for conformance

## 3.3 Deploy (see [video][horizon-video-setup])

Edge nodes for testing may be created using instructions in [`SETUP.md`][setup-md].  Credentials may be established for development using keys created for node configuration; refer to [`NETWORK.md`][network-md]  for more details.  Nodes may be interrogated for service status  (n.b. `TEST_NODE_NAMES` variable) with the following `make` targets:

+ `test-nodes` - test response JSON using `TEST_NODE_FILTER` for `jq` command
+ `list-nodes` - execute `hzn node list`

Observe  system with the following commands for listing nodes, services, and patterns:

+ `./setup/lsnodes.sh` - lists all nodes in the organization according to `setup/horizon.json`
+ `./setup/lsservices.sh` - lists all services in the organization according to `setup/horizon.json`
+ `./setup/lspatterns.sh` - lists all patterns in the organization according to `setup/horizon.json`

Individual patterns have specialized receiving scripts which can be invoked:

+ `./yolo2msghub/kafkat.sh` - listens to Kafka messages sent by the `yolo2msghub` service

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

# 4. Open Horizon

Open Horizon is available for a variety of architectures and platforms.  For more information please refer to the [`setup/README.md`][setup-readme-md].  

A _quick-start_ for Ubuntu/Debian/Raspbian LINUX below.

```
wget -qO - ibm.biz/horizon-setup | sudo bash
```

[setup-readme-md]: https://github.com/dcmartin/open-horizon/blob/master/setup/README.md

## 4.1 Credentials

Credentials are required to participate; request access on the IBM Applied Sciences [Slack][edge-slack] by providing your [IBMid][ibm-registration] email and IBM Cloud account GUID.

## 4.2 Further Information 

Refer to the following for more information on [getting started][edge-fabric] and [installation][edge-install].

## Changelog & Releases

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
