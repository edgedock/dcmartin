# `motion2mqtt` - detect motion and send to MQTT

Monitors attached camera and provides [motion-project.github.io][motion-project-io] as micro-service, transmitting _events_ and _images_ to a designated [MQTT][mqtt-org] host.  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

[mqtt-org]: http://mqtt.org/
[motion-project-io]: https://motion-project.github.io/

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.motion2mqtt.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.motion2mqtt "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.motion2mqtt.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.motion2mqtt "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.motion2mqtt
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.motion2mqtt.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.motion2mqtt.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.motion2mqtt "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.motion2mqtt.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.motion2mqtt "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.motion2mqtt
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.motion2mqtt.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.motion2mqtt.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.motion2mqtt "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.motion2mqtt.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.motion2mqtt "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.motion2mqtt
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.motion2mqtt.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `dcmartin@us.ibm.com`
+ `url` - `com.github.dcmartin.open-horizon.motion2mqtt`
+ `version` - `0.0.10`

#### Optional variables

+ `MOTION_DEVICE_DB` - device database name (aka top-level topic); defaults to `motion`
+ `MOTION_MQTT_HOST` - FQDN or IP address of MQTT server; defaults to `mqtt`
+ `MOTION_DEVICE_NAME` - device name; defaults to `HZN_DEVICE_ID` or `hostname`
+ `MOTION_MQTT_PORT` - port number; defaults to `1883`
+ `MOTION_MQTT_USERNAME` - MQTT username; defaults to ""
+ `MOTION_MQTT_PASSWORD` - MQTT password; defaults to ""
+ `MOTION_POST_PICTURES` - post pictures; default `off`; options include `on`, `best`, and `center`
+ `MOTION_LOG_LEVEL` - level of logging for motion2mqtt; default `2`
+ `MOTION_LOG_TYPE` - type of logging for motion2mqtt; default `all`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)

## How To Use

Copy this [repository][repository], change to the `motion2mqtt` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/motion2mqtt
% make
...
{
  "hzn": {
    "agreementid": "",
    "arch": "",
    "cpus": 0,
    "device_id": "",
    "exchange_url": "",
    "host_ips": [
      ""
    ],
    "organization": "",
    "pattern": "",
    "ram": 0
  },
  "date": 1550509113,
  "service": "motion2mqtt",
  "pattern": null,
  "motion2mqtt": {
    "cpu": false,
    "motion": {
      "event": {
        "base64": false
      },
      "image": {
        "base64": false
      }
    }
  }
}
```

The `motion2mqtt` value will initially be incomplete until the service completes its initial execution.  Subsequent tests should return a completed payload, see below:

```
% curl -sSL http://localhost:8082
```

should result in a partial service payload:

```
{
  "motion2mqtt": {
    "date": 1551144408,
    "log_level": "info",
    "debug": true,
    "db": "newman",
    "name": "davidsimac.local",
    "timezone": "America/Los_Angeles",
    "mqtt": {
      "host": "horizon.dcmartin.com",
      "port": "1883",
      "username": "username",
      "password": "password"
    },
    "motion": {
      "post": "center"
    },
    "period": 30,
    "services": [
      "cpu"
    ],
    "pid": 34,
    "cpu": {
      "date": 1551144406,
      "log_level": "info",
      "debug": false,
      "period": 60,
      "interval": 1,
      "percent": 66.32
    }
  },
  "hzn": {
    "agreementid": "99c2448bfcd40495ee7acdeaea2906e660c19d6b4019a8e37c80b6a7c9fc7db7",
    "arch": "amd64",
    "cpus": 1,
    "device_id": "davidsimac.local",
    "exchange_url": "https://alpha.edge-fabric.com/v1",
    "host_ips": [
      "127.0.0.1",
      "192.168.1.27",
      "192.168.1.26",
      "9.80.93.5"
    ],
    "organization": "dcmartin@us.ibm.com",
    "pattern": "",
    "ram": 1024
  },
  "date": 1551144407,
  "service": "motion2mqtt",
  "pattern": null
}
```

When deployed as a pattern, additional information is provided (n.b. `base64` encoded JPEG and GIF images have been redacted):

```
{
  "hzn": {
    "agreementid": "2cc1007a8a285e4075d58ee7bc31d2b24750aea8bb15a715f159fc93bc74b5a9",
    "arch": "arm",
    "cpus": 1,
    "device_id": "test-sdr-4",
    "exchange_url": "https://alpha.edge-fabric.com/v1/",
    "host_ips": [ "127.0.0.1", "169.254.184.120", "192.168.0.1", "192.168.1.47", "172.17.0.1" ],
    "organization": "dcmartin@us.ibm.com",
    "pattern": "dcmartin@us.ibm.com/motion2mqtt",
    "ram": 0
  },
  "date": 1550451493,
  "service": "motion2mqtt",
  "pattern": {
    "key": "dcmartin@us.ibm.com/motion2mqtt",
    "value": {
      "owner": "dcmartin@us.ibm.com/dcmartin@us.ibm.com",
      "label": "motion2mqtt",
      "description": "motion2mqtt as a pattern",
      "public": true,
      "services": [
        { "serviceUrl": "com.github.dcmartin.open-horizon.motion2mqtt", "serviceOrgid": "dcmartin@us.ibm.com", "serviceArch": "amd64", "serviceVersions": [ { "version": "0.0.1", "deployment_overrides": "", "deployment_overrides_signature": "", "priority": {}, "upgradePolicy": {} } ], "dataVerification": { "metering": {} }, "nodeHealth": { "missing_heartbeat_interval": 600, "check_agreement_status": 120 } },
        { "serviceUrl": "com.github.dcmartin.open-horizon.motion2mqtt", "serviceOrgid": "dcmartin@us.ibm.com", "serviceArch": "arm", "serviceVersions": [ { "version": "0.0.1", "deployment_overrides": "", "deployment_overrides_signature": "", "priority": {}, "upgradePolicy": {} } ], "dataVerification": { "metering": {} }, "nodeHealth": { "missing_heartbeat_interval": 600, "check_agreement_status": 120 } },
        { "serviceUrl": "com.github.dcmartin.open-horizon.motion2mqtt", "serviceOrgid": "dcmartin@us.ibm.com", "serviceArch": "arm64", "serviceVersions": [ { "version": "0.0.1", "deployment_overrides": "", "deployment_overrides_signature": "", "priority": {}, "upgradePolicy": {} } ], "dataVerification": { "metering": {} }, "nodeHealth": { "missing_heartbeat_interval": 600, "check_agreement_status": 120 } } ],
      "agreementProtocols": [ { "name": "Basic" } ],
      "lastUpdated": "2019-02-16T15:34:16.133Z[UTC]"
    }
  },
  "pid": 18,
  "motion2mqtt": {
    "date": 1550508626,
    "log_level": "info",
    "debug": false,
    "db": "newman",
    "name": "test-sdr-4",
    "timezone": "GMT",
    "mqtt": { "host": "horizon.dcmartin.com", "port": "1883", "username": "", "password": "" },
    "motion": {
      "post": "best",
      "event": {
        "device": "test-sdr-4",
        "camera": "default",
        "event": "59",
        "start": 1550508445,
        "image": { "device": "test-sdr-4", "camera": "default", "type": "jpeg", "date": 1550508446, "seqno": "03", "event": "59", "id": "20190218164726-59-03", "center": { "x": 600, "y": 262 }, "width": 64, "height": 120, "size": 5362, "noise": 17 },
        "elapsed": 3,
        "end": 1550508448,
        "date": 1550508574,
        "images": [ "20190218164725-59-00", "20190218164725-59-01", "20190218164725-59-02", "20190218164725-59-03", "20190218164726-59-00", "20190218164726-59-01", "20190218164726-59-02", "20190218164726-59-03", "20190218164727-59-00", "20190218164727-59-01", "20190218164728-59-00" ],
        "base64": "<redacted>"
      },
      "image": { "device": "test-sdr-4", "camera": "default", "type": "jpeg", "date": 1550508446, "seqno": "03", "event": "59", "id": "20190218164726-59-03", "center": { "x": 600, "y": 262 }, "width": 64, "height": 120, "size": 5362, "noise": 17, "base64": "<redacted>" }
    },
    "period": 300,
    "services": [ "cpu" ],
    "pid": 37,
    "cpu": { "date": 1550508327, "log_level": "info", "debug": false, "period": 60, "interval": 1, "percent": 58.32 }
  }
}
```

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[userinput]: https://github.com/dcmartin/open-horizon/blob/master/motion2mqtt/userinput.json
[service-json]: https://github.com/dcmartin/open-horizon/blob/master/motion2mqtt/service.json
[build-json]: https://github.com/dcmartin/open-horizon/blob/master/motion2mqtt/build.json
[dockerfile]: https://github.com/dcmartin/open-horizon/blob/master/motion2mqtt/Dockerfile


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
