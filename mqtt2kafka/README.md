# `mqtt2kafka` - MQTT to Kafka relay

This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.mqtt2kafka.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.mqtt2kafka "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.mqtt2kafka.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.mqtt2kafka "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.mqtt2kafka
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.mqtt2kafka.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.mqtt2kafka.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.mqtt2kafka "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.mqtt2kafka.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.mqtt2kafka "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.mqtt2kafka
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.mqtt2kafka.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.mqtt2kafka.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.mqtt2kafka "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.mqtt2kafka.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.mqtt2kafka "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.mqtt2kafka
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.mqtt2kafka.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `dcmartin@us.ibm.com`
+ `url` - `com.github.dcmartin.open-horizon.mqtt2kafka`
+ `version` - `0.0.1`
+ `arch` - `arm`, `arm64`, `amd64`

#### Required variables
+ `MQTT2KAFKA_APIKEY` - message hub API key

#### Optional variables
+ `MQTT2KAFKA_HOST` - IP or FQDN for mqtt host; defaults to `mqtt` on local VPN
+ `MQTT2KAFKA_PORT` - MQTT port number; defaults to 1883
+ `MQTT2KAFKA_USERNAME` - MQTT username; default "" (_empty string_); indicating no username
+ `MQTT2KAFKA_PASSWORD` - MQTT password; default "" (_empty string_); indicating no password
+ `MQTT2KAFKA_ADMIN_URL` - administrative URL; **no changes necessary**
+ `MQTT2KAFKA_BROKER`- message hub broker list; **no changes necessary**
+ `MQTT2KAFKA_PERIOD` - update time in seconds for status
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
+ `DEBUG` - force debug settings; boolean; default `false`

## How To Build

Copy this [repository][repository], change to the `mqtt2kafka` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/mqtt2kafka
% make
...
```

# Open Horizon

This service may be published to an Open Horizon exchange for an organization.  Please see the documentation for additional details.

## About Open Horizon

Open Horizon is a distributed, decentralized, automated system for the orchestration of workloads at the _edge_ of the *cloud*.  More information is available on [Github][open-horizon].  Devices with Horizon installed may _register_ for patterns using services provided by the IBM Cloud.

## Credentials

**Note:** _You will need an IBM Cloud [account][ibm-registration]_

Credentials are required to participate; request access on the IBM Applied Sciences [Slack][edge-slack] by providing an IBM Cloud Platform API key, which can be [created][ibm-apikeys] using your IBMid.  An API key will be provided for an IBM sponsored Kafka service during the alpha phase.  The same API key is used for both the CPU and SDR addon-patterns.

# Setup

Refer to these [instructions][setup].

# Further Information

Refer to the following for more information on [getting started][edge-fabric] and [installation][edge-install].

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[userinput]: https://github.com/dcmartin/open-horizon/blob/master/mqtt2kafka/userinput.json
[service-json]: https://github.com/dcmartin/open-horizon/blob/master/mqtt2kafka/service.json
[build-json]: https://github.com/dcmartin/open-horizon/blob/master/mqtt2kafka/build.json
[dockerfile]: https://github.com/dcmartin/open-horizon/blob/master/mqtt2kafka/Dockerfile


[dcmartin]: https://github.com/dcmartin
[edge-fabric]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/getting-started.html
[edge-install]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/adding-devices.html
[edge-slack]: https://ibm-appsci.slack.com/messages/edge-fabric-users/
[ibm-apikeys]: https://console.bluemix.net/iam/#/apikeys
[ibm-registration]: https://console.bluemix.net/registration/
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: https://github.com/dcmartin/open-horizon/blob/master/setup/README.md
