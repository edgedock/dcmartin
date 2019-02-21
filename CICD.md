# CI/CD for Open Horizon

## Background

The need for development and deployment of services to the edge requires capabiltiies for **continuous integration** (CI) and **continuous delivery** (CD) of the software components.  In the case of Open Horizon, the packages delivered are one or more _containers_ which encapsulate a Docker run-time environment and provision a _service_.

### Patterns
A _pattern_ is a packaging of one or more _services_ into a named entity identified by the organization which published that pattern into the _exchange_ **and** a pattern _name_ unique to that organization.  For example, the pattern named `cpu2msghub`is in the `IBM` organization and hence its **unique** identfiier is `IBM/cpu2msghub`.   Patterns refer to services based on a organization (`ord`) and `url` -- as well as architecture (`arch`) and version (`version`).  For example:

```
{ "url": "com.github.open-horizon.examples.cpu", "org": "IBM", "version": "1.2.2", "arch": "amd64" }
```
Patterns are published to the exchange through the `hzn` command-line-interface (CLI) and may be either `public` to the exchange or `private` to the organization.

### Services
A _service_ is a packaging of one or more _container_ images with zero or more required services, including peer services and required services; composition of services via _virtual private network_ (VPN).  Each service is identified through `deployment.services` from `service.json`.  In the following -- extracted from `cpu2msghub/service.json`--  the _service_ is deployed with the identifier `cpu2msghub`. 

```
  "deployment": {
    "services": {
      "cpu2msghub": {
...
      }
    }
  }
```
Access to the service coud be performed using `curl`, e.g.

```
% curl -sSL http://yolo2msghub/
```

#### Required services

Required services are identified by `url` as well as its architecture and version; for example from the same `cpu2msghub/services.json`

```
 "requiredServices": [
        { "url": "com.github.open-horizon.examples.cpu", "org": "IBM", "version": "1.2.2", "arch": "amd64" },
        { "url": "github.com.open-horizon.examples.gps", "org": "IBM", "version": "2.0.5", "arch": "amd64" }
]
```

Services are published to the exchange through an intermediary container registry service, e.g. Docker Hub.  The container image in the registry is referenced by exchange when the service is published.

## Success criteria

The expectations of this process is to automate the development, testing, and deployment processes for edge fabric patterns and their services across a large number of devices.  The key success criteria are:

1. __avoid failure in the field__ - a node that is currently operational should not fail due to an automated CI/CD process
2. __stage everything__ - all changes to deployed systems should be staged for testing prior to release
3. __enforce testing__ - all components should provide interfaces and cases for testing
4. __automate everything__ - to the greatest degree possible, automate the process

## Existing examples

The Open Horizon [page on github.com][open-horizon-github] provides open-source code for components and examples.  There are two examples currently available for use during the alpha phase. These examples include:

+ Patterns
  + cpu2msghub - capture CPU and GPS data and to send Kafka 
  + sdr2msghub - capture audio from FM radio broadcasts and send to Kafka
+ Services
  + cpu - return CPU usage percentage (0.0-100.0]
  + gps - return GPS coordinates - statically defined, captured from device, or Internet IP derived
  + sdr - capture FM radio broadcasts
  + _network_ - **out-of-scope**
  + _pi3-streamer_ - **out-of-scope**
  + _weatherstation_ - **out-of-scope**

[edge-fabric-staging-docs]: https://github.ibm.com/Edge-Fabric/staging-docs

This CI/CD process was developed based on the existing example patterns and services; only functional patterns and services available in the `IBM` organization were utilized; other examples were not utilized.  The [documentation][edge-fabric-staging-docs] for these examples provided guidance and insight on the requirements for the build process; no documentation was available for any existing release process or build automation.

### Stage everything
The change control system for this repository is Git which provides mechanisms to stage changes between various versions of a repository.  These versions are distinguished within a repository via branching from a parent (e.g. the trunk or _main_ branch) and then incorporating any changes through a _commit_ back to the parent.  The _push_ of the change back to the repository may be used to evaluate the state and determine if a _stage_ is ready for a build to be initiated.  The relevant content to define a _stage_ should be an artifact in the build process from which state information may be extracted; storing relevant information in the `Makefile` defeats that objective.

Explicit changes to a version artifact with appropriate build automation is still TBD.  The service version is specified in the`service.json` configuration template.  That version is used to determine the Docker _tag_ as well as the Open Horizon _service_ tag.

### Enforce testing
Staged changes require testing processes to automate the build process.  Each service should conform to a standard test harness with either a default or custom test script.  Standardization of the testing process enables replication and re-use of tests for the service and its required services, simplifying testing.  Additional standardization in testing should be extended to API coverage through utilization of Swagger (n.b. IBM API Connect).

### Automate everything
Determination of build state in the TravisCI process requires utilization of platform controlled environment variables, typically reserved for _secrets_, or can leverage repository sources, e.g. JSON configurations.  While specification of environment variables through the build automation process would be possible, both the quantity and the variability in naming present challenges to automation and repeatability.

## `examples` Repository

The [`examples`][open-horizon-examples-github] repository provides a breakdown into three subdirectories:
  
  + `edge/` - source code for Edge services
  + `tools/` - Alpine LINUX package for `kafkacat`
  + `cloud/` - source code for Cloud services

The `tools/` and `cloud/` components are out-of-scope.  The `edge/` subdirectory contains subdirectories for documentation (`doc/`), as well as for the following:
  
  + `msghub` - source code for services utilizing Kafka; in subdirectories: `cpu2msghub/` and `sdr2msghub/`
  + `services` - source code for other services
  + `wiotp` - Watson IoT Platform (**out-of-scope**)

Of the two Kafka-based services, the `cpu2msghub` service is simpler and was selected as the prototype for subsequent build process and release management automation for continuous integration and continuous delivery.

## `edge/msghub/cpu2msghub`
 
 This subdirectory contains the source code and build files for the `cpu2msghub` _service_.   The `cpu2msghub` _service_ requires two additional services form the `IBM` organization, nominally _cpu_ and _gps_,  identified by their sets of  `org`,`url`,`arch`, and `version`.
 
 The build process includes one `Makefile` with targets for:
 
 + `build` - builds the container including copy of Kafka APK
 + `run` - runs the container (locally) using a static set of `docker run` options
 + `check` - checks the output of the locally run container
 + `stop` - stops the locally run container
 + `hznbuild` - fetches dependencies for _cpu_ and _gps_ from within repository to `dev` environment
 + `hznstart`- starts the service (and required services) in `dev` environment
 + `hznstop` - stops the service (and required services) in `dev` environment
 + `publish-service` - publishes the service into the exchange
 + `publish-pattern` - publishes the pattern into the exchange
 + `clean` - removes build artifacts
 
There is no TravisCI build automation.  Review of the build process identified several challenges to automation.  The targets depend on extensive use of environment variables. These variables are statically defined in the `Makefile`, including the pattern _name_ (i.e. `cpu2msghub`), its version (`CPU2MSGHUB_VERSION`), as well as the versions of its required services (`CPU_VERSION` and `GPS_VERSION`).

# Changes from Examples

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

