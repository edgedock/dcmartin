# `yolo2msghub` - Send entity recognition counts to Kafka

Send YOLO classified image entity counts to Kafka; updates as often as underlying services provide.
This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Service discovery
+ `org` - `dcmartin@us.ibm.com/yolo2msghub`
+ `url` - `com.github.dcmartin.open-horizon.yolo2msghub`
+ `version` - `0.0.1`
### Architecture(s) supported
+ `arm` - RaspberryPi (armhf)
+ `amd64` - AMD/Intel 64-bit (x86-64)
+ `arm64` - nVidia TX2 (aarch)

### User input
Nodes should _register_ using a derivative of the template [`userinput.json`][userinput].  Variables may be modified in the `userinput.json` file, _or_ may be defined in a file of the same name, for example:
```
% jq '.api_key' {kafka-apiKey-file} > YOLO2MSGHUB_APIKEY
```
#### REQUIRED
+ `YOLO2MSGHUB_APIKEY` - message hub API key
#### OPTIONAL
+ `YOLO2MSGHUB_BROKER` - message hub brokers
+ `YOLO_ENTITY` - entity to count; defaults to `person`
+ `YOLO_PERIOD` - seconds between updates; defaults to `0`
+ `LOCALHOST_PORT` - port for access; default 8587 
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
#### Example registration
```
% hzn register -u {org}/iamapikey:{apikey} -n {nodeid}:{token} -e {org} -f userinput.json
```
### Sample

![sample.png](sample.png?raw=true "YOLO2MSGHUB")

## Services

This _service_ utilizes the following required services:

+ [`yolo`][yolo-service] - captures images from camera and counts specified entity
+ [`hal`][hal-service] - provides hardware inventory layer API for client
+ [`cpu`][cpu-service] - provides CPU percentage API for client
+ [`wan`][wan-service] - provides wide-area-network information API for client

[yolo-service]: https://github.com/dcmartin/open-horizon/tree/master/yolo
[hal-service]: https://github.com/dcmartin/open-horizon/tree/master/hal
[cpu-service]: https://github.com/dcmartin/open-horizon/tree/master/cpu
[wan-service]: https://github.com/dcmartin/open-horizon/tree/master/wan

# Getting started

Copy this [repository][repository], change to the `yolo2msghub` directory, then use the **make** command; quick-start below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/yolo2msghub
% make
...
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
# Building

The **make** command is used to `build`,`run`,`check` (default), `publish`, `verify`,`start`, and `clean`.

+ `build` - build container using `build.json` and `service.json`
+ `run` - run container locally; map `ports` in `service.json`
+ `check` - tests the service locally on mapped port
+ `push` - push the container to Docker registry; __requires__ `DOCKER_ID` and `docker login`
+ `publish` - publish service to _exchange_; __requires__ `hzn` CLI
+ `verify` - verify service on exchange; __requires__ `hzn` CLI
+ `start` - intiates service and required services locally; __requires__ `hzn` CLI
+ `clean` - remove all generated artefacts, including running containers and images

### `check`
```
% make check
...
{
  "hostname": "05acf6435757-192168016002",
  "service": "yolo2msghub",
  "device": "test-cpu-2",
  "pid": 9,
  "yolo2msghub": {
    "log_level": "info",
    "debug": "false",
    "services": [ { "name": "yolo", "url": "http://yolo:80" }, { "name": "hal", "url": "http://hal:80" }, { "name": "cpu", "url": "http://cpu:80" }, { "name": "wan", "url": "http://wan:80" } ],
    "date": 1548798539,
    "yolo": { "log_level": "info", "debug": "false", "date": 1548798507, "period": 0, "entity": "person", "time": 44.725642, "count": 0, "width": 320, "height": 240, "scale": "320x240", "mock": "false", "image": "redacted" },
    "hal": { "log_level": "info", "debug": "false", "date": 1548797851, "period": 60, "lshw": { "id": "b5dd54a7a499", "class": "system", "claimed": true, "description": "Computer", "product": "Raspberry Pi 3 Model B Plus Rev 1.3", "serial": "000000005770a507", "width": 32, "children": [ { "id": "core", "class": "bus", "claimed": true, "description": "Motherboard", "physid": "0", "capabilities": { "raspberrypi_3-model-b-plus": true, "brcm_bcm2837": true }, "children": [ { "id": "cpu:0", "class": "processor", "claimed": true, "description": "CPU", "product": "cpu", "physid": "0", "businfo": "cpu@0", "units": "Hz", "size": 1400000000, "capacity": 1400000000, "capabilities": { "cpufreq": "CPU Frequency scaling" } }, { "id": "cpu:1", "class": "processor", "disabled": true, "claimed": true, "description": "CPU", "product": "cpu", "physid": "1", "businfo": "cpu@1", "units": "Hz", "size": 1400000000, "capacity": 1400000000, "capabilities": { "cpufreq": "CPU Frequency scaling" } }, { "id": "cpu:2", "class": "processor", "disabled": true, "claimed": true, "description": "CPU", "product": "cpu", "physid": "2", "businfo": "cpu@2", "units": "Hz", "size": 1400000000, "capacity": 1400000000, "capabilities": { "cpufreq": "CPU Frequency scaling" } }, { "id": "cpu:3", "class": "processor", "disabled": true, "claimed": true, "description": "CPU", "product": "cpu", "physid": "3", "businfo": "cpu@3", "units": "Hz", "size": 1400000000, "capacity": 1400000000, "capabilities": { "cpufreq": "CPU Frequency scaling" } }, { "id": "memory", "class": "memory", "claimed": true, "description": "System memory", "physid": "4", "units": "bytes", "size": 972234752 } ] }, { "id": "network", "class": "network", "claimed": true, "description": "Ethernet interface", "physid": "1", "logicalname": "eth0", "serial": "02:42:ac:1d:00:02", "units": "bit/s", "size": 10000000000, "configuration": { "autonegotiation": "off", "broadcast": "yes", "driver": "veth", "driverversion": "1.0", "duplex": "full", "ip": "172.29.0.2", "link": "yes", "multicast": "yes", "port": "twisted pair", "speed": "10Gbit/s" }, "capabilities": { "ethernet": true, "physical": "Physical interface" } } ] }, "lsusb": [ { "bus_number": "001", "device_id": "001", "device_bus_number": "1d6b", "manufacture_id": "Bus 001 Device 001: ID 1d6b:0002", "manufacture_device_name": "Bus 001 Device 001: ID 1d6b:0002" }, { "bus_number": "001", "device_id": "003", "device_bus_number": "0424", "manufacture_id": "Bus 001 Device 003: ID 0424:2514", "manufacture_device_name": "Bus 001 Device 003: ID 0424:2514" }, { "bus_number": "001", "device_id": "002", "device_bus_number": "0424", "manufacture_id": "Bus 001 Device 002: ID 0424:2514", "manufacture_device_name": "Bus 001 Device 002: ID 0424:2514" }, { "bus_number": "001", "device_id": "005", "device_bus_number": "0424", "manufacture_id": "Bus 001 Device 005: ID 0424:7800", "manufacture_device_name": "Bus 001 Device 005: ID 0424:7800" }, { "bus_number": "001", "device_id": "004", "device_bus_number": "1415", "manufacture_id": "Bus 001 Device 004: ID 1415:2000", "manufacture_device_name": "Bus 001 Device 004: ID 1415:2000" } ], "lscpu": { "Architecture": "armv7l", "Byte Order": "Little Endian", "CPU(s)": "4", "On-line CPU(s) list": "0-3", "Thread(s) per core": "1", "Core(s) per socket": "4", "Socket(s)": "1", "Vendor ID": "ARM", "Model": "4", "Model name": "Cortex-A53", "Stepping": "r0p4", "CPU max MHz": "1400.0000", "CPU min MHz": "600.0000", "BogoMIPS": "89.60", "Flags": "half thumb fastmult vfp edsp neon vfpv3 tls vfpv4 idiva idivt vfpd32 lpae evtstrm crc32" }, "lspci": null, "lsblk": [ { "name": "mmcblk0", "maj:min": "179:0", "rm": "0", "size": "29.7G", "ro": "0", "type": "disk", "mountpoint": null, "children": [ { "name": "mmcblk0p1", "maj:min": "179:1", "rm": "0", "size": "43.9M", "ro": "0", "type": "part", "mountpoint": null }, { "name": "mmcblk0p2", "maj:min": "179:2", "rm": "0", "size": "29.7G", "ro": "0", "type": "part", "mountpoint": "/etc/hosts" } ] } ] },
    "cpu": { "log_level": "info", "debug": "false", "date": 1548820336, "period": 60, "interval": 1, "percent": 79.7 },
    "wan": { "log_level": "info", "debug": "false", "date": 1548797896, "period": 1800, "speedtest": { "download": 6030465.984919555, "upload": 2598608.738590407, "ping": 112, "server": { "url": "http://sjc.speedtest.net/speedtest/upload.php", "lat": "37.3041", "lon": "-121.8727", "name": "San Jose, CA", "country": "United States", "cc": "US", "sponsor": "Speedtest.net", "id": "10384", "url2": "http://sjc2.speedtest.net/speedtest/upload.php", "host": "sjc.host.speedtest.net:8080", "d": 7.476714842887551, "latency": 112 }, "timestamp": "2019-01-29T21:37:37.359821Z", "bytes_sent": 4472832, "bytes_received": 13115612, "share": null, "client": { "ip": "67.164.104.198", "lat": "37.2458", "lon": "-121.8306", "isp": "Comcast Cable", "isprating": "3.7", "rating": "0", "ispdlavg": "0", "ispulavg": "0", "loggedin": "0", "country": "US" } } } }
}
```
### `start`
The `start` target will initiate the _pattern_ with all required _services_; it depends on `publish` and `verify`
```
% make start
...
export HZN_EXCHANGE_URL=https://alpha.edge-fabric.com/v1/ && hzn dev service start -d test/
Service project /home/dcmartin/GIT/open-horizon/yolo2msghub/test verified.
Service project /home/dcmartin/GIT/open-horizon/yolo2msghub/test verified.
Start service: service(s) hal with instance id prefix com.github.dcmartin.open-horizon.hal_0.0.1_089fdddf-2206-4421-a84a-24b8ce95a3d7
Running service.
Start service: service(s) wan with instance id prefix com.github.dcmartin.open-horizon.wan_0.0.1_6adc547b-941f-46de-b189-213d9d98fe3a
Running service.
Start service: service(s) yolo with instance id prefix com.github.dcmartin.open-horizon.yolo_0.0.1_6e7c975a-ac22-4f8c-bad2-d6b97d2b20ec
Running service.
Start service: service(s) yolo2msghub with instance id prefix d1f279369ee592e401daadf249ae4a1196c42a548d3533fda6d7e240c9f483e1
Running service.
```
## Publishing

The `pattern` target will publish the pattern in the exchange.  The [`service.json`][service-json] file must be changed prior.

### `pattern`
```
% make pattern
...
export HZN_EXCHANGE_URL=https://alpha.edge-fabric.com/v1/ && hzn exchange pattern publish -o "dcmartin@us.ibm.com" -u iamapikey:{apikey} -f pattern.json -p yolo2msghub -k {private-key-file} -K {public-key-file}
Updating yolo2msghub in the exchange...
Storing IBM-6d570b1519a1030ea94879bbe827db0616b9f554-public.pem with the pattern in the exchange...
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
