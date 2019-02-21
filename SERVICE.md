# CI/CD for building services

Services are defined within a directory hierarchy of this [repository][repository].  Services include:

+ [`cpu`][cpu-service] - provide CPU usage as percentage (0-100)
+ [`wan`][wan-service] - provide Wide-Area-Network information
+ [`hal`][hal-service] - provide Hardware-Abstraction-Layer information
+ [`yolo`][yolo-service] - recognize `person` and othe entities from image
+ [`yolo2masgub`][yolo2msghub-service] - transmit `yolo`, `hal`, `cpu`, and `wan` information to Kafka
+ [`motion2mqtt`][motion2mqtt-service] - transmit motion detected images to MQTT

While all services in this repository share a common design (see [`DESIGN.md`][design-mg]), that design is independent _service_ build automation process.

## 1. Build process

Within each directory is a set of files to control the build process:

+ `Makefile` - build configuration and control for `make` command
+ `.travis.yml` - process automation configuration and control for [Travis][travis-ci]
+ `Dockerfile` - a cross-architecture container definition
+ `build.json` - Docker container configuration
+ `service.json` - _service_ configuration template
+ `userinput.json` - variables template for use in testing _service_
+ `pattern.json` - [**optional**] _pattern_ configuration template (see [`PATTERN.md`][pattern-md] for more information).

### 1.1 `Makefile` &&  `.travis.yml`

The `Makefile` is shared across all services; it is a symbolic link to a common [`service.makefile`][service-makefile] in the root of the repository.
Services are built using `make` command and a set of targets (see [`MAKE.md`][make-md] and [`MAKEVARS.md`][makevars-md]).
`.travis.yml`

The [Travis][travis-ci] process automation system for continuous-integration enables the execution of the build process and tools in a cloud environment. Travis expectations and limitations effect the CI/CD process.  Please see [`TRAVIS.md`][travis-md] for more information.

### 1.2 `Dockerfile` && `build.json`

The `Dockerfile` controls the container build process.  A critical component of that process is the `FROM` directive, which indicates the container from which to build.  The `build.json` configuration file provides a mapping for each architecture the _service_ supports.  For example, an Alpine-based LINUX container might include the following:

```
"build_from": {
    "arm64": "arm64v8/alpine:3.8",
    "amd64": "alpine:3.8",
    "arm": "arm32v6/alpine:3.8"
}
```

This example indicates three (3) supported architectures with values: `arm64`, `amd64`, and `arm`, and corresponding Docker container tags. The architecture values must be common across the build automation process and configuration files; it also **effects the building and naming of container images and services**. However, values may be specified as necessary to ensure uniqueness.

The `Dockerfile` also includes information for `LABEL` container information, for example:

```
LABEL \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date="${BUILD_DATE}" \
    org.label-schema.build-arch="${BUILD_ARCH}" \
    org.label-schema.name="cpu" \
    org.label-schema.description="base alpine container" \
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/master/cpu/" \
    org.label-schema.vcs-ref="${BUILD_REF}" \
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
```

### 1.3 `service.json` && `userinput.json`

The `service.json` configuration template provides standard Open Horizon service metadata and state information, including:

+ `org` - _organization_ in _exchange_
+ `url` - unique identifier for _service_ in organization
+ `version` - semantic version of _service_ [**state**]
+ `arch` - `null` in template; derived from `build.json`

In addition to the standard service configuration semantics and structure, there are three additional modifications:

+ `label` - this value is now used as a token (**non-breaking-string**), aka  _slug_, identifier for the service and _pattern_
+ `ports` - a mapping of service ports to host ports during local execution
+ `tmpfs` - [**optional**] specification for a temporary, in-memory, file-system for use on IoT devices

Ports may be specified for mapping both TCP and UDP, for example:

```
"ports": {
  "8082/tcp": 8082,
  "8080/tcp": 8080,
  "8081/tcp": 8081
}
```

The `tmpfs` specifies whether a temporary file-system should be created in RAM and it's `size` in bytes, `destination` directory (default "/tmpfs"), and `mode` permissions (default `0177`).

```
 "tmpfs": {  "size": 2048000, "destination": "/tmpfs", "mode": "0177" }
```

The `userinput.json` provides configuration for variables defined the _service_ in the `service.json`; this is service dependent.  Variables, including secrets, may also be defined as files with JSON content.  For example, the `yolo2msghub` service's required Kafka API key variable -- `YOLO2MSGHUB_APIKEY` -- would be created from an IBM MessageHub Kafka API key JSON file:

```
% jq '.api_key' {kafka-apiKey-file} > YOLO2MSGHUB_APIKEY
```

## 2. Build scripts

In addition, there are a set of build support scripts that provide required services for the automated build process; as with the `Makefile`, all scripts are shared across services.

+ `docker-run.sh` - standardized local execution of Docker containers per `service.json` configuration template
+ `mkdepend.sh` - utilizes `hzn` CLI to create build artefacts
+ `checkvars.sh`- process _service_ variables for `userinput.json`
+ `exchange-test.sh` - test _exchange_ for _service_ pre-requisites; (**note:** linked as `service-test.sh`)
+ `fixpattern.sh` - process _pattern_ configuration template (see [`PATTERN.md`][pattern-md])
+ `test-service.sh`- test _service_ output (**note:** linked as `test-<service>.sh`)
+ `test.sh` - test harness for processing output from `test-service.sh`

### 2.1 `docker-run.sh`

Run the _service_ locally as configured in the template and include all variables, port definitions, temporary file-system, and privilege.  Other parameters currently available for _service_ configuration are _not_ available.

### 2.2 `mkdepend.sh`

Utilize `hzn` CLI to create temporary build directory and process configuration template for _service_.

### 2.3 `checkvars.sh`

Gather variable(s) values as specified in _service_ configuration template, `userinput.json`, or corresponding files in directory.

### 2.4 `test-service.sh` && `test.sh`

Perform a test of the _service_ to support the test-harness (`test.sh`) for any service; the script name is dependent on the _service_ `label`.  All services share a common `'test-service.sh` script, symbolically linked using the service label, e.g. `test-yolo2msghub.sh`.

### 2.5 `service-test.sh` (_aka_ `exchange-test.sh`)

One script with two names for interrogating the _exchange_.  When invoked as `service-test.sh`, which is symbolically linked to `exchange-test.sh`, the _service_ is tested to determine if all required services are up-to-date with respect to organization, architecture, and semantic version number.  Out-of-date service configurations will fail with an error message.

## 3. Build automation

The `make` program is used to build; there is no software installation required by default -- except `make`, `git`, `curl`, `jq`, and [Docker][docker-start]. The automated CI/CD process utilizes [Travis CI][travis-ci] with this [YAML][travis-yaml]; please refer to [`TRAVIS.md`][travis-md] for more information. There is an accelerated [video][build-pattern-video] of building a pattern.

### 3.1 Pre-requisites

A _quick-start_ for Debian LINUX (Ubuntu or Raspbian) is to install `docker` and the build tools:

```
wget -qO - get.docker.com  | sh
sudo addgroup $(whoami) docker
sudo apt install -y git make curl jq
```

**NOTE**:  Then `logout` and login to establish `docker` group privileges.

### 3.2 Getting started

Clone the GIT repo and `make` the software. 

```
mkdir ~/gitdir
cd ~/gitdir
git clone http://github.com/dcmartin/open-horizon
cd open-horizon
make
```

The default target for the `make` process will `build` the container images, `run` them locally, and `check` the status of each _service_. More information is available in [`MAKE.md`][make-md].

### 3.3 Build a service

The build process for each service is identical.  As state above, the _default_ target is to build, run, and check the status of the service.  These targets do _not_ include the required services, which are only invoked when testing the service as a whole.  In addition to the `build`, `run`, and `check` targets, there are specific targets for services:

#### 3.3.1 `service-start`

This target will ensure that the service is built and then initiate the service using the `hzn` CLI commands.  All services specified, including required services, will also be initiated and appropriate virtual private networks will be established.  Please refer to the Open Horizon documentation for more details on the `hzn` command-line-interface.

#### 3.3.2 `service-stop`

This target will stop the services and all required services initiated using the `service-start` target.

#### 3.3.3 `service-publish`

This target will publish the service to the exchange, checking that appropriate modifications of the service `version` and its required services have been made.

#### 3.3.4 `service-verify`

This target will verify that the service is published into the exchange.

[docker-start]: https://www.docker.com/get-started
[make-md]: https://github.com/dcmartin/open-horizon/blob/master/MAKE.md
[travis-md]: https://github.com/dcmartin/open-horizon/blob/master/TRAVIS.md
[travis-yaml]: https://github.com/dcmartin/open-horizon/blob/master/.travis.yml
[travis-ci]: https://travis-ci.org/
[build-pattern-video]: https://youtu.be/cv_rOdxXidA

[yolo-service]: https://github.com/dcmartin/open-horizon/tree/master/yolo/README.md
[hal-service]: https://github.com/dcmartin/open-horizon/tree/master/hal/README.md
[cpu-service]: https://github.com/dcmartin/open-horizon/tree/master/cpu/README.md
[wan-service]: https://github.com/dcmartin/open-horizon/tree/master/wan/README.md
[yolo2msghub-service]: https://github.com/dcmartin/open-horizon/tree/master/yolo2msghub/README.md
[motion2mqtt-service]: https://github.com/dcmartin/open-horizon/tree/master/motion2mqtt/README.md

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

David C Martin (github@dcmartin.com)

[commits]: https://github.com/dcmartin/open-horizon/commits/master
[contributors]: https://github.com/dcmartin/open-horizon/graphs/contributors
[dcmartin]: https://github.com/dcmartin
[edge-fabric]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/getting-started.html
[edge-install]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/adding-devices.html
[edge-slack]: https://ibm-cloudplatform.slack.com/messages/edge-fabric-users/
[ibm-apikeys]: https://console.bluemix.net/iam/#/apikeys
[ibm-registration]: https://console.bluemix.net/registration/
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: https://github.com/dcmartin/open-horizon/blob/master/setup/README.md
