# `CICD.md` - CI/CD for Open Horizon
This document provides an introduction to the process and tooling utilized in this [repository][repository] to achieve continuous integration and delivery of [Open Horizon][open-horizon] services and patterns to the edge.  The CI/CD process demonstrated in this repository enables the automated building, testing, pushing, publishing, and deploying edge fabric services to devices for the purposes of development and testing.  Release management and production deployment are out-of-scope.

Open Horizon edge fabric provides method and apparatus to run multiple Docker containers on edge nodes.  These nodes are LINUX devices running the Docker virtualization engine, the Open Horizon edge fabric client, and registered with an Open Horizon exchange.  The edge fabric enables multiple containers, networks, and physical sensors to be woven into a pattern designed to meet a given need with a set of capabilities.  The only limitation of the fabric are the edge devices' capabilities; for example one device may have a camera attached and another may have a GPU.

[repository]:  https://github.com/dcmartin/open-horizon
[open-horizon]: http://github.com/open-horizon

<hr>

#  &#10071; Intended Audience
It is presumed that the reader is a software engineer with familiarity with the following:

+ **LINUX** - The free, open-source, UNIX-like, operating system, e.g. [Ubuntu][get-ubuntu] or [Raspbian][get-raspbian]
+ **HTTP** - The HyperText Transfer Protocol and tooling; see [here][curl-intro] and [here][socat-intro]
+ **Git** - Software management -AAS
+ **JSON** - JavaScript Object Notation and tooling; see [here][json-intro-jq]
+ **Make** - and other standard LINUX build tools; see [here][gnu-make]

Please refer to [`TERMINOLOGY.md`][terminology-md] for important terms and definitions.

# &#9989; What Will Be Learned

The software engineer will learn how to perform the following:

+ Use this repository
 1. Copy, configure, and use a Git repository
 2. Configure for Docker and Open Horizon
+ Build and test services and patterns
 3. Build, test, and publish  _service_
 4. Publish and test _pattern_
+ Change management practices
 5. Setup a development _branch_
 7. Update a _service_
 8. Update a _pattern_
 6. Submit a _pull request_
+ Automate build process
 9. Setup, configure, and use  Travis CI
+ Decorate
 10. Setup Docker container _badging_

 
Within the following scenario:

+ A single developer
+ One (1) Docker registry with one (1) namespace
+ One (1) Open Horizon exchange with one (1) organization
+ Public github.com, docker.io, travis-ci.org, and [microbadger.com][microbadger]
+ One (1) repository with two (2) branches: "dev" (`beta`) and “stable” (`master`)

[get-ubuntu]: https://www.ubuntu.com/download
[get-raspbian]: https://www.raspberrypi.org/downloads/raspbian/
[gnu-make]: https://www.gnu.org/software/make/
[socat-intro]: https://medium.com/@copyconstruct/socat-29453e9fc8a6
[git-basics]: https://gist.github.com/blackfalcon/8428401
[json-intro-jq]: https://medium.com/cameron-nokes/working-with-json-in-bash-using-jq-13d76d307c4
[curl-intro]: https://www.maketecheasier.com/introduction-curl/
[terminology-md]: https://github.com/dcmartin/open-horizon/blob/master/doc/TERMINOLOGY.md
[microbadger]: https://microbadger.com/
[git-pull-request]: https://help.github.com/en/articles/creating-a-pull-request

<hr>
## A. Introduction

The expectations of this process is to automate the development, testing, and deployment processes for edge fabric patterns and their services across a large number of devices.  The primary objective is to:

+ __eliminate failure in the field__

A node that is currently operational should not fail due to an automated CI/CD process result.

The key success criteria are:
 
1. __stage everything__ - all changes to deployed systems should be staged for testing prior to release
1. __enforce testing__ - all components should provide interfaces and cases for testing
1. __automate everything__ - to the greatest degree possible, automate the process

### Stage everything
The change control system for this repository is Git which provides mechanisms to stage changes between various versions of a repository.  These versions are distinguished within a repository via branching from a parent (e.g. the trunk or _master_ branch) and then incorporating any changes through a _commit_ back to the parent.  The _push_ of the change back to the repository may be used to evaluate the state and determine if a _stage_ is ready for a build to be initiated.  

### Enforce testing
Staged changes require testing processes to automate the build process.  Each service should conform to a standard test harness with either a default or custom test script.  Standardization of the testing process enables replication and re-use of tests for the service and its required services, simplifying testing.  Additional standardization in testing should be extended to API coverage through utilization of Swagger (n.b. IBM API Connect).

### Automate everything
A combination of tools enables automation for almost every component in the CI/CD process.  However, certain activities remain the provenance of human review and oversite, including _pull requests_ and _release management_.  In addition, modification of a service _version_ is _not_ dependent on either the Git or Docker repository version information.

## B. Design
The process is designed to account for multiple branches, registries, and exchanges being utilized as part of the build, test, and release management process.  This [repository][repository] is built as an example implementation of this CI/CD process.  Each of the services is built using a similar [design][design-md] that utilizes a common set of `make` files and support scripts.

The CI/CD process is centered around these primary tools accessed **through the command-line**:

+ `make` - control, build, test automation
+ `git` - software version and branch management
+ `docker` - Docker registries, repositories, and images
+ `travis` - release change management
+ `hzn` - Open Horizon command-line-interface
+ `ssh` - Secure Shell 

The CI/CD process requires configuration to operate properly; **relevant JSON configuration files**:

1. `~/.docker/config.json` - Docker configuration, including registries and authentication
2. `registry.json` - IBM Cloud Container Registry configuration (see [`REGISTRY.md`][registry-md])
3. `apiKey.json` - IBM Cloud platform API key

These files are utilized for the control attributes; they may also be specified as environment variables or files in the `open-horizon/` directory; **the control attributes are**: 

+ `DOCKER_NAMESPACE` - identifies the collection of repositories, e.g. `dcmartin`
+ `DOCKER_REGISTRY` - identifies the SaaS server, e.g. `docker.io`
+ `DOCKER_LOGIN` - account identifier for access to registry
+ `DOCKER_PASSWORD` - password to verify account in registry
+ `HZN_ORG_ID` - organizational identifier for Open Horizon edge fabric exchange
+ `HZN_EXCHANGE_URL` - identifies the SaaS server, e.g. `alpha.edge-fabric.com`
+ `HZN_EXCHANGE_APIKEY` - API key for exchange server, a.k.a. IBM Cloud Platform API key

For more information refer to [`MAKEVARS.md`][makevars-md]

[makevars-md]: https://github.com/dcmartin/open-horizon/blob/master/doc/MAKEVARS.md

<hr>
# 1. Use

## Step 0 - Install Open Horizon
With the assumption that `docker` has already been installed; if not refer to these [instructions][get-docker].

[get-docker]: https://docs.docker.com/install/

```
cd $GD/open-horizon
wget -qO - ibm.biz/get-horizon | sudo bash
```
**Note**: only the `hzn` command-line-interface tool is installed for macOS



## Step 1 - Clone and configure 

Clone this [repository][repository] into a new directory (n.b. it may also be [forked][forking-repository]):

[forking-repository]: https://github.community/t5/Support-Protips/The-difference-between-forking-and-cloning-a-repository/ba-p/1372

This repository has the following default build variables which should be changed:

+ `DOCKER_NAMESPACE` - the identifier for the registry; for example, the _userid_ on [hub.docker.com][docker-hub]
+ `HZN_ORG_ID` - organizational identifier in the Open Horizon exchange; for example: `<userid>@cloud.ibm.com`

[docker-hub]: http://hub.docker.com

Set those environment variables (and `GD` for the _Git_ working directory) appropriately:

```
export GD=~/gitdir
export DOCKER_NAMESPACE=
export HZN_ORG_ID=
```

Use the following instructions (n.b. [automation script][clone-config-script]) to clone and configure this repository:

```
mkdir -p $GD
cd $GD
git clone http://github.com/dcmartin/open-horizon
cd open-horizon
echo "${DOCKER_NAMESPACE}" > DOCKER_NAMESPACE
echo "${HZN_ORG_ID}" > HZN_ORG_ID
```

Creating the `DOCKER_NAMESPACE` and `HZN_ORG_ID` files will ensure persistence of build configuration.

**NOTE**: If using [IBM Container Registry][registry-md] and the `./open-horizon/registry.json` file exists, the Docker registry configuration therein will be utilized.


## Step 3 - Create IBM Cloud API key file
Visit the IBM Cloud [IAM][iam-service] service to create and download a platform API key; copy the downloaded `apiKey.json` file into the `open-horizon/` directory; for example:

[iam-service]: https://cloud.ibm.com/iam

```
cp -f ~/Downloads/apiKey.json $GD/open-horizon/apiKey.json 
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

## &#10004; Finished
The resulting `open-horizon/` directory contains all the necessary components to build a set of service, a deployable pattern, and a set of nodes for testing.

## &#10033; Optional: _alternative registry_
Refer to the [`REGISTRY.md`][registry-md] instructions for additional information on utilizing the IBM Cloud Container Registry.

[registry-md]: https://github.com/dcmartin/open-horizon/blob/master/doc/REGISTRY.md

# 2. Build
Services are organized into subdirectories of `open-horizon/` directory and all share a common [design][design-md]. Please refer to [`BUILD.md`][build-md] for details on the build process. 

Two base service containers are provided; one for Alpine with its minimal footprint, and one for Ubuntu with its support for a wide range of software packages.

1. [`base-alpine`][base-alpine] - a base service container for Alpine LINUX
2. [`base-ubuntu`][base-ubuntu] - a base service container for Ubuntu LINUX

[yolo-service]: https://github.com/dcmartin/open-horizon/tree/master/yolo/README.md
[hal-service]: https://github.com/dcmartin/open-horizon/tree/master/hal/README.md
[cpu-service]: https://github.com/dcmartin/open-horizon/tree/master/cpu/README.md
[wan-service]: https://github.com/dcmartin/open-horizon/tree/master/wan/README.md
[base-alpine]: https://github.com/dcmartin/open-horizon/tree/master/base-alpine/README.md
[base-ubuntu]: https://github.com/dcmartin/open-horizon/tree/master/base-ubuntu/README.md
[hzncli]: https://github.com/dcmartin/open-horizon/tree/master/hzncli/README.md
[herald-service]: https://github.com/dcmartin/open-horizon/tree/master/herald/README.md
[mqtt-service]: https://github.com/dcmartin/open-horizon/tree/master/mqtt/README.md
[yolo2msghub-service]: https://github.com/dcmartin/open-horizon/tree/master/yolo2msghub/README.md
[yolo4motion-service]: https://github.com/dcmartin/open-horizon/tree/master/yolo4motion/README.md
[motion2mqtt-service]: https://github.com/dcmartin/open-horizon/tree/master/motion2mqtt/README.md
[mqtt2kafka-service]: https://github.com/dcmartin/open-horizon/tree/master/mqtt2kafka/README.md
[jetson-caffe-service]: https://github.com/dcmartin/open-horizon/tree/master/jetson-caffe/README.md
[jetson-yolo-service]: https://github.com/dcmartin/open-horizon/tree/master/jetson-yolo/README.md
[jetson-digits]: https://github.com/dcmartin/open-horizon/tree/master/jetson-digits/README.md
[jetson-jetpack]: https://github.com/dcmartin/open-horizon/tree/master/jetson-jetpack/README.md
[jetson-cuda]: https://github.com/dcmartin/open-horizon/tree/master/jetson-cuda/README.md
[jetson-opencv]: https://github.com/dcmartin/open-horizon/tree/master/jetson-opencv/README.md

The `cpu`,`hal`,`wan`, and `mqtt` services are Alpine-based and of minimal size.
The `yolo` and `yolo2msghub` services are Ubuntu-based to support YOLO/Darknet and Kafka, respectively.

## Examples

The containers built and pushed for these two services are utilized to build the remaining samples:

1. [`cpu`][cpu-service] - a cpu percentage monitor
2. [`hal`][hal-service] - a hardware-abstraction-layer inventory
3. [`wan`][wan-service] - a wide-area-network monitor
4. [`yolo`][yolo-service] - the `you-only-look-once` image entity detection and classification tool
5. [`yolo2msghub`][yolo2msghub-service] - uses 1-4 to send local state and entity detection information via Kafka

Each of the services may be built out-of-the-box (OOTB) using the `make` command.  Please refer to [`MAKE.md`][make-md] for additional information.

## Step 1
After copy and configuration of repository, build and test all services.

**Change to the Git working directory:**

```
cd $GD/open-horizon
```

**Build services for supported architectures.**  The default [`make`][make-md] target is to `build`, `run`, and `check` the service's container using the development host's native architecture (e.g. `amd64`).   A single architecture may be built with `build-service` which reports `build` output (n.b. `build` is silent).

```
make service-build
```

**Test services for supported architectures.**  The services' containers status outputs are **tested using the `jq` command** and the first uncommented line from the `TEST_JQ_FILTER` file.  Some services require time to initialize; subsequent requests produce complete status.

```
make service-test
```

## Step 2
Services require their Docker container images to be _pushed_ to the Docker registry.  Once a Docker container has been built, it may be pushed to a registry.  Services typically support more than one architecture.  A single architecture may be pushed with `push-service` or simply `push`.

**Push containers for supported architectures.**

```
make service-push
```

## Step 3
To publish services in the exchange, run the following commands:

```
make service-publish
make serve-verify
```

## Step 4
To publish the `yolo2msghub` pattern, run the following commands:

```
make pattern-publish
make pattern-validate
```

## &#10004; Finished
All services and patterns have been published in the Open Horizon exchange and all associated Docker containers have been pushed to the designated registry.

For more information on building services, see [`SERVICE.md`][service-md].

# 3. Change
The build process is designed to process changes to the software and take actions, e.g. rebuilding a service container.  To manage change control this process utilizes the `git` command in conjunction with a SaaS (e.g. `github.com`).

<hr>
# &#9888; WARNING

The namespace and version identifiers for Git do not represent the namespaces, identifiers, or versions used by either Docker or Open Horizon.  **To avoid conflicts in identification of containers, services, and patterns multiple Docker registries & namespaces and Open Horizon exchanges & organizations should be utilized.**

### &#9995; Docker registry & namespace and Open Horizon exchange & organization

When using a single registry, namespace, exchange, and organization tt is necessary to distinguish between containers, services, and patterns.  The `TAG` value is used to modify the container, service, and pattern identifiers in the configuration templates and build files.  In addition, the `build.json` file values are also decorated with the `TAG` value when from the same Docker registry and namespace.

The value may be used to indicate a branch or stage;  for example development (`beta`) or staging (`master`). An`open-horizon/TAG` that distinguishes the `beta` branch would be created with the following command:

```
echo 'beta' > $GD/open-horizon/TAG
```
<hr>

## Step 1
The the most basic CI/CD process consists of the following activities (see [Git Basics][git-basics]):

1. Create branch (e.g. `beta`) of _parent_ (e.g. `master`)
1. Develop on `beta` branch
1. Merge `master` into `beta` and test
2. Commit `beta`
2. Merge `beta` into `master` and test
1. Commit `master`
2. Build, test, and deliver `master`

**Create branch.**  A branch requires a _name_ for identification; provide a string with no whitespace or special characters:

```
git branch beta
```

**Identify branch** A branch can be identified using the `git branch` command; an asterisk (`*`) indicates the current branch.
```
% git branch
  beta
* master
```

**Switch branch** Switch between branches using `git checkout` command:

```
% git checkout beta

Switched to branch 'beta'
Your branch is up to date with 'origin/master'.
% git branch
* beta
  master
```

## Step 2
**Change the service**.  Create a change in one of the repository's services and then build, test, and repeat until the change works as intended.

## Step 3
**Merge `master` branch into `beta`**.  Prior to merging a branch into a parent, any updates to the parent should be pulled into the branch and merge appropriately.  Build and test processes may then be applied either manually or automatically.

```
% git checkout beta
% git pull origin master
% make service-build && make service-test
```

## Step 4
Once a branch has been successfully tested (and approved if submitted through _pull request_), the branch may be merged with the parent.  For example, merging the `beta` branch back into `master`:

```
% git checkout master
% git pull origin master
% git merge beta
% make service-build && make service-test
```

[git-branch-merge]: https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging


# 6. Test
The `yolo2msghub` _service_ is also configured as a _pattern_ that can be deployed to test devices.  The pattern instantiates the `yolo2msgub` service and its four (4) `requiredServices`: {`cpu`,`hal`,`wan`, and `yolo`} on nodes which _register_ for the service.  Please refer to [`PATTERN.md`][pattern-md] for information on creating and deploying patterns.

[design-md]: https://github.com/dcmartin/open-horizon/blob/master/doc/DESIGN.md
[service-md]: https://github.com/dcmartin/open-horizon/blob/master/doc/SERVICE.md
[build-md]: https://github.com/dcmartin/open-horizon/blob/master/doc/BUILD.md
[pattern-md]: https://github.com/dcmartin/open-horizon/blob/master/doc/PATTERN.md
[make-md]: https://github.com/dcmartin/open-horizon/blob/master/doc/MAKE.md
[open-horizon-github]: http://github.com/open-horizon
[open-horizon-examples-github]: http://github.com/open-horizon/examples

