# `hal` - Hardware Abstration Layer service

Provides hardware information as micro-service; updates periodically (default `60` seconds or 1 minute).  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_hal.svg)](https://microbadger.com/images/dcmartin/amd64_hal "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_hal.svg)](https://microbadger.com/images/dcmartin/amd64_hal "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_hal
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_hal.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_hal.svg)](https://microbadger.com/images/dcmartin/arm_hal "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_hal.svg)](https://microbadger.com/images/dcmartin/arm_hal "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_hal
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_hal.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_hal.svg)](https://microbadger.com/images/dcmartin/arm64_hal "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_hal.svg)](https://microbadger.com/images/dcmartin/arm64_hal "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_hal
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_hal.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `dcmartin@us.ibm.com`
+ `url` - `com.github.dcmartin.open-horizon.hal`
+ `version` - `0.0.1`

#### Optional variables
+ `HAL_PERIOD` - seconds between updates; defaults to `60`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
## How To Use

Copy this [repository][repository], change to the `hal` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/hal
% make
...
{
  "hostname": "6f8d7dbd61da-172017000004",
  "org": "dcmartin@us.ibm.com",
  "pattern": "hal",
  "device": "test-cpu-2-arm_hal",
  "pid": 9,
  "hal": {
    "log_level": "info",
    "debug": "false",
    "date": 1548701599,
    "period": 60
  }
}
```
The `hal` payload will be incomplete until the service completes; subsequent `make check` will return complete; see below:
```
{
  "hostname": "6f8d7dbd61da-172017000004",
  "org": "dcmartin@us.ibm.com",
  "pattern": "hal",
  "device": "test-cpu-2-arm_hal",
  "pid": 9,
  "hal": {
    "log_level": "info",
    "debug": "false",
    "date": 1548701599,
    "period": 60,
    "lshw": {
      "id": "6f8d7dbd61da",
      "class": "system",
      "claimed": true,
      "description": "Computer",
      "product": "Raspberry Pi 3 Model B Plus Rev 1.3",
      "serial": "000000005770a507",
      "width": 32,
      "children": [
        {
          "id": "core",
          "class": "bus",
          "claimed": true,
          "description": "Motherboard",
          "physid": "0",
          "capabilities": {
            "raspberrypi_3-model-b-plus": true,
            "brcm_bcm2837": true
          },
          "children": [
            {
              "id": "cpu:0",
              "class": "processor",
              "claimed": true,
              "description": "CPU",
              "product": "cpu",
              "physid": "0",
              "businfo": "cpu@0",
              "units": "Hz",
              "size": 1400000000,
              "capacity": 1400000000,
              "capabilities": {
                "cpufreq": "CPU Frequency scaling"
              }
            },
            {
              "id": "cpu:1",
              "class": "processor",
              "disabled": true,
              "claimed": true,
              "description": "CPU",
              "product": "cpu",
              "physid": "1",
              "businfo": "cpu@1",
              "units": "Hz",
              "size": 1400000000,
              "capacity": 1400000000,
              "capabilities": {
                "cpufreq": "CPU Frequency scaling"
              }
            },
            {
              "id": "cpu:2",
              "class": "processor",
              "disabled": true,
              "claimed": true,
              "description": "CPU",
              "product": "cpu",
              "physid": "2",
              "businfo": "cpu@2",
              "units": "Hz",
              "size": 1400000000,
              "capacity": 1400000000,
              "capabilities": {
                "cpufreq": "CPU Frequency scaling"
              }
            },
            {
              "id": "cpu:3",
              "class": "processor",
              "disabled": true,
              "claimed": true,
              "description": "CPU",
              "product": "cpu",
              "physid": "3",
              "businfo": "cpu@3",
              "units": "Hz",
              "size": 1400000000,
              "capacity": 1400000000,
              "capabilities": {
                "cpufreq": "CPU Frequency scaling"
              }
            },
            {
              "id": "memory",
              "class": "memory",
              "claimed": true,
              "description": "System memory",
              "physid": "4",
              "units": "bytes",
              "size": 972234752
            }
          ]
        },
        {
          "id": "network",
          "class": "network",
          "claimed": true,
          "description": "Ethernet interface",
          "physid": "1",
          "logicalname": "eth0",
          "serial": "02:42:ac:11:00:04",
          "units": "bit/s",
          "size": 10000000000,
          "configuration": {
            "autonegotiation": "off",
            "broadcast": "yes",
            "driver": "veth",
            "driverversion": "1.0",
            "duplex": "full",
            "ip": "172.17.0.4",
            "link": "yes",
            "multicast": "yes",
            "port": "twisted pair",
            "speed": "10Gbit/s"
          },
          "capabilities": {
            "ethernet": true,
            "physical": "Physical interface"
          }
        }
      ]
    },
    "lsusb": [
      {
        "bus_number": "001",
        "device_id": "001",
        "device_bus_number": "1d6b",
        "manufacture_id": "Bus 001 Device 001: ID 1d6b:0002",
        "manufacture_device_name": "Bus 001 Device 001: ID 1d6b:0002"
      },
      {
        "bus_number": "001",
        "device_id": "003",
        "device_bus_number": "0424",
        "manufacture_id": "Bus 001 Device 003: ID 0424:2514",
        "manufacture_device_name": "Bus 001 Device 003: ID 0424:2514"
      },
      {
        "bus_number": "001",
        "device_id": "002",
        "device_bus_number": "0424",
        "manufacture_id": "Bus 001 Device 002: ID 0424:2514",
        "manufacture_device_name": "Bus 001 Device 002: ID 0424:2514"
      },
      {
        "bus_number": "001",
        "device_id": "005",
        "device_bus_number": "0424",
        "manufacture_id": "Bus 001 Device 005: ID 0424:7800",
        "manufacture_device_name": "Bus 001 Device 005: ID 0424:7800"
      },
      {
        "bus_number": "001",
        "device_id": "004",
        "device_bus_number": "1415",
        "manufacture_id": "Bus 001 Device 004: ID 1415:2000",
        "manufacture_device_name": "Bus 001 Device 004: ID 1415:2000"
      }
    ],
    "lscpu": {
      "Architecture": "armv7l",
      "Byte Order": "Little Endian",
      "CPU(s)": "4",
      "On-line CPU(s) list": "0-3",
      "Thread(s) per core": "1",
      "Core(s) per socket": "4",
      "Socket(s)": "1",
      "Vendor ID": "ARM",
      "Model": "4",
      "Model name": "Cortex-A53",
      "Stepping": "r0p4",
      "CPU max MHz": "1400.0000",
      "CPU min MHz": "600.0000",
      "BogoMIPS": "89.60",
      "Flags": "half thumb fastmult vfp edsp neon vfpv3 tls vfpv4 idiva idivt vfpd32 lpae evtstrm crc32"
    },
    "lspci": null,
    "lsblk": [
      {
        "name": "mmcblk0",
        "maj:min": "179:0",
        "rm": "0",
        "size": "29.7G",
        "ro": "0",
        "type": "disk",
        "mountpoint": null,
        "children": [
          {
            "name": "mmcblk0p1",
            "maj:min": "179:1",
            "rm": "0",
            "size": "43.9M",
            "ro": "0",
            "type": "part",
            "mountpoint": null
          },
          {
            "name": "mmcblk0p2",
            "maj:min": "179:2",
            "rm": "0",
            "size": "29.7G",
            "ro": "0",
            "type": "part",
            "mountpoint": "/etc/hosts"
          }
        ]
      }
    ]
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

[userinput]: https://github.com/dcmartin/open-horizon/blob/master/hal/userinput.json
[service-json]: https://github.com/dcmartin/open-horizon/blob/master/hal/service.json
[build-json]: https://github.com/dcmartin/open-horizon/blob/master/hal/build.json
[dockerfile]: https://github.com/dcmartin/open-horizon/blob/master/hal/Dockerfile


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
