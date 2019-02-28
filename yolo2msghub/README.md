# `yolo2msghub` - count an entity and send to Kafka

Send YOLO classified image entity counts to Kafka; updates as often as underlying services provide.
This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_yolo2msghub.svg)](https://microbadger.com/images/dcmartin/amd64_yolo2msghub "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_yolo2msghub.svg)](https://microbadger.com/images/dcmartin/amd64_yolo2msghub "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_yolo2msghub
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_yolo2msghub.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_yolo2msghub.svg)](https://microbadger.com/images/dcmartin/arm_yolo2msghub "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_yolo2msghub.svg)](https://microbadger.com/images/dcmartin/arm_yolo2msghub "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_yolo2msghub
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_yolo2msghub.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_yolo2msghub.svg)](https://microbadger.com/images/dcmartin/arm64_yolo2msghub "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_yolo2msghub.svg)](https://microbadger.com/images/dcmartin/arm64_yolo2msghub "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_yolo2msghub
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_yolo2msghub.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `dcmartin@us.ibm.com`
+ `url` - `com.github.dcmartin.open-horizon.yolo2msghub`
+ `version` - `0.0.1`

#### Required variables
+ `YOLO2MSGHUB_APIKEY` - message hub API key

#### Optional variables
+ `YOLO2MSGHUB_PERIOD` - seconds between updates; defaults to `30`
+ `YOLO2MSGHUB_ADMIN_URL` - administrative URL for REStful API
+ `YOLO2MSGHUB_BROKER` - message hub brokers
+ `LOCALHOST_PORT` - port for access; default **8587**
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`). 
+ `DEBUG` - including debugging output; `true` or `false`; default: `false`

### Pattern registration
Register nodes using a derivative of the template [`userinput.json`][userinput].  Variables may be modified in the `userinput.json` file, _or_ may be defined in a file of the same name; **contents should be JSON**, e.g. quoted strings; extract from downloaded API keys using `jq` command:  

```
% jq '.api_key' {kafka-apiKey-file} > YOLO2MSGHUB_APIKEY
```

**NOTE:** Refer to _Required Services_ for their variables.

#### Example registration
```
% hzn register -u ${HZN_ORG_ID}/iamapikey:{apikey} -n {nodeid}:{token} -e ${HZN_ORG_ID} -f userinput.json
```

## Required services

This _service_ includes the following services:

+ [`yolo`][yolo-service] - captures images from camera and counts specified entity
+ [`hal`][hal-service] - provides hardware inventory layer API for client
+ [`cpu`][cpu-service] - provides CPU percentage API for client
+ [`wan`][wan-service] - provides wide-area-network information API for client

Each of these services is described in the following locations:

[yolo-service]: https://github.com/dcmartin/open-horizon/tree/master/yolo/README.md
[hal-service]: https://github.com/dcmartin/open-horizon/tree/master/hal/README.md
[cpu-service]: https://github.com/dcmartin/open-horizon/tree/master/cpu/README.md
[wan-service]: https://github.com/dcmartin/open-horizon/tree/master/wan/README.md

# Sample

![sample.png](sample.png?raw=true "YOLO2MSGHUB")

# Getting started

Clone or fork this [repository][repository], change to the `yolo2msghub` directory, then use the **make** command; quick-start below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/yolo2msghub
% make
```

The default `make` command will `build`,`run`, and `check` this service.  A container with the name `{arch}_yolo2msghub`, e.g. `amd64_yolo2msghub` on Intel/AMD PC/MAC/LINUX, will be created (n.b. running containers can be listed through `docker ps`). Results from a successful `make check` yield a sample payload:

```
{
  "hostname": "a60b406943d4-172017000007",
  "org": "dcmartin@us.ibm.com",
  "pattern": "yolo2msghub",
  "device": "davidsimac.local-amd64_yolo2msghub",
  "pid": 8,
  "yolo2msghub": {
    "log_level": "info",
    "debug": "false",
    "services": [
      { "name": "yolo", "url": "http://yolo:80" },
      { "name": "hal", "url": "http://hal:80" },
      { "name": "cpu", "url": "http://cpu:80" },
      { "name": "wan", "url": "http://wan:80" }
    ]
  }
}
```

# Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[userinput]: https://github.com/dcmartin/open-horizon/blob/master/yolo2msghub/userinput.json
[service-json]: https://github.com/dcmartin/open-horizon/blob/master/yolo2msghub/service.json
[build-json]: https://github.com/dcmartin/open-horizon/blob/master/yolo2msghub/build.json
[dockerfile]: https://github.com/dcmartin/open-horizon/blob/master/yolo2msghub/Dockerfile
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
