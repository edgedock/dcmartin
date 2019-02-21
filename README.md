# Open Horizon example _services_ and _patterns_

Open Horizon is a distributed, decentralized, automated system for the orchestration of workloads at the _edge_ of the *cloud*.  More information is available on [Github][open-horizon].  Devices with Horizon installed may _register_ for patterns using services provided by the IBM Cloud.  Please refer to [`DESIGN.md`][design-md] for more information on the design of these examples services.

[design-md]: https://github.com/dcmartin/open-horizon/tree/master/DESIGN.md

# 1. Status

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

# 2. Build

The `make` program is used to build; the software required: `make`, `git`, `curl`, `jq`, and [`docker`][docker-start].  More information about the build process at [`BUILD.md`][build-md].

The default target for the `make` process will `build` the container images, `run` them locally, and `check` the status of each _service_. More information is available in [`MAKE.md`][make-md].   

[docker-start]: https://www.docker.com/get-started
[make-md]: https://github.com/dcmartin/open-horizon/blob/master/MAKE.md
[build-md]: https://github.com/dcmartin/open-horizon/blob/master/BUILD.md
[travis-yaml]: https://github.com/dcmartin/open-horizon/blob/master/.travis.yml
[travis-ci]: https://travis-ci.org/
[build-pattern-video]: https://youtu.be/cv_rOdxXidA

# 3. Services & Patterns

Services are defined within a directory hierarchy of this [repository][repository].  Services include:

+ [`cpu`][cpu-service] - provide CPU usage as percentage (0-100)
+ [`wan`][wan-service] - provide Wide-Area-Network information
+ [`hal`][hal-service] - provide Hardware-Abstraction-Layer information
+ [`yolo`][yolo-service] - recognize `person` and other entities from image
+ [`yolo2masgub`][yolo2msghub-service] - transmit `yolo`, `hal`, `cpu`, and `wan` information to Kafka (**pattern** available)
+ [`motion2mqtt`][motion2mqtt-service] - transmit motion detected images to MQTT (**pattern** available)

While all services in this repository share a common design (see [`DESIGN.md`][design-md]), that design is independent of the build automation process.   The build automation process is futher described in [`BUILD.md`][build-md].  See [`SERVICE.md`][service-md] and [`PATTERN.md`][pattern-md] for more information on building services and patterns.

[yolo-service]: https://github.com/dcmartin/open-horizon/tree/master/yolo/README.md
[hal-service]: https://github.com/dcmartin/open-horizon/tree/master/hal/README.md
[cpu-service]: https://github.com/dcmartin/open-horizon/tree/master/cpu/README.md
[wan-service]: https://github.com/dcmartin/open-horizon/tree/master/wan/README.md
[yolo2msghub-service]: https://github.com/dcmartin/open-horizon/tree/master/yolo2msghub/README.md
[motion2mqtt-service]: https://github.com/dcmartin/open-horizon/tree/master/motion2mqtt/README.md

# 5. Open Horizon

Open Horizon is available for a variety of architectures and platforms.  For more information please refer to the [`setup/README.md`][setup-readme-md].  

A _quick-start_ for Ubuntu/Debian/Raspbian LINUX below.

```
wget -qO - ibm.biz/horizon-setup | sudo bash
```

[setup-readme-md]: https://github.com/dcmartin/open-horizon/blob/master/setup/README.md

## 5.1 Credentials

Credentials are required to participate; request access on the IBM Applied Sciences [Slack][edge-slack] by providing an IBM Cloud Platform API key, which can be [created][ibm-apikeys] using your [IBMid][ibm-registration]

## 5.2 Further Information 

Refer to the following for more information on [getting started][edge-fabric] and [installation][edge-install].

## CLOC

```
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
C                               69           2989           1858          20295
C/C++ Header                    49           1380           1409           8183
Markdown                        15            546              0           2316
Bourne Shell                    35            329            327           1871
CUDA                            10            315             94           1853
JSON                            34              6              0            875
YAML                             2             29             13            354
Python                           6             65             18            275
Dockerfile                       6             58             28            244
make                             3             81             51            234
C++                              1             16              1            118
-------------------------------------------------------------------------------
SUM:                           230           5814           3799          36618
-------------------------------------------------------------------------------
```

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



