# `mqtt` - MQTT broker

This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_mqtt-beta.svg)](https://microbadger.com/images/dcmartin/amd64_mqtt-beta "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_mqtt-beta.svg)](https://microbadger.com/images/dcmartin/amd64_mqtt-beta "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_mqtt-beta
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_mqtt-beta.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_mqtt-beta.svg)](https://microbadger.com/images/dcmartin/arm_mqtt-beta "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_mqtt-beta.svg)](https://microbadger.com/images/dcmartin/arm_mqtt-beta "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_mqtt-beta
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_mqtt-beta.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_mqtt-beta.svg)](https://microbadger.com/images/dcmartin/arm64_mqtt-beta "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_mqtt-beta.svg)](https://microbadger.com/images/dcmartin/arm64_mqtt-beta "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_mqtt-beta
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_mqtt-beta.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `dcmartin@us.ibm.com`
+ `url` - `com.github.dcmartin.open-horizon.mqtt`
+ `version` - `0.0.1`

#### Optional variables
+ `MQTT_PERIOD` - update time in seconds for server statistics
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
+ `DEBUG` - force debug settings; boolean; default `false`

## How To Use

Copy this [repository][repository], change to the `mqtt` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/mqtt
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
  "date": 1550798064,
  "service": "mqtt",
  "pid": 13,
  "mqtt": {
    "date": 1550798079,
    "log_level": "info",
    "debug": false,
    "period": 30,
    "pid": 17,
    "version": "mosquitto version 1.4.15",
    "broker": {
      "bytes": {
        "received": 45836001021,
        "sent": 43188059313
      },
      "clients": {
        "connected": 1
      },
      "load": {
        "messages": {
          "sent": {
            "one": 21.91,
            "five": 105.69,
            "fifteen": 215.26
          },
          "received": {
            "one": 30.31,
            "five": 146.31,
            "fifteen": 373
          }
        }
      },
      "publish": {
        "messages": {
          "received": 481086,
          "sent": 173971,
          "dropped": 0
        }
      },
      "subscriptions": {
        "count": 132
      }
    }
  }
}
```

# Open Horizon

This service may be published to an Open Horizon exchange for an organization.  Please see the documentation for additional details.

## User Input (options)
Nodes should _register_ using a derivative of the template `userinput.json` [file][userinput].  Options include:
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
+ `DEBUG` - force debugging mode; boolean; default `false`

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

[userinput]: https://github.com/dcmartin/open-horizon/blob/master/mqtt/userinput.json
[service-json]: https://github.com/dcmartin/open-horizon/blob/master/mqtt/service.json
[build-json]: https://github.com/dcmartin/open-horizon/blob/master/mqtt/build.json
[dockerfile]: https://github.com/dcmartin/open-horizon/blob/master/mqtt/Dockerfile


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
