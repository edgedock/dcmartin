#  	&#9968; Open Horizon example _services_ and _patterns_

Open Horizon is a distributed, decentralized, automated system for the orchestration of workloads at the _edge_ of the *cloud*.  More information is available on [Github][open-horizon].  Devices with Horizon installed may _register_ for patterns using services provided by the IBM Cloud. 

[design-md]: https://github.com/dcmartin/open-horizon/tree/master/doc/DESIGN.md

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
+ `DOCKER_NAMESPACE` is [`dcmartin`][docker-dcmartin]
+ `URL` is [`com.github.dcmartin.open-horizon`][repository]

[docker-dcmartin]: https://hub.docker.com/?namespace=dcmartin

**NOTE**: build, push, and publish containers, services, and patterns using appropriate values.

# 2. Services & Patterns

Services are defined within a directory hierarchy of this [repository][repository]. Please refer to [`DESIGN.md`][design-md] for more information on the design of these examples services.  All services in this repository share a common [design][design-md].

Patterns include:

+ `yolo2msghub` - Pattern of `yolo2msghub` with `yolo`,`hal`,`wan`, and `cpu`
+ `motion2mqtt` - Pattern of `motion2mqtt`,`yolo4motion` and `mqtt2kafka` with `mqtt`,`hal`,`wan`, and `cpu`

Services include:

+ [`cpu`][cpu-service] - provide CPU usage as percentage (0-100)
+ [`wan`][wan-service] - provide Wide-Area-Network information
+ [`hal`][hal-service] - provide Hardware-Abstraction-Layer information
+ [`yolo`][yolo-service] - recognize entities from USB camera
+ [`mqtt`][mqtt-service] - MQTT message broker service
+ [`hzncli`][hzncli] - service container with `hzn` command-line-interface installed
+ [`herald`][herald-service] - multi-cast data received from other heralds on local-area-network
+ [`yolo2msgub`][yolo2msghub-service] - transmit `yolo`, `hal`, `cpu`, and `wan` information to Kafka
+ [`motion2mqtt`][motion2mqtt-service] - transmit motion detected images to MQTT
+ [`yolo4motion`][yolo4motion-service] - subscribe to MQTT _topics_ from `motion2mqtt`,  recognize entities, and publish results
+ [`mqtt2kafka`][mqtt2kafka-service] - relay MQTT traffic to Kafka
+ [`jetson-caffe`][jetson-caffe-service] - BVLC Caffe with CUDA and OpenCV for nVidia Jetson TX
+ [`jetson-yolo`][jetson-yolo-service] - Darknet YOLO with CUDA and OpenCV for nVidia Jetson TX
+ [`jetson-digits`][jetson-digits] - nVidia DIGITS with CUDA

There are also _base_ containers that are used by the other services:

+ [`base-alpine`][base-alpine] - base container for Alpine LINUX
+ [`base-ubuntu`][base-ubuntu] - base container for Ubuntu LINUX
+ [`jetson-jetpack`][jetson-jetpack] - base container for Jetson devices
+ [`jetson-cuda`][jetson-cuda] - base container for Jetson devices with CUDA
+ [`jetson-opencv`][jetson-opencv] - base container for Jetson devices with CUDA & OpenCV

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

[jetson-digits]: https://github.com/dcmartin/open-horizon/tree/master/jetson-digits/README.md
[jetson-jetpack]: https://github.com/dcmartin/open-horizon/tree/master/jetson-jetpack/README.md
[jetson-cuda]: https://github.com/dcmartin/open-horizon/tree/master/jetson-cuda/README.md
[jetson-opencv]: https://github.com/dcmartin/open-horizon/tree/master/jetson-opencv/README.md

# 3. Copy and Use

The services and patterns in this [repository][repository] may be built and tested either as a group or individually.  Please refer to [`CICD.md`][cicd-md] for more information on using these examples.

See [`SERVICE.md`][service-md] and [`PATTERN.md`][pattern-md] for more information on building services and patterns.

#  	&#127919;  Further Information 

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
[service-md]: https://github.com/dcmartin/open-horizon/blob/master/doc/SERVICE.md
[cicd-md]: https://github.com/dcmartin/open-horizon/blob/master/doc/CICD.md
[pattern-md]: https://github.com/dcmartin/open-horizon/blob/master/doc/PATTERN.md
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
