# `CICD.md` - CI/CD for Open Horizon
This document provides an introduction to the process and tooling utilized in this [repository][repository] to achieve continuous integration and delivery of [Open Horizon][open-horizon] services and patterns to the edge.

[repository]:  https://github.com/dcmartin/open-horizon

[open-horizon]: http://github.com/open-horizon



# 0. Background
It is presumed that the reader is a software engineer with familiarity with the following:

+ **LINUX** - The free, open-source, UNIX-like, operating system, e.g. [Ubuntu][get-ubuntu] or [Raspbian][get-raspbian]
+ **HTTP** - The HyperText Transfer Protocol and tooling; see [here][curl-intro] and [here][socat-intro]
+ **Git** - Software management -AAS; see [here][git-basics]
+ **JSON** - JavaScript Object Notation and tooling; see [here][json-intro-jq]
+ **Make** - and other standard LINUX build tools; see [here][gnu-make]

[get-ubuntu]: https://www.ubuntu.com/download
[get-raspbian]: https://www.raspberrypi.org/downloads/raspbian/
[gnu-make]: https://www.gnu.org/software/make/
[socat-intro]: https://medium.com/@copyconstruct/socat-29453e9fc8a6
[git-basics]: https://gist.github.com/blackfalcon/8428401
[json-intro-jq]: https://medium.com/cameron-nokes/working-with-json-in-bash-using-jq-13d76d307c4
[curl-intro]: https://www.maketecheasier.com/introduction-curl/

Please refer to [`TERMINOLOGY.md`][terminology-md] for important terms and definitions.

[terminology-md]: https://github.com/dcmartin/open-horizon/blob/master/TERMINOLOGY.md

# 1. Introduction
Open Horizon edge fabric provides method and apparatus to run multiple Docker containers on edge nodes.  These nodes are LINUX devices running the Docker virtualization engine, the Open Horizon edge fabric client, and registered with an Open Horizon exchange.

The edge fabric enables multiple containers, networks, and physical sensors to stitched into a pattern designed to meet a need.  The only limitation of the fabric are the devices' capabilities; for example one device may have a camera attached and another may have a GPU.

The CI/CD process demonstrated in this repository enables the automated building, testing, pushing, publishing, and deploying edge fabric services to devices for the purposes of development and testing.  Release management and production deployment are out-of-scope.

# 2. Design

The expectations of this process is to automate the development, testing, and deployment processes for edge fabric patterns and their services across a large number of devices.  The primary objective is to:

+ __eliminate failure in the field__

A node that is currently operational should not fail due to an automated CI/CD process result.

The key success criteria are:
 
2. __stage everything__ - all changes to deployed systems should be staged for testing prior to release
3. __enforce testing__ - all components should provide interfaces and cases for testing
4. __automate anything__ - to the greatest degree possible, automate the process

### Stage everything
The change control system for this repository is Git which provides mechanisms to stage changes between various versions of a repository.  These versions are distinguished within a repository via branching from a parent (e.g. the trunk or _master_ branch) and then incorporating any changes through a _commit_ back to the parent.  The _push_ of the change back to the repository may be used to evaluate the state and determine if a _stage_ is ready for a build to be initiated.  

### Enforce testing
Staged changes require testing processes to automate the build process.  Each service should conform to a standard test harness with either a default or custom test script.  Standardization of the testing process enables replication and re-use of tests for the service and its required services, simplifying testing.  Additional standardization in testing should be extended to API coverage through utilization of Swagger (n.b. IBM API Connect).

### Automate anything
A combination of tools enables automation for almost every component in the CI/CD process.  However, certain activities remain the provenance of human review and oversite, including _pull requests_ and _release management_.  In addition, modification of a service _version_ is _not_ dependent on either the Git or Docker repository version information.

# 3.Use

This [repository][repository] is built as an example implementation of this CI/CD process.  Each of the services is built using a similar [design][design-md] that utilizes a common set of `make` files and support scripts.

The CI/CD process is centered around these primary tools accessed through the command-line:

+ `make` - control, build, test automation
+ `git` - software version and branch management
+ `docker` - Docker registries, repositories, and images
+ `travis` - release change management
+ `hzn` - Open Horizon command-line-interface
+ `ssh` - Secure Shell 

The process is designed to account for multiple branches, registries, and exchanges being utilized as part of the build, test, and release management process; no release management process is proscribed.

The CI/CD process requires configuration to operate properly; the control attributes are listed below; they may be specified as environment variables, files, or automatically extracted from relevant JSON configuration files, e.g. `~/.docker/config.json`, `registry.json` and `apiKey.json` for the Docker configuration, registry, and IBM Cloud, respectively.

+ `DOCKER_NAMESPACE` - identifies the collection of repositories, e.g. `dcmartin`
+ `DOCKER_REGISTRY` - identifies the SaaS server, e.g. `docker.io`
+ `DOCKER_LOGIN` - account identifier for access to registry
+ `DOCKER_PASSWORD` - password to verify account in registry
+ `HZN_ORG_ID` - organizational identifier for Open Horizon edge fabric exchange
+ `HZN_EXCHANGE_URL` - identifies the SaaS server, e.g. `alpha.edge-fabric.com`
+ `HZN_EXCHANGE_USERAUTH` - credentials user to exchange, e.g. `<org>/iamapikey:<apikey>`

For more information refer to [`MAKEVARS.md`][makevars-md]

[makevars-md]: https://github.com/dcmartin/open-horizon/blob/master/MAKEVARS.md

## Step 1 - Clone and configure

Clone this [repository][repository] into a new directory (n.b. the repository may also be [forked][forking-repository]):

[forking-repository]: https://github.community/t5/Support-Protips/The-difference-between-forking-and-cloning-a-repository/ba-p/1372

This repository is configured with the following default `make` variables which should be changed:

+ `DOCKER_NAMESPACE` - the identifier for the registry; for example, the _userid_ on [docker.io][docker-hub]
+ `HZN_ORG_ID` - organizational identifier in the Open Horizon exchange; for example: <userid>@cloud.ibm.com

[docker-hub]: http://hub.docker.com

Set those environment variables (and `GIT` directory) appropriately:

```
export GD=
export DOCKER_NAMESPACE=
export HZN_ORG_ID=
```

Use the following instructions (n.b. [source][clone-config-script]) to clone and configure this repository; **password for Docker may be requested**)

```
mkdir -p $GD
cd $GD
git clone http://github.com/dcmartin/open-horizon
cd $GD/open-horizon
for j in */service.json; do jq '.org="'${HZN_ORG_ID}'"' $j > $j.$$ && mv $j.$$ $j; done
for j in */pattern.json; do jq '.services[].serviceOrgid="'${HZN_ORG_ID}'"' $j > $j.$$ && mv $j.$$ $j; done
for j in */build.json; do sed -i -e 's|dcmartin/|'"${DOCKER_NAMESPACE}"'/|g' "${j}"; done
```

## Step 2 - Install Open Horizon
With the assumption that `docker` has already been installed; if not refer to these [instructions][get-docker].

[get-docker]: https://docs.docker.com/install/

+ **macOS**

 ```
cd $GD/open-horizon
sudo bash ./update-hzncli-macos.sh
```
**Note**: only the `hzn` command-line-interface tool is installed for macOS

+ **LINUX**

 ```
cd $GD/open-horizon
sudo bash ./setup/aptget-horizon.sh
```

## Step 3 - Create IBM Cloud API key file
Visit the IBM Cloud [IAM][iam-service] service to create and download a platform API key; copy that `apiKey.json` file into the `open-horizon/` directory:

[iam-service]: https://cloud.ibm.com/iam

```
cp -f ~/apiKey.json $GD/open-horizon/apiKey.json 
```

## Step 4 - Create code-signing key files
Create a private-public key pair for encryption and digital signature:

```
cd $GD/open-horizon/
rm -f *.key *.pem
hzn key create ${HZN_ORG_ID} $(whoami)@$(hostname)
mv -f *.key ${HZN_ORG_ID}.key
mv -f *.pem ${HZN_ORG_ID}.pem
```

[clone-config-script]: https://github.com/dcmartin/open-horizon/blob/master/scripts/clone-config.txt

The resulting `open-horizon/` directory contains all the necessary components to build a set of service, a deployable pattern, and a set of nodes for testing.

# 3.2 Building sample services

## Step 1 - 
## Step 5

[design-md]: https://github.com/dcmartin/open-horizon/blob/master/DESIGN.md


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

