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
+ `org` - `dcmartin@us.ibm.com`
+ `url` - `com.github.dcmartin.open-horizon.yolo`
+ `version` - `0.0.2`

#### Optional variables
+ `YOLO_CONFIG` - configuration of YOLO; `tiny`, `v2`, or `v3`
+ `YOLO_ENTITY` - entity to count; defaults to `all`
+ `YOLO_PERIOD` - seconds between updates; defaults to `0`
+ `YOLO_THRESHOLD` - minimum probability; default `0.25`; range `0.0` to `1.0`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
+ `DEBUG` - turn on debugging output; `true` or `false`; default `false`

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
  "yolo": {
    "log_level": "info",
    "debug": true,
    "date": 1551045756,
    "period": 0,
    "entity": "all",
    "config": "tiny",
    "threshold": 0.25,
    "names": [ "person", "bicycle", "car", "motorbike", "aeroplane", "bus", "train", "truck", "boat", "traffic light", "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat", "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee", "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket", "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple", "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair", "sofa", "pottedplant", "bed", "diningtable", "toilet", "tvmonitor", "laptop", "mouse", "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink", "refrigerator", "book", "clock", "vase", "scissors", "teddy bear", "hair drier", "toothbrush" ]
  },
  "hzn": { "agreementid": "", "arch": "", "cpus": 0, "device_id": "", "exchange_url": "", "host_ips": [ "" ], "organization": "", "pattern": "", "ram": 0 },
  "date": 1551045756,
  "service": "yolo"
}
```

The `yolo` payload will be incomplete until the service completes; subsequent `make check` will return complete; see below:

```
{
  "yolo": {
    "log_level": "info",
    "debug": true,
    "date": 1551045824,
    "period": 0,
    "entity": "all",
    "config": "tiny",
    "threshold": 0.25,
    "names": [ "person", "bicycle", "car", "motorbike", "aeroplane", "bus", "train", "truck", "boat", "traffic light", "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat", "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee", "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket", "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple", "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair", "sofa", "pottedplant", "bed", "diningtable", "toilet", "tvmonitor", "laptop", "mouse", "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink", "refrigerator", "book", "clock", "vase", "scissors", "teddy bear", "hair drier", "toothbrush" ],
    "mock": "eagle",
    "time": 0.830621,
    "info": { "type": "JPEG", "size": "773x512", "bps": "8-bit", "color": "sRGB" },
    "detected": [
      {
        "entity": "bird",
        "count": 1
      }
    ],
    "count": 1,
    "scale": "none",
    "image": "redacted"
  },
  "hzn": { "agreementid": "", "arch": "", "cpus": 0, "device_id": "", "exchange_url": "", "host_ips": [ "" ], "organization": "", "pattern": "", "ram": 0 },
  "date": 1551045756,
  "service": "yolo"
}

```

## Example

![mock-output.jpg](samples/mock-output.jpg?raw=true "YOLO")

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
