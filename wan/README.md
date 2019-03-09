# `wan` - Wide-Area-Network monitoring service

Monitors Internet access information as micro-service; updates periodically (default `1800` seconds or 15 minutes).  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.wan.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.wan "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.wan.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.wan "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.wan
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.wan.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.wan.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.wan "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.wan.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.wan "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.wan
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.wan.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.wan.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.wan "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.wan.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.wan "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.wan
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.wan.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `dcmartin@us.ibm.com`
+ `url` - `com.github.dcmartin.open-horizon.wan`
+ `version` - `0.0.1`

#### Optional variables
+ `WAN_PERIOD` - seconds between updates; defaults to `1800`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
## How To Use

Copy this [repository][repository], change to the `wan` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/wan
% make
...
{
  "hostname": "8a1dc0372e86-172017000005",
  "org": "dcmartin@us.ibm.com",
  "pattern": "wan",
  "device": "test-cpu-2-arm_com.github.dcmartin.open-horizon.wan",
  "pid": 9,
  "wan": {
    "log_level": "info",
    "debug": "false",
    "date": 1548701992,
    "period": 1800
  }
}
```
The `wan` payload will be incomplete until the service initiates; subsequent `make check` will return complete; see below:
```
{
  "hostname": "8a1dc0372e86-172017000005",
  "org": "dcmartin@us.ibm.com",
  "pattern": "wan",
  "device": "test-cpu-2",
  "pid": 9,
  "wan": {
    "log_level": "info",
    "debug": "false",
    "date": 1548702028,
    "period": 1800,
    "speedtest": {
      "download": 4890441.312717636,
      "upload": 7495721.486184587,
      "ping": 19.113,
      "server": {
        "url": "http://sjc.speedtest.net/speedtest/upload.php",
        "lat": "37.3041",
        "lon": "-121.8727",
        "name": "San Jose, CA",
        "country": "United States",
        "cc": "US",
        "sponsor": "Speedtest.net",
        "id": "10384",
        "url2": "http://sjc2.speedtest.net/speedtest/upload.php",
        "host": "sjc.host.speedtest.net:8080",
        "d": 7.476714842887551,
        "latency": 19.113
      },
      "timestamp": "2019-01-28T18:59:59.103913Z",
      "bytes_sent": 9617408,
      "bytes_received": 9593604,
      "share": null,
      "client": {
        "ip": "67.164.104.198",
        "lat": "37.2458",
        "lon": "-121.8306",
        "isp": "Comcast Cable",
        "isprating": "3.7",
        "rating": "0",
        "ispdlavg": "0",
        "ispulavg": "0",
        "loggedin": "0",
        "country": "US"
      }
    }
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

[userinput]: https://github.com/dcmartin/open-horizon/blob/master/wan/userinput.json
[service-json]: https://github.com/dcmartin/open-horizon/blob/master/wan/service.json
[build-json]: https://github.com/dcmartin/open-horizon/blob/master/wan/build.json
[dockerfile]: https://github.com/dcmartin/open-horizon/blob/master/wan/Dockerfile


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
