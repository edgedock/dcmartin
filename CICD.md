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

The CI/CD process is centered around these primary tools accessed **through the command-line**:

+ `make` - control, build, test automation
+ `git` - software version and branch management
+ `docker` - Docker registries, repositories, and images
+ `travis` - release change management
+ `hzn` - Open Horizon command-line-interface
+ `ssh` - Secure Shell 

The process is designed to account for multiple branches, registries, and exchanges being utilized as part of the build, test, and release management process; no release management process is proscribed nor provided.

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
+ `HZN_EXCHANGE_USERAUTH` - credentials user to exchange, e.g. `<org>/iamapikey:<apikey>`

For more information refer to [`MAKEVARS.md`][makevars-md]

[makevars-md]: https://github.com/dcmartin/open-horizon/blob/master/MAKEVARS.md

## Step 1 - Clone and configure

Clone this [repository][repository] into a new directory (n.b. it may also be [forked][forking-repository]):

[forking-repository]: https://github.community/t5/Support-Protips/The-difference-between-forking-and-cloning-a-repository/ba-p/1372

This repository is configured with the following default `make` variables which should be changed:

+ `DOCKER_NAMESPACE` - the identifier for the registry; for example, the _userid_ on [docker.io][docker-hub]
+ `HZN_ORG_ID` - organizational identifier in the Open Horizon exchange; for example: <userid>@cloud.ibm.com

[docker-hub]: http://hub.docker.com

Set those environment variables (and `GD` _Git_ working directory) appropriately:

```
export GD=
export DOCKER_NAMESPACE=
export HZN_ORG_ID=
```

Use the following instructions (n.b. [automation script][clone-config-script]) to clone and configure this repository:

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

## Step 5 - _Optional_ - IBM Container Registry
Refer to the [`REGISTRY.md`][registry-md] instructions for additional information on utilizing the IBM Cloud Container Registry.

[registry-md]: https://github.com/dcmartin/open-horizon/blob/master/REGISTRY.md

# 3.2 Sample Services
Services are organized into subdirectories of `open-horizon/` directory and all share a common design (n.b. see [`DESIGN.md`][design-md]).  For more information on _services_, see [`SERVICE.md`][service-md].

Some services are built as _base_ containers that are used as the Docker build `FROM` target.  The base containers include:

1. `base-alpine` - a base service container for Alpine LINUX
2. `base-ubuntu` - a base service container for Ubuntu LINUX

The containers built and pushed for these two services are utilized to build the remaining samples:

1. `cpu` - a cpu percentage monitor
2. `hal` - a hardware-abstraction-layer inventory
3. `wan` - a wide-area-network monitor
4. `yolo` - the `you-only-look-once` image entity detection and classification tool
5. `yolo2msghub` - uses 1-4 to send local state and entity detection information via Kafka

Each of the services may be built out-of-the-box (OOTB) using the `make` command.  Please refer to [`BUILD.md`][build-md] and [`MAKE.md`][make-md] for additional information.

# 3.3 Test Patterns
The `yolo2msghub` _service_ is also configured as a _pattern_ that can be deployed to test devices.  The pattern instantiates the `yolo2msgub` service and its four (4) `requiredServices`: {`cpu`,`hal`,`wan`, and `yolo`} on nodes which _register_ for the service.  Please refer to [`PATTERN.md`][pattern-md] for information on creating and deploying patterns.

[design-md]: https://github.com/dcmartin/open-horizon/blob/master/DESIGN.md
[service-md]: https://github.com/dcmartin/open-horizon/blob/master/SERVICE.md
[build-md]: https://github.com/dcmartin/open-horizon/blob/master/BUILD.md
[pattern-md]: https://github.com/dcmartin/open-horizon/blob/master/PATTERN.md
[make-md]: https://github.com/dcmartin/open-horizon/blob/master/MAKE.md
[open-horizon-github]: http://github.com/open-horizon
[open-horizon-examples-github]: http://github.com/open-horizon/examples

