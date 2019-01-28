# `yolo` - You Only Look Once service

Provides entity count information as micro-service; updates periodically (default `0` seconds).  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Architecture

This service supports the following architectures:

+ `arm` - RaspberryPi (armhf)
+ `amd64` - AMD/Intel 64-bit (x86-64)
+ `arm64` - nVidia TX2 (aarch)

## How To Use

Copy this [repository][repository], change to the `yolo` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon .
% cd open-horizon/yolo
% make
...
{
  "hostname": "c2ceb8a68871-172017000002",
  "org": "dcmartin@us.ibm.com",
  "pattern": "yolo",
  "device": "davidsimac.local-amd64_yolo",
  "pid": 7,
  "yolo": null
}
```
The initial call to the service will return `null` for the `yolo` attribute until the service has completed its initial execution; subsequent calls should return a complete payload; see below:
```
{
  "hostname": "30f977daac44-172017000002",
  "org": "dcmartin@us.ibm.com",
  "pattern": "yolo",
  "device": "test-cpu-2-arm_yolo",
  "pid": 9,
  "yolo": {
    "date": 1548695016,
    "time": 37.676646,
    "entity": "person",
    "count": 0,
    "width": 320,
    "height": 240,
    "scale": "320x240",
    "mock": "false",
    "image": "<redacted>"
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
## Organization

Prior to _publishing_ the `service.json` [file][service-json] must be modified for your organization.

+ `org` - `dcmartin@us.ibm.com/yolo`
+ `url` - `com.github.dcmartin.open-horizon.yolo`
+ `version` - `0.0.1`

## Publishing
The **make** targets for `publish` and `verify` make the service and its container available for node registration.
```
% make publish
...
Using 'dcmartin/amd64_yolo@sha256:b1d9c38fee292f895ed7c1631ed75fc352545737d1cd58f762a19e53d9144124' in 'deployment' field instead of 'dcmartin/amd64_yolo:0.0.1'
Creating com.github.dcmartin.open-horizon.yolo_0.0.1_amd64 in the exchange...
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
[macos-install]: https://github.com/open-horizon/anax/releases
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: https://github.com/dcmartin/open-horizon/blob/master/setup/README.md
