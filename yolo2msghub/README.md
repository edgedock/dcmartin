# `yolo2msghub` - count an entity and send to Kafka

Send YOLO classified image entity counts to Kafka; updates as often as underlying services provide.
This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo2msghub.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo2msghub "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo2msghub.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo2msghub "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo2msghub
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo2msghub.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.yolo2msghub.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.yolo2msghub "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.yolo2msghub.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.yolo2msghub "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.yolo2msghub
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.yolo2msghub.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo2msghub.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo2msghub "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo2msghub.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo2msghub "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo2msghub
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo2msghub.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `dcmartin@us.ibm.com`
+ `url` - `com.github.dcmartin.open-horizon.yolo2msghub`
+ `version` - `0.0.1`

### Required variables
+ `YOLO2MSGHUB_APIKEY` - message hub API key

### Optional variables
+ `YOLO2MSGHUB_PERIOD` - seconds between updates; defaults to `30`
+ `YOLO2MSGHUB_ADMIN_URL` - administrative URL for REStful API
+ `YOLO2MSGHUB_BROKER` - message hub brokers
+ `LOCALHOST_PORT` - port for access; default **8587**
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`). 
+ `DEBUG` - including debugging output; `true` or `false`; default: `false`

#### Example `userinput.json`

```
{
  "global": [],
  "services": [
    {
      "org": "dcmartin@us.ibm.com",
      "url": "com.github.dcmartin.open-horizon.yolo2msghub",
      "versionRange": "[0.0.0,INFINITY)",
      "variables": { "YOLO2MSGHUB_APIKEY": null, "LOCALHOST_PORT": 8587, "LOG_LEVEL": "info", "DEBUG": false }
    },
    {
      "org": "dcmartin@us.ibm.com",
      "url": "com.github.dcmartin.open-horizon.yolo",
      "versionRange": "[0.0.0,INFINITY)",
      "variables": { "YOLO_ENTITY": "person", "YOLO_PERIOD": 60, "YOLO_CONFIG": "tiny", "YOLO_THRESHOLD": 0.25 }
    },
    {
      "org": "dcmartin@us.ibm.com",
      "url": "com.github.dcmartin.open-horizon.cpu",
      "versionRange": "[0.0.0,INFINITY)",
      "variables": { "CPU_PERIOD": 60 }
    },
    {
      "org": "dcmartin@us.ibm.com",
      "url": "com.github.dcmartin.open-horizon.wan",
      "versionRange": "[0.0.0,INFINITY)",
      "variables": { "WAN_PERIOD": 900 }
    },
    {
      "org": "dcmartin@us.ibm.com",
      "url": "com.github.dcmartin.open-horizon.hal",
      "versionRange": "[0.0.0,INFINITY)",
      "variables": { "HAL_PERIOD": 1800 }
    }
  ]
}
```


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

The default `make` command will `build`,`run`, and `check` this service.  A container with the name `{arch}_com.github.dcmartin.open-horizon.yolo2msghub`, e.g. `amd64_com.github.dcmartin.open-horizon.yolo2msghub` on Intel/AMD PC/MAC/LINUX, will be created (n.b. running containers can be listed through `docker ps`).

## make `check`
Check service status output using the `TEST_JQ_FILTER` file contents as JSON output format.

```
{
  "yolo2msghub": {
    "log_level": "info",
    "debug": false,
    "services": [
      {
        "name": "yolo",
        "url": "http://yolo"
      },
      {
        "name": "hal",
        "url": "http://hal"
      },
      {
        "name": "cpu",
        "url": "http://cpu"
      },
      {
        "name": "wan",
        "url": "http://wan"
      }
    ],
    "period": 30,
    "cpu": false,
    "wan": false,
    "hal": false,
    "yolo": false
  },
  "hzn": {
    "agreementid": "388f1b3d8bcc95564a17199da446bc77f0b483044ba27ced534a334d081cfb41",
    "arch": "amd64",
    "cpus": 1,
    "device_id": "davidsimac.local",
    "exchange_url": "https://alpha.edge-fabric.com/v1",
    "host_ips": [
      "127.0.0.1",
      "192.168.1.27",
      "192.168.1.26",
      "9.80.93.175",
      "192.168.52.1",
      "192.168.29.1",
      "192.168.55.105",
      "169.254.245.125"
    ],
    "organization": "dcmartin@us.ibm.com",
    "pattern": "",
    "ram": 1024
  },
  "date": 1551814617,
  "service": "yolo2msghub"
}
```
## make `test`
Interrogate the service through direct access to Docker container and retrieve service status on designated port; process output through `test.sh` test harness using `test-yolo2msghub.sh` script.   Output conformant JSON attribute names and types.

```
{
  "yolo2msghub": {
    "wan": {
      "date": "number",
      "log_level": "string",
      "debug": "boolean",
      "period": "number"
    },
    "cpu": {
      "date": "number",
      "log_level": "string",
      "debug": "boolean",
      "period": "number",
      "interval": "number",
      "percent": "number"
    },
    "hal": {
      "date": "number",
      "log_level": "string",
      "debug": "boolean",
      "period": "number",
      "lshw": {
        "id": "string",
        "class": "string",
        "claimed": "boolean",
        "handle": "string",
        "description": "string",
        "product": "string",
        "version": "string",
        "serial": "string",
        "width": "number",
        "configuration": {
          "configuration": "object"
        },
        "capabilities": {
          "capabilities": "object"
        },
        "children": [
          "object",
          "object"
        ]
      },
      "lsusb": [],
      "lscpu": {
        "Architecture": "string",
        "CPU_op_modes": "string",
        "Byte_Order": "string",
        "CPUs": "string",
        "On_line_CPUs_list": "string",
        "Threads_per_core": "string",
        "Cores_per_socket": "string",
        "Sockets": "string",
        "Vendor_ID": "string",
        "CPU_family": "string",
        "Model": "string",
        "Model_name": "string",
        "Stepping": "string",
        "CPU_MHz": "string",
        "BogoMIPS": "string",
        "L1d_cache": "string",
        "L1i_cache": "string",
        "L2_cache": "string",
        "L3_cache": "string",
        "Flags": "string"
      },
      "lspci": [
        "object",
        "object",
        "object",
        "object",
        "object",
        "object",
        "object",
        "object",
        "object"
      ],
      "lsblk": [
        "object",
        "object",
        "object",
        "object"
      ]
    },
    "yolo": "null",
    "log_level": "string",
    "debug": "boolean",
    "services": [
      "object",
      "object",
      "object",
      "object"
    ],
    "period": "number",
    "date": "number"
  },
  "hzn": {
    "agreementid": "string",
    "arch": "string",
    "cpus": "number",
    "device_id": "string",
    "exchange_url": "string",
    "host_ips": [
      "string",
      "string",
      "string",
      "string",
      "string",
      "string",
      "string",
      "string"
    ],
    "organization": "string",
    "pattern": "string",
    "ram": "number"
  },
  "date": "number",
  "service": "string"
}

```
## make `test-nodes`

Access the service status on identified nodes (n.b. `TEST_TMP_MACHINES`) on designated port and process output using first non-commented line from file `TEST_NODE_FILTER`; for example if the service was started with `service-start` the results would not include `pattern` information.

```
>>> MAKE -- start testing yolo2msghub on localhost port 8587:8587 at Tue Mar  5 11:50:50 PST 2019
ELAPSED: 0
{"name":null}
{"hzn":{"agreementid":"0756cfe35e7b2e1891c1174d37e34587d8a878f8ff7a02bcfe72e94eee27600e","arch":"amd64","cpus":1,"device_id":"davidsimac.local","exchange_url":"https://alpha.edge-fabric.com/v1","host_ips":["127.0.0.1","192.168.1.27","192.168.1.26","9.80.93.175","192.168.52.1","192.168.29.1","192.168.55.105","169.254.245.125"],"organization":"dcmartin@us.ibm.com","pattern":"","ram":1024}}
{"period":30}
{"date":1551814993}
{"pattern":{"label":null}}
{"pattern":{"updated":null}}
{"horizon":{"pattern":""}}
{"cpu":true}
{"cpu":99.75}
{"hal":true}
{"wan":true}
{"yolo":true}
>>> MAKE -- finish testing yolo2msghub on localhost at Tue Mar  5 11:50:50 PST 2019
```

## `kafkacat.sh`

+ `./kafkacat.sh` - listens to Kafka messages sent by the `yolo2msghub` service

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
