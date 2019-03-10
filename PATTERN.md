# `PATTERN.md` - publishing patterns

# 1. Build

Patterns are composed of services and have no build process.  However, all services specified in the `pattern.json` configuration file must be available in the exchange for all architectures specified in the configuration.  The configuration file:

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
          "version": "0.0.1"
        }
      ]
    },
    {
      "serviceUrl": "com.github.dcmartin.open-horizon.yolo2msghub",
      "serviceOrgid": "dcmartin@us.ibm.com",
      "serviceArch": "arm",
      "serviceVersions": [
        {
          "version": "0.0.1"
        }
      ]
    },
    {
      "serviceUrl": "com.github.dcmartin.open-horizon.yolo2msghub",
      "serviceOrgid": "dcmartin@us.ibm.com",
      "serviceArch": "arm64",
      "serviceVersions": [
        {
          "version": "0.0.1"
        }
      ]
    }
  ]
}
```

# 2. Publish

## `make` targets

### `pattern-publish`

### `pattern-validate`

# 3. Deploy


These targets act on clients specified by the `TEST_NODES_NAME` variable; its value may be specified in file `TEST_TMP_MACHINES`:

```
test-sdr-1.local
test-sdr-4.local
test-cpu-2.local
test-cpu-3.local
test-cpu-6.local
```

## 3.1 `make` targets

+ `nodes`
+ `list-nodes`
+ `test-nodes`
+ `undo-nodes`

### 3.1.1 `make nodes`

Before registration:

```
Created horizon metadata files in /Volumes/dcmartin/GIT/beta/open-horizon/motion2mqtt/horizon. Edit these files to define and configure your new service.
>>> MAKE -- 11:16:28 -- registering nodes: test-sdr-1.local test-sdr-4.local test-cpu-3.local test-cpu-6.local test-cpu-2.local
>>> MAKE -- 11:16:28 -- registering test-sdr-1.local Sun Mar 10 11:16:28 PDT 2019
--- INFO -- ./nodereg.sh 80400 -- test-sdr-1.local
--- INFO -- ./nodereg.sh 80400 -- registering test-sdr-1.local with pattern motion2mqtt-beta
>>> MAKE -- 11:16:49 -- registering test-sdr-4.local Sun Mar 10 11:16:49 PDT 2019
--- INFO -- ./nodereg.sh 80435 -- test-sdr-4.local
--- INFO -- ./nodereg.sh 80435 -- registering test-sdr-4.local with pattern motion2mqtt-beta
>>> MAKE -- 11:17:07 -- registering test-cpu-3.local Sun Mar 10 11:17:07 PDT 2019
--- INFO -- ./nodereg.sh 80468 -- test-cpu-3.local
--- INFO -- ./nodereg.sh 80468 -- registering test-cpu-3.local with pattern motion2mqtt-beta
>>> MAKE -- 11:17:26 -- registering test-cpu-6.local Sun Mar 10 11:17:26 PDT 2019
--- INFO -- ./nodereg.sh 80501 -- test-cpu-6.local
--- INFO -- ./nodereg.sh 80501 -- registering test-cpu-6.local with pattern motion2mqtt-beta
>>> MAKE -- 11:17:46 -- registering test-cpu-2.local Sun Mar 10 11:17:46 PDT 2019
--- INFO -- ./nodereg.sh 80535 -- test-cpu-2.local
--- INFO -- ./nodereg.sh 80535 -- registering test-cpu-2.local with pattern motion2mqtt-beta
```
After registration:

```
Created horizon metadata files in /Volumes/dcmartin/GIT/beta/open-horizon/motion2mqtt/horizon. Edit these files to define and configure your new service.
>>> MAKE -- 11:19:42 -- registering nodes: test-sdr-1.local test-sdr-4.local test-cpu-3.local test-cpu-6.local test-cpu-2.local
>>> MAKE -- 11:19:43 -- registering test-sdr-1.local Sun Mar 10 11:19:43 PDT 2019
--- INFO -- ./nodereg.sh 80769 -- test-sdr-1.local
--- INFO -- ./nodereg.sh 80769 -- test-sdr-1.local -- configured with dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 80769 -- test-sdr-1.local -- version: 0.0.12; url: com.github.dcmartin.open-horizon.motion2mqtt-beta
>>> MAKE -- 11:19:50 -- registering test-sdr-4.local Sun Mar 10 11:19:50 PDT 2019
--- INFO -- ./nodereg.sh 80810 -- test-sdr-4.local
--- INFO -- ./nodereg.sh 80810 -- test-sdr-4.local -- configured with dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 80810 -- test-sdr-4.local -- version: 0.0.12; url: com.github.dcmartin.open-horizon.motion2mqtt-beta
>>> MAKE -- 11:19:55 -- registering test-cpu-3.local Sun Mar 10 11:19:55 PDT 2019
--- INFO -- ./nodereg.sh 80850 -- test-cpu-3.local
--- INFO -- ./nodereg.sh 80850 -- test-cpu-3.local -- configured with dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 80850 -- test-cpu-3.local -- version: 0.0.12; url: com.github.dcmartin.open-horizon.motion2mqtt-beta
>>> MAKE -- 11:20:00 -- registering test-cpu-6.local Sun Mar 10 11:20:00 PDT 2019
--- INFO -- ./nodereg.sh 80891 -- test-cpu-6.local
--- INFO -- ./nodereg.sh 80891 -- test-cpu-6.local -- configured with dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 80891 -- test-cpu-6.local -- version: 0.0.12; url: com.github.dcmartin.open-horizon.motion2mqtt-beta
>>> MAKE -- 11:20:05 -- registering test-cpu-2.local Sun Mar 10 11:20:05 PDT 2019
--- INFO -- ./nodereg.sh 80931 -- test-cpu-2.local
--- INFO -- ./nodereg.sh 80931 -- test-cpu-2.local -- configured with dcmartin@us.ibm.com/motion2mqtt-beta
--- INFO -- ./nodereg.sh 80931 -- test-cpu-2.local -- version: 0.0.12; url: com.github.dcmartin.open-horizon.motion2mqtt-beta
```

### 3.1.2 `make list-nodes`

After registration and initiation of Docker containers for services:

```
>>> MAKE -- 11:04:43 -- listing nodes: test-sdr-1.local test-sdr-4.local test-cpu-3.local test-cpu-6.local test-cpu-2.local
>>> MAKE -- 11:04:43 -- listing test-sdr-1.local Sun Mar 10 11:04:43 PDT 2019
{
  "id": "test-sdr-1",
  "organization": "dcmartin@us.ibm.com",
  "pattern": "dcmartin@us.ibm.com/motion2mqtt-beta",
  "name": "test-sdr-1",
  "token_last_valid_time": "2019-03-10 15:52:07 +0000 GMT",
  "token_valid": true,
  "ha": false,
  "configstate": {
    "state": "configured",
    "last_update_time": "2019-03-10 15:52:16 +0000 GMT"
  },
  "configuration": {
    "exchange_api": "https://alpha.edge-fabric.com/v1/",
    "exchange_version": "1.75.0",
    "required_minimum_exchange_version": "1.73.0",
    "preferred_exchange_version": "1.75.0",
    "architecture": "arm",
    "horizon_version": "2.22.3"
  },
  "connectivity": {
    "firmware.bluehorizon.network": true,
    "images.bluehorizon.network": true
  }
}
CONTAINER ID        IMAGE                                                            COMMAND             CREATED             STATUS              PORTS                              NAMES
b84ef6fe64dc        dcmartin/arm_com.github.dcmartin.open-horizon.motion2mqtt-beta   "/usr/bin/run.sh"   2 hours ago         Up 2 hours          0.0.0.0:8080-8082->8080-8082/tcp   4e4e38404d7e0c781c30a344965aba87b0174ced17e2fc86cdb3b31d9240ffd2-motion2mqtt
f7a443ad19db        dcmartin/arm_com.github.dcmartin.open-horizon.yolo4motion-beta   "/usr/bin/run.sh"   2 hours ago         Up 2 hours                                             dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.yolo4motion-beta_0.0.4_31924caa-5fdb-41d7-bb1c-9f2bd270a623-yolo4motion
707f1617bf23        dcmartin/arm_com.github.dcmartin.open-horizon.mqtt-beta          "/usr/bin/run.sh"   2 hours ago         Up 2 hours                                             dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.mqtt-beta_0.0.3_faaa9933-a445-486e-a746-3b0b5c835ec2-mqtt
0ecaaa367c13        dcmartin/arm_com.github.dcmartin.open-horizon.cpu-beta           "/usr/bin/run.sh"   2 hours ago         Up 2 hours                                             dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.cpu-beta_0.0.3_fe59c186-e074-4df5-a10b-2ef411974a3a-cpu
>>> MAKE -- 11:04:45 -- listing test-sdr-4.local Sun Mar 10 11:04:45 PDT 2019
{
  "id": "test-sdr-4",
  "organization": "dcmartin@us.ibm.com",
  "pattern": "dcmartin@us.ibm.com/motion2mqtt-beta",
  "name": "test-sdr-4",
  "token_last_valid_time": "2019-03-10 15:52:22 +0000 GMT",
  "token_valid": true,
  "ha": false,
  "configstate": {
    "state": "configured",
    "last_update_time": "2019-03-10 15:52:31 +0000 GMT"
  },
  "configuration": {
    "exchange_api": "https://alpha.edge-fabric.com/v1/",
    "exchange_version": "1.75.0",
    "required_minimum_exchange_version": "1.73.0",
    "preferred_exchange_version": "1.75.0",
    "architecture": "arm",
    "horizon_version": "2.22.3"
  },
  "connectivity": {
    "firmware.bluehorizon.network": true,
    "images.bluehorizon.network": true
  }
}
CONTAINER ID        IMAGE                                                            COMMAND             CREATED             STATUS              PORTS                              NAMES
d31e4b8f5d9b        dcmartin/arm_com.github.dcmartin.open-horizon.motion2mqtt-beta   "/usr/bin/run.sh"   2 hours ago         Up 2 hours          0.0.0.0:8080-8082->8080-8082/tcp   2bbfb8b6def64c0a6e9e74cb9888eea900bf9622854ded04e2ff50f49498eb0c-motion2mqtt
95e3748eec1d        dcmartin/arm_com.github.dcmartin.open-horizon.yolo4motion-beta   "/usr/bin/run.sh"   2 hours ago         Up 2 hours                                             dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.yolo4motion-beta_0.0.4_06fa9b0c-9cd3-4daf-b95c-1a7cdade792d-yolo4motion
45155b57b2b7        dcmartin/arm_com.github.dcmartin.open-horizon.mqtt-beta          "/usr/bin/run.sh"   2 hours ago         Up 2 hours                                             dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.mqtt-beta_0.0.3_03a046e6-8f32-4537-828b-04fc806184ef-mqtt
6e7f50c1dedb        dcmartin/arm_com.github.dcmartin.open-horizon.cpu-beta           "/usr/bin/run.sh"   2 hours ago         Up 2 hours                                             dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.cpu-beta_0.0.3_be7eb6d2-6eee-4aca-9e46-a3c1e0b0a7aa-cpu
>>> MAKE -- 11:04:46 -- listing test-cpu-3.local Sun Mar 10 11:04:46 PDT 2019
{
  "id": "test-cpu-3",
  "organization": "dcmartin@us.ibm.com",
  "pattern": "dcmartin@us.ibm.com/motion2mqtt-beta",
  "name": "test-cpu-3",
  "token_last_valid_time": "2019-03-10 15:52:43 +0000 GMT",
  "token_valid": true,
  "ha": false,
  "configstate": {
    "state": "configured",
    "last_update_time": "2019-03-10 15:52:54 +0000 GMT"
  },
  "configuration": {
    "exchange_api": "https://alpha.edge-fabric.com/v1/",
    "exchange_version": "1.75.0",
    "required_minimum_exchange_version": "1.73.0",
    "preferred_exchange_version": "1.75.0",
    "architecture": "arm",
    "horizon_version": "2.22.3"
  },
  "connectivity": {
    "firmware.bluehorizon.network": true,
    "images.bluehorizon.network": true
  }
}
CONTAINER ID        IMAGE                                                            COMMAND             CREATED             STATUS              PORTS                              NAMES
c2faff20f9ea        dcmartin/arm_com.github.dcmartin.open-horizon.motion2mqtt-beta   "/usr/bin/run.sh"   11 minutes ago      Up 11 minutes       0.0.0.0:8080-8082->8080-8082/tcp   4e45971d40d83bd994b0e4badf400249ab506670cc9daed8e023cfa58af1e064-motion2mqtt
d62418d1dff8        dcmartin/arm_com.github.dcmartin.open-horizon.yolo4motion-beta   "/usr/bin/run.sh"   12 minutes ago      Up 11 minutes                                          dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.yolo4motion-beta_0.0.4_e65c0d1b-cbc6-4786-a94f-c642030f7b1b-yolo4motion
901be4bdc5ee        dcmartin/arm_com.github.dcmartin.open-horizon.mqtt-beta          "/usr/bin/run.sh"   12 minutes ago      Up 12 minutes                                          dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.mqtt-beta_0.0.3_48db8127-32f6-4cc9-aec9-7a202c4af253-mqtt
175888fb695a        dcmartin/arm_com.github.dcmartin.open-horizon.cpu-beta           "/usr/bin/run.sh"   12 minutes ago      Up 12 minutes                                          dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.cpu-beta_0.0.3_f157f46e-804a-4718-98c6-be559c616040-cpu
>>> MAKE -- 11:04:48 -- listing test-cpu-6.local Sun Mar 10 11:04:48 PDT 2019
{
  "id": "test-cpu-6",
  "organization": "dcmartin@us.ibm.com",
  "pattern": "dcmartin@us.ibm.com/motion2mqtt-beta",
  "name": "test-cpu-6",
  "token_last_valid_time": "2019-03-10 15:53:00 +0000 GMT",
  "token_valid": true,
  "ha": false,
  "configstate": {
    "state": "configured",
    "last_update_time": "2019-03-10 15:53:12 +0000 GMT"
  },
  "configuration": {
    "exchange_api": "https://alpha.edge-fabric.com/v1/",
    "exchange_version": "1.75.0",
    "required_minimum_exchange_version": "1.73.0",
    "preferred_exchange_version": "1.75.0",
    "architecture": "arm",
    "horizon_version": "2.22.3"
  },
  "connectivity": {
    "firmware.bluehorizon.network": true,
    "images.bluehorizon.network": true
  }
}
CONTAINER ID        IMAGE                                                            COMMAND             CREATED             STATUS              PORTS                              NAMES
4570d43b32c0        dcmartin/arm_com.github.dcmartin.open-horizon.motion2mqtt-beta   "/usr/bin/run.sh"   2 hours ago         Up 2 hours          0.0.0.0:8080-8082->8080-8082/tcp   e398dc1e502dbfa7ba2ca13b39aaffb7f3497e0e8aaac19cfa00dd6812f585bf-motion2mqtt
c1516b128757        dcmartin/arm_com.github.dcmartin.open-horizon.yolo4motion-beta   "/usr/bin/run.sh"   2 hours ago         Up 2 hours                                             dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.yolo4motion-beta_0.0.4_62c80f17-138a-49b6-a574-817cd576f7fb-yolo4motion
41cb6bd7caa1        dcmartin/arm_com.github.dcmartin.open-horizon.mqtt-beta          "/usr/bin/run.sh"   2 hours ago         Up 2 hours                                             dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.mqtt-beta_0.0.3_2cd75bc7-df20-4438-8e7c-983d9231f35f-mqtt
8778e3ef5682        dcmartin/arm_com.github.dcmartin.open-horizon.cpu-beta           "/usr/bin/run.sh"   2 hours ago         Up 2 hours                                             dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.cpu-beta_0.0.3_378b0f55-3907-42f3-aeda-fecf0cc29a86-cpu
>>> MAKE -- 11:04:50 -- listing test-cpu-2.local Sun Mar 10 11:04:50 PDT 2019
{
  "id": "test-cpu-2",
  "organization": "dcmartin@us.ibm.com",
  "pattern": "dcmartin@us.ibm.com/motion2mqtt-beta",
  "name": "test-cpu-2",
  "token_last_valid_time": "2019-03-10 15:53:19 +0000 GMT",
  "token_valid": true,
  "ha": false,
  "configstate": {
    "state": "configured",
    "last_update_time": "2019-03-10 15:53:28 +0000 GMT"
  },
  "configuration": {
    "exchange_api": "https://alpha.edge-fabric.com/v1/",
    "exchange_version": "1.75.0",
    "required_minimum_exchange_version": "1.73.0",
    "preferred_exchange_version": "1.75.0",
    "architecture": "arm",
    "horizon_version": "2.22.3"
  },
  "connectivity": {
    "firmware.bluehorizon.network": true,
    "images.bluehorizon.network": true
  }
}
CONTAINER ID        IMAGE                                                            COMMAND             CREATED             STATUS              PORTS                              NAMES
44c27bff8b87        dcmartin/arm_com.github.dcmartin.open-horizon.motion2mqtt-beta   "/usr/bin/run.sh"   2 hours ago         Up 2 hours          0.0.0.0:8080-8082->8080-8082/tcp   a3c4ac393498b4fefcc213a1d2e5237c09557a24438d543e70a07fe6dfcacefe-motion2mqtt
3b4be796e88b        dcmartin/arm_com.github.dcmartin.open-horizon.yolo4motion-beta   "/usr/bin/run.sh"   2 hours ago         Up 2 hours                                             dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.yolo4motion-beta_0.0.4_9161d21c-8418-472d-8c16-19b12e598643-yolo4motion
838e17a284d5        dcmartin/arm_com.github.dcmartin.open-horizon.mqtt-beta          "/usr/bin/run.sh"   2 hours ago         Up 2 hours                                             dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.mqtt-beta_0.0.3_f122312e-b094-4c7f-95c3-7ea569d827b7-mqtt
7e7e59bbda4d        dcmartin/arm_com.github.dcmartin.open-horizon.cpu-beta           "/usr/bin/run.sh"   2 hours ago         Up 2 hours                                             dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.cpu-beta_0.0.3_2f5293d1-6085-4ab2-8fd1-2f1b282e4fdb-cpu

```

### `make test-nodes`

Nodes configured with the pattern will respond to inquiries on their status port, e.g. the `motion2mqtt` service exposes port `8082` for its status.  Executing this target in the `motion2mqtt` directory will interrogate that port, for example:

```
--- MAKE -- start testing motion2mqtt-beta on test-sdr-1.local port 8082 at Mon Feb 25 17:33:55 PST 2019
ELAPSED: 2
{"period":300}
{"date":1551140470}
{"pattern":{"label":"motion2mqtt-beta"}}
{"pattern":{"services":"0.0.6"}}
{"pattern":{"services":"0.0.6"}}
{"pattern":{"services":"0.0.6"}}
{"pattern":{"updated":"2019-02-26T00:00:35.550Z[UTC]"}}
{"horizon":{"pattern":"dcmartin@us.ibm.com/motion2mqtt-beta"}}
{"cpu":true}
{"cpu":100}
{"event":true}
{"image":true}
--- MAKE -- start testing motion2mqtt-beta on test-sdr-4.local port 8082 at Mon Feb 25 17:33:58 PST 2019
ELAPSED: 2
{"period":300}
{"date":1551139975}
{"pattern":{"label":"motion2mqtt-beta"}}
{"pattern":{"services":"0.0.6"}}
{"pattern":{"services":"0.0.6"}}
{"pattern":{"services":"0.0.6"}}
{"pattern":{"updated":"2019-02-26T00:00:35.550Z[UTC]"}}
{"horizon":{"pattern":"dcmartin@us.ibm.com/motion2mqtt-beta"}}
{"cpu":true}
{"cpu":31.29}
{"event":true}
{"image":true}
--- MAKE -- start testing motion2mqtt-beta on test-cpu-2.local port 8082 at Mon Feb 25 17:34:03 PST 2019
ELAPSED: 2
{"period":300}
{"date":1551140497}
{"pattern":{"label":"motion2mqtt-beta"}}
{"pattern":{"services":"0.0.6"}}
{"pattern":{"services":"0.0.6"}}
{"pattern":{"services":"0.0.6"}}
{"pattern":{"updated":"2019-02-26T00:00:35.550Z[UTC]"}}
{"horizon":{"pattern":"dcmartin@us.ibm.com/motion2mqtt-beta"}}
{"cpu":true}
{"cpu":8.37}
{"event":true}
{"image":true}
--- MAKE -- start testing motion2mqtt-beta on test-cpu-3.local port 8082 at Mon Feb 25 17:34:08 PST 2019
ELAPSED: 1
{"period":300}
{"date":1551140000}
{"pattern":{"label":"motion2mqtt-beta"}}
{"pattern":{"services":"0.0.6"}}
{"pattern":{"services":"0.0.6"}}
{"pattern":{"services":"0.0.6"}}
{"pattern":{"updated":"2019-02-26T00:00:35.550Z[UTC]"}}
{"horizon":{"pattern":"dcmartin@us.ibm.com/motion2mqtt-beta"}}
{"cpu":true}
{"cpu":100}
{"event":true}
{"image":true}
--- MAKE -- start testing motion2mqtt-beta on test-cpu-6.local port 8082 at Mon Feb 25 17:34:10 PST 2019
ELAPSED: 1
{"period":300}
{"date":1551140082}
{"pattern":{"label":"motion2mqtt-beta"}}
{"pattern":{"services":"0.0.6"}}
{"pattern":{"services":"0.0.6"}}
{"pattern":{"services":"0.0.6"}}
{"pattern":{"updated":"2019-02-26T00:00:35.550Z[UTC]"}}
{"horizon":{"pattern":"dcmartin@us.ibm.com/motion2mqtt-beta"}}
{"cpu":true}
{"cpu":72.9}
{"event":true}
{"image":true}
--- MAKE -- finish testing motion2mqtt-beta on test-sdr-1.local test-sdr-4.local test-cpu-2.local test-cpu-3.local test-cpu-6.local at Mon Feb 25 17:34:12 PST 2019
```

### 3.1.3 `make undo-nodes`

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
