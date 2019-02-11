# `MAKE.md` - how to build the software

## A. _Quick-Start_

**All services in this [repository][repository] may be built OOTB (out-of-the-box) by running the `make` command.**

The top-level [makefile][makefile]  by default will `build` and `run` (locally) the containers for each _service_ in this repository, and then `check` each _service_ (see `make check` below).  All services share a common [service.makefile][service-makefile] which is driven through the service configuration files.

[service-makefile]: https://github.com/dcmartin/open-horizon/blob/master/service.makefile
[makefile]: https://github.com/dcmartin/open-horizon/blob/master/makefile

# B. Detailed instructions

While these services may be built automatically, there are a number of details important for successful development and deployment.  Each _service_ in an Open Horizon _exchange_ is associated with an _organization_ and may be either **private** to that organization or **public** to all organizations on the exchange.  

## 1. Configuration files
These build process is controlled a few command lines options and three JSON files.  

+ `build.json` - service supported architecture `BUILD_FROM` targets
+ `service.json` - service definition including `label`, `org`, `url`, `port`, and other information
+ `pattern.json`- configuration information for the _service_ as a _pattern_ of services  [**optional**] 

### 1.1 `build.json`
This JSON configuration file maps supported architectures to designated containers from which to build.  For example the `cpu` service supports four architectures:

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

### 1.2 `service.json`
This JSON configuration file specifies information about the service itself and is used as a template; the build process utilizes the following:

+ `org` - a _string_ for the _organization_ for this service in the _exchange_ 
+ `url` - a _string_ uniquely identifying the service in the _exchange_
+ `label` - a _string_ used for identifying the _service_ in the _organization_
+ `version` - a _string_ representing the [version][semver] of the service

The `label` and `version` values are used in the `make` process to derive other identifiers, e.g. the Docker image `name`; it is **recommended**, but not required, that the `label` be unique within the _organization_.
 
#### 1.2.1`userInput`

The `userInput` from `service.json` specifies values provided to the service as environment variables.  Some services _require_ values to be provided.  During development and testing, required values may be specified through files of the same name.  For example, the `yolo2msghub` service requires `YOLO2MSGHUB_APIKEY` as indicated by its `defaultValue` being `null` (see below and [here][yolo2msghub-service]).

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

## 2. Dockerfile
This JSON configuration file 

In addition to the **Configuration**, the `Dockerfile` contains details on the required operating environment and package installation.  By default, all services are configured to launch `/usr/bin/run.sh` which invokes `/usr/bin/service.sh` to respond to RESTful `GET` for status on its designated port (n.b. default `80`); see the `make check` section below for details.

## 3. `make`

The **make** command by **default** performs `build`,`run`,`check`; available targets:

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
The command line directives are options, but include:

+ `BUILD_ARCH` - specify the architecture for the build process per `build.json` options
+ `TAG` - a _string_ value appened to _almost_ all artefacts, including Docker images, service `url`, ..

These options may be specified when invoking the `make` command:

```
% make BUILD_ARCH=arm64 TAG=experimental
```


### 3.1 `build`
This target builds a Docker container for local execution.

### 3.2 `run`
This target runs the locally built Docker container for the service.

### 3.3 `check`
This target accesses the service on its mapped service port; see `service.json` for individual services

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
This target pushes the locally built Docker container to [Docker hub][docker-hub]

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

### 3.9 `pattern`

The `pattern` target will publish the pattern in the exchange.  The [`service.json`][service-json] file must be changed prior.

```
% make pattern
...
export HZN_EXCHANGE_URL=https://alpha.edge-fabric.com/v1/ && hzn exchange pattern publish -o "dcmartin@us.ibm.com" -u iamapikey:{apikey} -f pattern.json -p yolo2msghub -k {private-key-file} -K {public-key-file}
Updating yolo2msghub in the exchange...
Storing IBM-6d570b1519a1030ea94879bbe827db0616b9f554-public.pem with the pattern in the exchange...
```
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
