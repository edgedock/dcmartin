# `PATTERN.md` - publishing patterns

# 1. Introduction

Patterns are composed of services and depend on a successful service build.  All services for all architectures specified in the _pattern_ configuration file must be available in the designated exchange.

## Example single-service `pattern.json` template

The `pattern.json` template file for `yolo2msghub` (see below) contains human-readable attributes and a listing of services that are included.  In this example, there are three `services` in the array; one for each supported architecture.  Each service is identified by a the URL, organization, architecture, and acceptable versions.

```
{
  "label": "yolo2msghub",
  "description": "yolo and friends as a pattern",
  "public": true,
  "services": [
    {
      "serviceUrl": "com.github.dcmartin.open-horizon.yolo2msghub",
      "serviceOrgid": "dcmartin@us.ibm.com",
      "serviceArch": "amd64",
      "serviceVersions": [
        {
          "version": "0.0.11"
        }
      ]
    },
    {
      "serviceUrl": "com.github.dcmartin.open-horizon.yolo2msghub",
      "serviceOrgid": "dcmartin@us.ibm.com",
      "serviceArch": "arm",
      "serviceVersions": [
        {
          "version": "0.0.11"
        }
      ]
    },
    {
      "serviceUrl": "com.github.dcmartin.open-horizon.yolo2msghub",
      "serviceOrgid": "dcmartin@us.ibm.com",
      "serviceArch": "arm64",
      "serviceVersions": [
        {
          "version": "0.0.11"
        }
      ]
    }
  ]
}
```

# 2. Configuration

When using a single `DOCKER_NAMESPACE` and/or a single `HZN_EXCHANGE_URL` for multiple build stages, a special `TAG` file is recommended to maintain naming separation for containers, services, and patterns.

The `TAG` file may be used to indicate a branch, or stage, in the process;  for example from experimental (`exp`), to testing (`beta`), and finally to staging (`master`) prior to release management and production.

A Git branch can be identified using the `git branch` command; an asterisk (`*`) indicates the current branch; for example:

```
% git branch
* beta
  master
```

A `./open-horizon/TAG` file associated with the `beta` branch is created with the following command:

```
echo 'beta' > $GD/open-horizon/TAG
```




separation of Docker container images and Open Horizon exchange services and patterns when using a single `DOCKER_NAMESPACE` and 


# 3. Publish and validate
Patterns are published to an exchange using a completed configuration template.  When all services in a pattern have been published to the exchange, the pattern itself can be published.

### `pattern-publish`

Patterns are published using the `make` command in the corresponding subdirectory of the repository; for example:

```
cd ./open-horizon/yolo2msghub
make pattern-publish
```

Example output:

```
>>> MAKE -- 19:19:58 -- publishing: yolo2msghub; organization: dcmartin@us.ibm.com; exchange: https://alpha.edge-fabric.com/v1
Updating yolo2msghub in the exchange...
Storing dcmartin@us.ibm.com.pem with the pattern in the exchange...
```

### `pattern-validate`
Validates the pattern registration in the exchange using the `hzn` command-line-interface tool.


# 3. Deployment Testing

Client devices and virtual machines may be targeted for use as development nodes; refer to [`setup/README.md`][setup-readme-md] for additional information.  Devices are controlled using the `ssh` command via both the `Makefile` as well as through the `nodereg.sh` script; this script processes devices through stages until registered:

[setup-readme-md]: https://github.com/dcmartin/open-horizon/blob/master/setup/README.md

+ `null` - installs Open Horizon on the device
+ `unconfigured` - registers the node for the current pattern
+ `configuring` - purges the device of Open Horizon
+ `configured` - unregisters node iff pattern `url` does not match current

See `make nodes` below for additional information.

## A. Identify development nodes

Once devices have been configured for use a development nodes a listing of node names should be created in the file `TEST_TMP_MACHINES`; this file is _ignored_ by Git; for example:

```
test-amd64-1.local
test-arm-1.local
test-arm64-1.local
```

## 3.1 `make` targets

+ `nodes`
+ `nodes-list`
+ `nodes-test`
+ `nodes-undo`
+ `nodes-clean`
+ `nodes-purge`

### 3.1.1 `make nodes`
This target registers the development nodes listed in the `TEST_TMP_MACHINES` file with the current working directory pattern (e.g. `motion2mqtt/` directory with `pattern.json` file).  This target can be run repeatedly to assess registration status.  For example, in the following output only `test-cpu-6` was registered with the pattern; all other nodes were already registered.

```
make nodes
Created horizon metadata files in /Volumes/dcmartin/GIT/beta/open-horizon/motion2mqtt/horizon. Edit these files to define and configure your new service.
>>> MAKE -- 16:12:51 -- registering nodes: test-amd64-1 nano-1 test-cpu-2 test-cpu-3 test-cpu-6 test-sdr-1 test-sdr-4 tx2
>>> MAKE -- 16:12:52 -- registering test-amd64-1 
+++ WARN -- ./nodereg.sh 30580 -- missing service organization; using dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 30580 -- test-amd64-1 at IP: 192.168.1.187
--- INFO -- ./nodereg.sh 30580 -- test-amd64-1 -- configured with dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 30580 -- test-amd64-1 -- version: 0.0.13; url: com.github.dcmartin.open-horizon.motion2mqtt-beta
>>> MAKE -- 16:13:01 -- registering nano-1 
+++ WARN -- ./nodereg.sh 30631 -- missing service organization; using dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 30631 -- nano-1 at IP: 192.168.1.206
--- INFO -- ./nodereg.sh 30631 -- nano-1 -- configured with dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 30631 -- nano-1 -- version: 0.0.13; url: com.github.dcmartin.open-horizon.motion2mqtt-beta
>>> MAKE -- 16:13:08 -- registering test-cpu-2 
+++ WARN -- ./nodereg.sh 30682 -- missing service organization; using dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 30682 -- test-cpu-2 at IP: 192.168.1.180
--- INFO -- ./nodereg.sh 30682 -- test-cpu-2 -- configured with dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 30682 -- test-cpu-2 -- version: 0.0.13; url: com.github.dcmartin.open-horizon.motion2mqtt-beta
>>> MAKE -- 16:13:17 -- registering test-cpu-3 
+++ WARN -- ./nodereg.sh 30733 -- missing service organization; using dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 30733 -- test-cpu-3 at IP: 192.168.1.167
--- INFO -- ./nodereg.sh 30733 -- test-cpu-3 -- configured with dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 30733 -- test-cpu-3 -- version: 0.0.13; url: com.github.dcmartin.open-horizon.motion2mqtt-beta
>>> MAKE -- 16:13:24 -- registering test-cpu-6 
+++ WARN -- ./nodereg.sh 30786 -- missing service organization; using dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 30786 -- test-cpu-6 at IP: 192.168.1.220
--- INFO -- ./nodereg.sh 30786 -- registering test-cpu-6 with pattern: dcmartin@us.ibm.com/motion2mqtt-beta; input: horizon/userinput.json
--- INFO -- ./nodereg.sh 30786 -- machine: test-cpu-6; state: Reading input file /tmp/input.json...
Horizon Exchange base URL: https://alpha.edge-fabric.com/v1
Node dcmartin@us.ibm.com/test-cpu-6 exists in the exchange
Initializing the Horizon node...
Setting service variables...
Changing Horizon state to configured to register this node with Horizon...
Horizon node is registered. Workload agreement negotiation should begin shortly. Run 'hzn agreement list' to view.
configured
--- INFO -- ./nodereg.sh 30786 -- test-cpu-6 -- configured with dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 30786 -- test-cpu-6 -- version: 0.0.13; url: com.github.dcmartin.open-horizon.motion2mqtt-beta
>>> MAKE -- 16:13:52 -- registering test-sdr-1 
+++ WARN -- ./nodereg.sh 30870 -- missing service organization; using dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 30870 -- test-sdr-1 at IP: 192.168.1.219
--- INFO -- ./nodereg.sh 30870 -- test-sdr-1 -- configured with dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 30870 -- test-sdr-1 -- version: 0.0.13; url: com.github.dcmartin.open-horizon.motion2mqtt-beta
>>> MAKE -- 16:14:01 -- registering test-sdr-4 
+++ WARN -- ./nodereg.sh 30921 -- missing service organization; using dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 30921 -- test-sdr-4 at IP: 192.168.1.47
--- INFO -- ./nodereg.sh 30921 -- test-sdr-4 -- configured with dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 30921 -- test-sdr-4 -- version: 0.0.13; url: com.github.dcmartin.open-horizon.motion2mqtt-beta
>>> MAKE -- 16:14:11 -- registering tx2 
+++ WARN -- ./nodereg.sh 30974 -- missing service organization; using dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 30974 -- tx2 at IP: 192.168.1.31
--- INFO -- ./nodereg.sh 30974 -- tx2 -- configured with dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 30974 -- tx2 -- version: 0.0.13; url: com.github.dcmartin.open-horizon.motion2mqtt-beta
```

### 3.1.2 `make nodes-list`

After registration and initiation of Docker containers for services; for example node `tx2`:

```
>>> MAKE -- 16:15:24 -- listing tx2
{"node":"tx2"}
{"agreements":[{"url":"com.github.dcmartin.open-horizon.mqtt2kafka-beta","org":"dcmartin@us.ibm.com","version":"0.0.1","arch":"arm64"},{"url":"com.github.dcmartin.open-horizon.motion2mqtt-beta","org":"dcmartin@us.ibm.com","version":"0.0.13","arch":"arm64"}]}
{"services":["com.github.dcmartin.open-horizon.wan-beta","com.github.dcmartin.open-horizon.yolo4motion-beta","com.github.dcmartin.open-horizon.cpu-beta","com.github.dcmartin.open-horizon.hal-beta","com.github.dcmartin.open-horizon.motion2mqtt-beta","com.github.dcmartin.open-horizon.mqtt-beta","com.github.dcmartin.open-horizon.mqtt2kafka-beta"]}
{"container":"3e64661fb5a83040932d7dfa3c549d83d6e38c839e6b7cb2c1b16516da052742-motion2mqtt"}
{"container":"dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.yolo4motion-beta_0.0.4_c5ae5ff6-1f5f-4651-976b-3c099a2c19b7-yolo4motion"}
{"container":"dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.hal-beta_0.0.3_c6ee8878-face-4100-8386-d047bd710787-hal"}
{"container":"dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.cpu-beta_0.0.3_fb8eb358-ee21-443d-8257-3a07f3b448e6-cpu"}
{"container":"31840f4d6b962138a127ea7f1992c75072356697b71bbbd8f33f3933da02d479-mqtt2kafka"}
{"container":"dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.wan-beta_0.0.3_f6bdb821-6dfe-43ed-a067-cb0b17720468-wan"}
{"container":"dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.mqtt-beta_0.0.3_1fc832a7-e78a-4670-957f-9354da01b75c-mqtt"}
```

### 3.1.3 `make nodes-test`

Nodes configured with the pattern will respond to inquiries on their status port, e.g. the `motion2mqtt` service exposes port `8082` for its status.  Executing this target in the `motion2mqtt` directory will interrogate that port, for example:

```
>>> MAKE -- 16:17:50 -- testing: motion2mqtt-beta; node: tx2; port: 8082:8082; date: Wed Mar 27 16:17:50 PDT 2019
ELAPSED: 4
{"date":1553728375}
{"config":{"log_level":"info","debug":true,"group":"newman","device":"tx2","timezone":"/usr/share/zoneinfo/America/Los_Angeles","services":[{"name":"yolo4motion","url":"http://yolo4motion"},{"name":"cpu","url":"http://cpu"},{"name":"mqtt","url":"http://mqtt"},{"name":"hal","url":"http://hal"}],"mqtt":{"host":"mqtt","port":1883,"username":"","password":""},"motion":{"post_pictures":"center","locate_mode":"off","event_gap":30,"framerate":2,"threshold":5000,"threshold_tune":false,"noise_level":32,"noise_tune":true,"log_level":6,"log_type":"all"}}}
{"hzn":"dcmartin@us.ibm.com/motion2mqtt-beta"}
{"label":"motion2mqtt"}
{"version":"0.0.13.13"}
{"service":true}
{"mqtt":true}
{"hal":true}
{"hal":{"lsdf":[{"mount":"/dev/root","spacetotal":"28G","spaceavail":"20G"},{"mount":"/dev/sda","spacetotal":"110G","spaceavail":"86G"}]}}
{"hal":{"lshw":{"product":"quill"}}}
{"yolo4motion":false}
{"cpu":true}
{"cpu":39.66}
{"motion":{"event":false}}
{"motion":{"image":false}}
{"yolo":{"image":false}}
{"yolo":{"mock":null}}
{"yolo":{"detected":null}}
```

This output is created using the following filter for the `jq` command (see `TEST_NODE_FILTER` file); this file may contain multiple lines with comments denoted by a `#` as the first character.  Only the first non-commented line is utilized; others may be alternatives.

```
.test.date=.date, .test.config=.config, .test.hzn=.hzn.pattern.key, .test.label=.service.label, .test.version=.service.version,.test.service=.motion2mqtt?!=null, .test.mqtt=.mqtt?!=null, .test.hal=.hal?!=null, .test.hal.lsdf=.hal.lsdf, .test.hal.lshw.product=.hal.lshw.product, .test.yolo4motion=.yolo4motion?!=null, .test.cpu=.cpu?!=null, .test.cpu=.cpu.percent, .test.motion.event=.motion2mqtt.motion.event.base64?!=null, .test.motion.image=.motion2mqtt.motion.image.base64?!=null, .test.yolo.image=(.yolo4motion.image?!=null), .test.yolo.mock=(.yolo4motion.mock), .test.yolo.detected=(.yolo4motion.detected)
```

### 3.1.4 `make nodes-undo`

```
>>> MAKE -- 11:12:35 -- unregistering nodes: test-sdr-1.local test-sdr-4.local test-cpu-3.local test-cpu-6.local test-cpu-2.local
>>> MAKE -- 11:12:35 -- unregistering test-sdr-1.local Sun Mar 10 11:12:35 PDT 2019
Unregistering this node, cancelling all agreements, stopping all workloads, and restarting Horizon...
Horizon node unregistered. You may now run 'hzn register ...' again, if desired.
>>> MAKE -- 11:13:07 -- unregistering test-sdr-4.local Sun Mar 10 11:13:07 PDT 2019
Unregistering this node, cancelling all agreements, stopping all workloads, and restarting Horizon...
Horizon node unregistered. You may now run 'hzn register ...' again, if desired.
>>> MAKE -- 11:13:38 -- unregistering test-cpu-3.local Sun Mar 10 11:13:38 PDT 2019
Unregistering this node, cancelling all agreements, stopping all workloads, and restarting Horizon...
Horizon node unregistered. You may now run 'hzn register ...' again, if desired.
>>> MAKE -- 11:14:26 -- unregistering test-cpu-6.local Sun Mar 10 11:14:26 PDT 2019
Unregistering this node, cancelling all agreements, stopping all workloads, and restarting Horizon...
Horizon node unregistered. You may now run 'hzn register ...' again, if desired.
>>> MAKE -- 11:15:27 -- unregistering test-cpu-2.local Sun Mar 10 11:15:27 PDT 2019
Unregistering this node, cancelling all agreements, stopping all workloads, and restarting Horizon...
Horizon node unregistered. You may now run 'hzn register ...' again, if desired.
```

### 3.1.5 `make nodes-clean`

Performs both a `nodes-undo` as well as removes all running docker images and prunes all containers from the nodes.

### 3.1.6 `make nodes-purge`

Performs `nodes-clean` and then purges `bluehorizon`, `horizon`, and `horizon-cli` packages from node.
