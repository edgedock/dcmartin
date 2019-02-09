# `yolo` - You Only Look Once service

Provides entity count information as micro-service; updates periodically (default `0` seconds).  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_yolo-beta.svg)](https://microbadger.com/images/dcmartin/amd64_yolo-beta "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_yolo-beta.svg)](https://microbadger.com/images/dcmartin/amd64_yolo-beta "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_yolo-beta
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_yolo-beta.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_yolo-beta.svg)](https://microbadger.com/images/dcmartin/arm_yolo-beta "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_yolo-beta.svg)](https://microbadger.com/images/dcmartin/arm_yolo-beta "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_yolo-beta
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_yolo-beta.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_yolo-beta.svg)](https://microbadger.com/images/dcmartin/arm64_yolo-beta "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_yolo-beta.svg)](https://microbadger.com/images/dcmartin/arm64_yolo-beta "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_yolo-beta
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_yolo-beta.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `dcmartin@us.ibm.com/yolo`
+ `url` - `com.github.dcmartin.open-horizon.yolo`
+ `version` - `0.0.1`

### Architecture(s) supported
+ `arm` - RaspberryPi (armhf)
+ `amd64` - AMD/Intel 64-bit (x86-64)
+ `arm64` - nVidia TX2 (aarch)

#### Optional variables
+ `YOLO_ENTITY` - entity to count; defaults to `person`
+ `YOLO_PERIOD` - seconds between updates; defaults to `0`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)

## How To Use

Copy this [repository][repository], change to the `yolo` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/yolo
% make
...
{
  "hostname": "abec6ffa6455-172017000002",
  "org": "dcmartin@us.ibm.com",
  "pattern": "yolo",
  "device": "test-cpu-2-arm_yolo",
  "pid": 9,
  "yolo": {
    "log_level": "info",
    "debug": "false",
    "date": 1548702320,
    "period": 0,
    "entity": "person"
  }
}
```
The `yolo` payload will be incomplete until the service completes; subsequent `make check` will return complete; see below:
```
{
  "hostname": "abec6ffa6455-172017000002",
  "org": "dcmartin@us.ibm.com",
  "pattern": "yolo",
  "device": "test-cpu-2-arm_yolo",
  "pid": 9,
  "yolo": {
    "log_level": "info",
    "debug": "false",
    "date": 1548702367,
    "period": 0,
    "entity": "person",
    "time": 38.565109,
    "count": 0,
    "width": 320,
    "height": 240,
    "scale": "320x240",
    "mock": "false",
    "image": "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"
  }
}

```
## Example

![mock-output.jpg](mock-output.jpg?raw=true "YOLO")

# Open Horizon

This service may be published to an Open Horizon exchange for an organization.  Please see the documentation for additional details.

## User Input (options)
Nodes should _register_ using a derivative of the template `userinput.json` [file][userinput].  Options include:
+ `YOLO_ENTITY` - entity to count; defaults to `person`
+ `YOLO_PERIOD` - seconds between updates; defaults to `0`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)

### Example registration
```
% hzn register -u {org}/iamapikey:{apikey} -n {nodeid}:{token} -e {org} -f userinput.json
```

## Exchange

The **make** targets for `publish` and `verify` make the service and its container available on the exchange.  Prior to _publishing_ the `service.json` [file][service-json] must be modified for your organization.
```
% make publish
...
Using 'dcmartin/amd64_cpu@sha256:b1d9c38fee292f895ed7c1631ed75fc352545737d1cd58f762a19e53d9144124' in 'deployment' field instead of 'dcmartin/amd64_cpu:0.0.1'
Creating com.github.dcmartin.open-horizon.cpu_0.0.1_amd64 in the exchange...
Storing IBM-6d570b1519a1030ea94879bbe827db0616b9f554-public.pem with the service in the exchange...
```

```
% make verify
# should return 'true'
hzn exchange service list -o {org} -u iamapikey:{apikey} | jq '.|to_entries[]|select(.value=="'"{org}/{url}_{version}_{arch}"'")!=null'
true
# should return 'All signatures verified'
hzn exchange service verify --public-key-file ../IBM-..-public.pem -o {org} -u iamapikey:{apikey} "{org}/{url}_{version}_{arch}"
All signatures verified
```
## About Open Horizon

Open Horizon is a distributed, decentralized, automated system for the orchestration of workloads at the _edge_ of the *cloud*.  More information is available on [Github][open-horizon].  Devices with Horizon installed may _register_ for patterns using services provided by the IBM Cloud.

## Credentials

**Note:** _You will need an IBM Cloud [account][ibm-registration]_

Credentials are required to participate; request access on the IBM Applied Sciences [Slack][edge-slack] by providing an IBM Cloud Platform API key, which can be [created][ibm-apikeys] using your IBMid.  An API key will be provided for an IBM sponsored Kafka service during the alpha phase.  The same API key is used for both the CPU and SDR addon-patterns.

# Setup

Refer to these [instructions][setup].  Installation package for macOS is also [available][macos-install]

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

[userinput]: https://github.com/dcmartin/open-horizon/blob/master/yolo/userinput.json
[service-json]: https://github.com/dcmartin/open-horizon/blob/master/yolo/service.json
[build-json]: https://github.com/dcmartin/open-horizon/blob/master/yolo/build.json
[dockerfile]: https://github.com/dcmartin/open-horizon/blob/master/yolo/Dockerfile


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
