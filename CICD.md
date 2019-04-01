# `CICD.md` - CI/CD for Open Horizon
This document provides an introduction to the process and tooling utilized in this [repository][repository] to achieve continuous integration and delivery of [Open Horizon][open-horizon] services and patterns to the edge.

[repository]:  https://github.com/dcmartin/open-horizon

[open-horizon]: http://github.com/open-horizon

Please refer to [`TERMINOLOGY.md`][terminology-md] for important terms and definitions.

[terminology-md]: https://github.com/dcmartin/open-horizon/blob/master/TERMINOLOGY.md

# 0. Background
It is presumed that the reader is a software engineer with familiarity with the following:

+ `LINUX` - The free, open-source, UNIX-like, operating system, e.g. [Ubuntu][get-ubuntu] or [Raspbian][get-raspbian]
+ `HTTP` - The HyperText Transfer Protocol and tooling; see [here][curl-intro] and [here][socat-intro]
+ `GIT` - Software management -AAS; see [here][git-basics]
+ `JSON` - JavaScript Object Notation and tooling; see [here][json-intro-jq]
+ `make` - and other standard LINUX build tools; see [here][gnu-make]

[get-ubuntu]: https://www.ubuntu.com/download
[get-raspbian]: https://www.raspberrypi.org/downloads/raspbian/
[gnu-make]: https://www.gnu.org/software/make/
[socat-intro]: https://medium.com/@copyconstruct/socat-29453e9fc8a6
[git-basics]: https://gist.github.com/blackfalcon/8428401
[json-intro-jq]: https://medium.com/cameron-nokes/working-with-json-in-bash-using-jq-13d76d307c4
[curl-intro]: https://www.maketecheasier.com/introduction-curl/

# 1. Introduction
Open Horizon edge fabric provides method and apparatus to run multiple Docker containers on edge nodes.  These nodes are LINUX devices running the Docker virtualization engine, the Open Horizon edge fabric client, and registered with an Open Horizon exchange.

The edge fabric stitches together multiple containers, networks, and physical sensors into a pattern designed to solve a problem.  The only limitation of the fabric are the devices' capabilities; for example one device may have a camera attached and another may not.

The CI/CD process is centered around five (5) primary tools:

+ `make` - control, build, test automation
+ `git` - software version and branch management
+ `docker` - Docker repositories and images
+ `travis` - release change management
+ `hzn` - Open Horizon command-line-interface

## 1.1 Automation controls
The CI/CD automated process is designed to account for multiple branches, registries, and exchanges being utilized as part of the build, test, and release management process.  The attributes that specify these components are listed below and detailed in [`MAKEVARS.md`][makevars-md].

[makevars-md]: https://github.com/dcmartin/open-horizon/blob/master/MAKEVARS.md

+ `DOCKER_NAMESPACE` - identifies the collection of repositories, e.g. `dcmartin`
+ `DOCKER_REGISTRY` - identifies the SaaS server, e.g. `docker.io`
+ `DOCKER_LOGIN` - account identifier for access to registry
+ `DOCKER_PASSWORD` - password to verify account in registry
+ `HZN_ORG_ID` - organizational identifier for Open Horizon edge fabric exchange
+ `HZN_EXCHANGE_URL` - identifies the SaaS server, e.g. `alpha.edge-fabric.com`
+ `HZN_EXCHANGE_USERAUTH` - credentials user to exchange, e.g. `<org>/iamapikey:<apikey>`

# 2. Services
Open Horizon edge fabric services compose one or more Docker containers along with other required services connected with point-to-point virtual-private-networks (VPN). 

### Service identification
Services are identified with the following mandatory attributes:

+ `org` - the organization in the _exchange_
+ `url` - a unique name for the service within the organization
+ `version` - the [_semantic version_][whatis-semantic-version] of the service
+ `arch` - the architecture of the service (see [architecture list][arch-list])

### Service description
Additional descriptive attributes are also available:

+ `label` - an plain-text  string to name the service; **used for defaults in build process**
+ `description` - a plain-text description of the service; maximum 1024 characters
+ `documentation` - link (URL) to documentation, e.g. `README.md` file

### Service composition
The composition attributes include:

+ `shareable` - may be either `singleton` or `multiple` to control instantiation
+ `requiredServices` - an array of services to instantiate and connect  via [VPN][whatis-vpn]
+ `userInput` - an array of dictionary entries for variables passed as environment variables to the container(s)
+ `deployment` - a dictionary of `services` defined by hostname, including Docker image & environment

[whatis-vpn]: https://en.wikipedia.org/wiki/Virtual_private_network

### Example service

The [`cpu/service.json`][cpu-service]  template -- when completed -- is listed below.  The **cpu** service is a `singleton` with no `requiredServices`, four (4) variables in `userInput`, and one `deployment.services` named `cpu` with additional environment variables `SERVICE_LABEL` and `SERVICE_VERSION`.

[cpu-service]: https://github.com/dcmartin/open-horizon/blob/master/cpu/service.json

```JSON
{
  "label": "cpu",
  "description": "Provides hardware abstraction layer as service",
  "documentation": "https://github.com/dcmartin/open-horizon/cpu/README.md",
  "org": "dcmartin@us.ibm.com",
  "url": "com.github.dcmartin.open-horizon.cpu-beta",
  "version": "0.0.3",
  "arch": "arm64",
  "public": true,
  "sharable": "singleton",
  "requiredServices": [],
  "userInput": [
    {
      "name": "CPU_PERIOD",
      "label": "seconds between update",
      "type": "int",
      "defaultValue": "60"
    },
    {
      "name": "CPU_INTERVAL",
      "label": "seconds between cpu testing",
      "type": "int",
      "defaultValue": "1"
    },
    {
      "name": "LOG_LEVEL",
      "label": "specify logging level",
      "type": "string",
      "defaultValue": "info"
    },
    {
      "name": "DEBUG",
      "label": "debug on/off",
      "type": "boolean",
      "defaultValue": "false"
    }
  ],
  "deployment": {
    "services": {
      "cpu": {
        "environment": [
          "SERVICE_LABEL=cpu",
          "SERVICE_VERSION=0.0.3"
        ],
        "image": "dcmartin/arm64_com.github.dcmartin.open-horizon.cpu-beta:0.0.3",
        "privileged": true,
        "specific_ports": []
      }
    }
  },
  "tmpfs": {
    "size": 2048000
  },
  "ports": {
    "80/tcp": 8581
  }
}
```

## Containers

## Patterns

## Nodes

# Design criteria

The expectations of this process is to automate the development, testing, and deployment processes for edge fabric patterns and their services across a large number of devices.  The key success criteria are:

1. __avoid failure in the field__ - a node that is currently operational should not fail due to an automated CI/CD process
2. __stage everything__ - all changes to deployed systems should be staged for testing prior to release
3. __enforce testing__ - all components should provide interfaces and cases for testing
4. __automate everything__ - to the greatest degree possible, automate the process

### Stage everything
The change control system for this repository is Git which provides mechanisms to stage changes between various versions of a repository.  These versions are distinguished within a repository via branching from a parent (e.g. the trunk or _main_ branch) and then incorporating any changes through a _commit_ back to the parent.  The _push_ of the change back to the repository may be used to evaluate the state and determine if a _stage_ is ready for a build to be initiated.  The relevant content to define a _stage_ should be an artifact in the build process from which state information may be extracted; storing relevant information in the `Makefile` defeats that objective.

Explicit changes to a version artifact with appropriate build automation is still TBD.  The service version is specified in the`service.json` configuration template.  That version is used to determine the Docker _tag_ as well as the Open Horizon _service_ tag.

### Enforce testing
Staged changes require testing processes to automate the build process.  Each service should conform to a standard test harness with either a default or custom test script.  Standardization of the testing process enables replication and re-use of tests for the service and its required services, simplifying testing.  Additional standardization in testing should be extended to API coverage through utilization of Swagger (n.b. IBM API Connect).

### Automate everything
Determination of build state in the TravisCI process requires utilization of platform controlled environment variables, typically reserved for _secrets_, or can leverage repository sources, e.g. JSON configurations.  While specification of environment variables through the build automation process would be possible, both the quantity and the variability in naming present challenges to automation and repeatability.



# Using the CI/CD process and tooling

1. Create _configuration_ JSON: `service.json` and `pattern.json` 
1. Create `service.makefile` - build, etc.. service using configuration JSON
1. Single `Dockerfile` - simplify build process
1. Create _build_ JSON: `build.json` - standardize architecture naming and Docker `FROM`
1. Create script `docker-run.sh` - standardize local execution (variables, environment, priviledged, ports)
1. Automate creation of `dev` environment (and elimination of `horizon/` artifact) 
1. Create script `mkdepend.sh`- automate post-processing of `dev` environment
1. Create template `userinput.json` - automate `dev` environment
1. Create script `checkvars.sh` - automate service variable processing
1. Create script `test.sh`- automatic, generic, test harness for any service
1. Create script `test-service.sh` - automatic, generic, test script for any service
1. `TAG` builds - optional environment variable or`TAG` file to distinguish build artifacts
1. Create script `fixpattern.sh` - automate pattern naming for publishing

### 1. Configuration JSON

The specification of version numbers and other dependencies for the build process were centralized into two JSON configuration files: `service.json` and `pattern.json`.  These files existed in the original, but were elevated to build artifacts and were templatized to handle issues of architecture and required services identification, notably the _tagging_ of the `url` and the `requiredServices[].url` in the `service.json` and `services[].servicesUrl` in the `pattern.json` (n.b. see _`mkdepend.sh`_).

### 2. `service.makefile`

A generic `Makefile` (n.b. shared via symbolic link) for any service using the CI/CD process; the build process provided is described in more detail in [`MAKE.md`][make-md].

### 3. & 4. Single Dockerfile _and_ `build.json`

Simplify development process through single Dockerfile using the JSON configuration in `build.json` to derive the `FROM` specification.  The `build.json` contains an array of **supported** architectures and the corresponding container **tag**, for example:

```
    "build_from": {
        "arm64": "arm64v8/alpine:3.8",
        "amd64": "alpine:3.8",
        "arm": "arm32v6/alpine:3.8"
    }
```

The standard `make` file utilizes this information to provide the `FROM` information required in the `Dockerfile`, specifying `--build-arg BUILD_FROM=<from>` command-line option to the `docker` command according to the `build.json`; a default value is best-practice, for example:

```
ARG BUILD_FROM=alpine:3.8
  
FROM $BUILD_FROM
```

### 5. `docker-run.sh`

A dynamic mechanism is required to automatically process the configuration JSON `service.json` to identify the environment variables expected and required.  In addition, dynamic mapping of ports from the container to the local host eliminated port conflicts; a benefit of extending the configuration to include a `ports` mapping section was standardization for all services on utilization of port `80` as the default.  This eliminated the need for a well-known port for each service as implemented originally.

### 6. Automate `horizon/` directory

The static artifact of the `horizon/` directory was specific to the cpu2msghub service, including files with embedded environment variables which required evaluation to create necessary components in the build.  Nothing in the `horizon/` directory could not be generated using the `hzn dev service new` command.

### 7. and 8. and 9. `mkdepend.sh`, `userinput.json`,`checkvars.sh`

The template artifacts of `service.json` and `userinput.json` are processed to provide proper architectures and variables for use with `hzn dev service start` command, including checking variables against transient files with matching names, e.g. `MSGHUB_APIKEY`.  This file-name mechanism enables automation of the build process as avoids disclosure of _secrets_ using TravisCI.

### 10. and 11. `test.sh` and `test-service.sh`

Automated test harness (`test.sh`) and automated, default, service test script (`test-service.sh`) for any service using this CI/CD process.  The default script is utilized to process the output of the service and provide a structural breakdown suitable for comparison with a known-good sample.

### 12. and 13. `TAG` and `fixpattern.sh`

To avoid utilization of the same pattern _name_ when building the software on varying branches in the repository, an additional `TAG` is introduced to append to all artifacts built in the repository.  The `fixpattern.sh` script appends the value, if and only if defined, to the pattern _name_ for both the `hzn exchange pattern publish` command and derived, transient, `horizon/pattern.json` file.

# MORE INFORMATION

Please refer to [`SERVICE.md`][service-md] for more information on building services.
Please refer to [`PATTERN.md`][pattern-md] for more information on building patterns.


[service-md]: https://github.com/dcmartin/open-horizon/blob/master/SERVICE.md
[pattern-md]: https://github.com/dcmartin/open-horizon/blob/master/PATTERN.md
[make-md]: https://github.com/dcmartin/open-horizon/blob/master/MAKE.md
[open-horizon-github]: http://github.com/open-horizon
[open-horizon-examples-github]: http://github.com/open-horizon/examples

