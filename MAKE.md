# `MAKE.md` - how to build the software

## A. _Quick-Start_

**All services in this [repository][repository] may be built OOTB (out-of-the-box) by running the `make` command.**

The top-level [makefile][makefile]  by default will `build` and `run` (locally) the containers for each _service_ in this repository, and then `check` each _service_ (see `make check` below); for more information refer to [`MAKEVARS.md`][makevars-md]

# B. Detailed instructions

While these services may be built automatically, there are a number of details important for successful development and deployment.  Each _service_ in an Open Horizon _exchange_ is associated with an _organization_ and may be either **private** to that organization or **public** to all organizations on the exchange.  

## 1. Service configuration
The _service_ configuration and `make` process is controlled by a few command lines options and three JSON files.   The JSON files are:

+ `build.json` - service supported architectures and `BUILD_FROM` targets
+ `service.json` - service definition including `label`, `org`, `url`, and other information
+ `pattern.json`- information for the _service_ as a _pattern_ of services  [**_optional_**] 

### 1.1 `build.json`
This JSON configuration file maps supported architectures to designated containers from which to build.  For example, the [`cpu`][cpu-service] service supports four architectures:

```
{
    "build_from": {
        "arm64": "arm64v8/alpine:3.8",
        "amd64": "alpine:3.8",
        "arm": "arm32v6/alpine:3.8",
        "i386": "i386/alpine:3.8"
    }
}
```
[cpu-service]: https://github.com/dcmartin/open-horizon/tree/master/cpu

### 1.2 `service.json`
This JSON configuration file specifies information about the service itself and is used as a template; the build process utilizes the following:

+ `org` - a _string_ for the _organization_ for this service in the _exchange_ 
+ `url` - a _string_ uniquely identifying the service in the _exchange_
+ `label` - a _string_ used for identifying the _service_ in the _organization_
+ `version` - a _string_ representing the [version][semver] of the service

The `label` and `version` values are used in the `make` process to derive other identifiers, e.g. the Docker image `name`; it is **recommended**, but not required, that the `label` be unique within the _organization_.
 
#### 1.2.1`userInput` in `service.json`

The `userInput` specifies values provided to the service as environment variables.  Some services _require_ values to be provided.  During development and testing, required values may be specified through files of the same name.  For example, the `yolo2msghub` service requires `YOLO2MSGHUB_APIKEY` as indicated by its `defaultValue` being `null` (see below and [here][yolo2msghub-service]).

[yolo2msghub-service]: https://github.com/dcmartin/open-horizon/blob/master/yolo2msghub/service.json

```
"userInput": [
...
 { "name": "YOLO2MSGHUB_APIKEY", "label": "message hub API key", "type": "string", "defaultValue": null },
...
]
```

In this case a file may be created by processing the Kafka API key provided by the IBM [EventStreams][message-hub] service; for example:

```
% jq '.api_key' apiKey.json > YOLO2MSGHUB_APIKEY
```

[message-hub]: https://www.ibm.com/cloud/message-hub

#### 1.2.1 `ports` in `service.json`
 The `ports` specifies the ports to be mapped _from_ the container to the localhost, e.g. the following maps the service port `80` to the localhost port `8581`.  Both `tcp` and `udp` ports may be specified.  This port mapping is _only_ done when running the service locally (see `make run`).
 
```
 "ports": {  "80/tcp": 8581 }
```

#### 1.2.2 `tmpfs` in `service.json`
The `tmpfs` specifies whether a temporary file-system should be created in RAM and it's `size` in bytes, `destination` directory (default "/tmpfs"), and `mode` permissions (default `0177`).

```
 "tmpfs": {  "size": 2048000, "destination": "/tmpfs", "mode": "0177" }
```

### 1.3 `pattern.json`
This configuration file specifies information about using the _service_ in a pattern with other services for the architectures supported.  If a `pattern.json` files does not exist, the _service_ has not been configured as a _pattern_ and some `make` targets will not succeed.  In addition, before a _pattern_ can be published to an _exchange_, all `requiredServices` as specified in the `service.json` must already be published to the exchange (see `make publish` below).

```
{
  "label": "yolo2msghub",
  "description": "yolo and friends as a pattern",
  "public": true,
  "services": [
    { "serviceUrl": "com.github.dcmartin.open-horizon.yolo2msghub", "serviceOrgid": "dcmartin@us.ibm.com", "serviceArch": "amd64", "serviceVersions": [ { "version": "0.0.1" } ] },
    { "serviceUrl": "com.github.dcmartin.open-horizon.yolo2msghub", "serviceOrgid": "dcmartin@us.ibm.com", "serviceArch": "arm", "serviceVersions": [ { "version": "0.0.1" } ] },
    { "serviceUrl": "com.github.dcmartin.open-horizon.yolo2msghub", "serviceOrgid": "dcmartin@us.ibm.com", "serviceArch": "arm64", "serviceVersions": [ { "version": "0.0.1" } ] }
  ]   
}  
```

### 1.4 `userinput.json`

This configuration file is _not_ used in the build process, but provides a template for specifying the values required to _register_ for this pattern and is used to run the `start` the service (n.b. see `make start`).  The values specified in this file are utilized if there are no corresponding files with the variable name, for example `YOLO2MSGHUB_APIKEY`.

## 2. Dockerfile
The `Dockerfile` contains details on the required operating environment and package installation.  By default, all services are configured to launch `/usr/bin/run.sh` which invokes `/usr/bin/service.sh` to respond to RESTful `GET` for status on its designated port (n.b. default `80`); see the `make check` section below for details.  There should be no need to change this file.

## 3. `make`

The build process is controlled by the `make` command and two files: [`makefile`][makefile] at the top-level and [`service.makefile`][service-makefile], which all _services_ share.  There are many variables in these files, but usually do not require modification (see command-line options); for more information refer to [`MAKEVARS.md`][makevars-md]

[makevars-md]: https://github.com/dcmartin/open-horizon/blob/master/MAKEVARS.md
[service-makefile]: https://github.com/dcmartin/open-horizon/blob/master/service.makefile
[makefile]: https://github.com/dcmartin/open-horizon/blob/master/makefile

The **make** command by **default** performs `build`,`run`,`check`; other available targets:

+ `build` - build container using `build.json` and `service.json`
+ `run` - run container locally; map `ports` as in `service.json`
+ `check` - checks the service locally on mapped port
+ `push` - push the container to Docker registry; __requires__ `DOCKER_ID` and `docker login`
+ `publish` - publish service to _exchange_; __requires__ `hzn` CLI
+ `verify` - verify service on exchange; __requires__ `hzn` CLI
+ `start` - intiates service and required services locally; __requires__ `hzn` CLI
+ `test` - tests the service output using `test-{service}.sh` for conformant payload
+ `clean` - remove all generated artefacts, including running containers and images
+  `distclean` - remove all residuals, including variable and key files


###  3.0 Command-line options
The command line directives are optional, but may be specified to control the architecture and naming of the artefacts.  By default the native architecture is automatically detected and `TAG` is empty.

+ `BUILD_ARCH` - specify the architecture for the build process per `build.json` options
+ `TAG` - a _string_ value appened to _almost_ all artefacts, including Docker images, service `url`, ..

These options may be specified when invoking the `make` command (see below) or statically specified by creating a file with the same name in the top-level directory, e.g. `echo 'experimental' > TAG`)

```
% make BUILD_ARCH=arm64 TAG=experimental
```

### 3.1 `build`
This target builds a local Docker container for the service.  Output from the build is stored in the file `build.out`

### 3.2 `run`
This target runs the local Docker container for the service.

### 3.3 `check`
This target checks the service on its mapped port; see `service.json` for individual services.  For example, the `cpu` service responds on port `8581` with the following payload when `make check` is invoked in the `cpu/` directory.

```
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
  "date": 1549907345,
  "service": "cpu",
  "hostname": "7a635ad1f814-172017000002",
  "pid": 21,
  "cpu": {
    "date": 1549911546,
    "log_level": "info",
    "debug": false,
    "period": 60,
    "interval": 1,
    "percent": 1.49
  }
}
```

### 3.4 `push`
This target pushes the local Docker container to [Docker hub][docker-hub]

[docker-hub]: http://hub.docker.com/

### 3.5 `publish`
This target publishes containers in Docker hub to the Open Horizon _exchange_.

### 3.6 `verify`
This target verifies the service(s) in the Open Horizon _exchange_.

### 3.7 `test`
This target may be used against the local container, the local service (n.b. see `start` target), or any node running the _service_.  The service is accessed on its external `port` without mapping.  The payload is processed into a JSON type structure, including _object_, _array_, _number_, _string_.

```
{
  "hzn": {
    "agreementid": "string",
    "arch": "string",
    "cpus": "number",
    "device_id": "string",
    "exchange_url": "string",
    "host_ips": [
      "string"
    ],
    "organization": "string",
    "pattern": "string",
    "ram": "number"
  },
  "date": "number",
  "service": "string",
  "hostname": "string",
  "pid": "number",
  "cpu": {
    "date": "number",
    "log_level": "string",
    "debug": "boolean",
    "period": "number",
    "interval": "number",
    "percent": "number"
  }
}
```
### 3.8 `start`
The `start` target will initiate the _service_ with all `requiredServices` as specified in `service.json`.  For example:

```
cpu/% make start
--- INFO -- removing docker container amd64_cpu-beta for service cpu
amd64_cpu-beta
Stop service: service(s) cpu with instance id prefix com.github.dcmartin.open-horizon.cpu-beta_0.0.1_8617f17b-f2b8-4761-ba35-2806f6d5c4e9
Stopped service.
--- INFO -- building docker container cpu-beta with tag dcmartin/amd64_cpu-beta:0.0.1
--- INFO -- pushing docker container dcmartin/amd64_cpu-beta:0.0.1 for service cpu
The push refers to repository [docker.io/dcmartin/amd64_cpu-beta]
9bce4b746201: Layer already exists 
5f6c19678c43: Layer already exists 
767f936afb51: Layer already exists 
0.0.1: digest: sha256:58139697236f8cbfd921837bf693c2141cb0d0796a88e9e2a10fe73f80f2b11b size: 947
--- INFO -- building horizon
Created horizon metadata files in /Users/dcmartin/GIT/open-horizon/cpu/horizon. Edit these files to define and configure your new service.
+++ WARN ../checkvars.sh 74370 -- service template unspecified; default: service.json
+++ WARN ../mkdepend.sh 74382 -- modifying service URL with beta in horizon/userinput.json and horizon/service.definition.json
--- INFO -- starting cpu from horizon
+++ WARN ../checkvars.sh 74415 -- service template unspecified; default: service.json
Service project /Users/dcmartin/GIT/open-horizon/cpu/horizon verified.
Service project /Users/dcmartin/GIT/open-horizon/cpu/horizon verified.
Start service: service(s) cpu with instance id prefix 19c8bf62b10e5eb63bf0a46ba6f958fcc073a766353cb45fea1cb2d108985db3
Running service.
```

### 3.9 `pattern`

The `pattern` target will publish the _service_ as a _pattern_ in the _exchange_.  A `pattern.json` file must be present. 


# Changelog & Releases

Releases are based on [Semantic Versioning][semver], and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.
[semver]: https://semver.org/


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


[amd64-layers-shield]: https://images.microbadger.com/badges/image/dcmartin/plex-amd64.svg
[amd64-microbadger]: https://microbadger.com/images/dcmartin/plex-amd64
[armhf-microbadger]: https://microbadger.com/images/dcmartin/plex-armhf
[armhf-layers-shield]: https://images.microbadger.com/badges/image/dcmartin/plex-armhf.svg

[amd64-version-shield]: https://images.microbadger.com/badges/version/dcmartin/plex-amd64.svg
[amd64-arch-shield]: https://img.shields.io/badge/architecture-amd64-blue.svg
[amd64-dockerhub]: https://hub.docker.com/r/dcmartin/plex-amd64
[amd64-pulls-shield]: https://img.shields.io/docker/pulls/dcmartin/plex-amd64.svg
[armhf-arch-shield]: https://img.shields.io/badge/architecture-armhf-blue.svg
[armhf-dockerhub]: https://hub.docker.com/r/dcmartin/plex-armhf
[armhf-pulls-shield]: https://img.shields.io/docker/pulls/dcmartin/plex-armhf.svg
[armhf-version-shield]: https://images.microbadger.com/badges/version/dcmartin/plex-armhf.svg
[i386-arch-shield]: https://img.shields.io/badge/architecture-i386-blue.svg
[i386-dockerhub]: https://hub.docker.com/r/dcmartin/plex-i386
[i386-layers-shield]: https://images.microbadger.com/badges/image/dcmartin/plex-i386.svg
[i386-microbadger]: https://microbadger.com/images/dcmartin/plex-i386
[i386-pulls-shield]: https://img.shields.io/docker/pulls/dcmartin/plex-i386.svg
[i386-version-shield]: https://images.microbadger.com/badges/version/dcmartin/plex-i386.svg
