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

## `make` targets

### `test-nodes`

This target tests the node specified by the `TEST_NODES_NAME` variable; its value may be specified through a temporary, git-ignored, file: `TEST_TMP_MACHINES`, for example:

```
test-sdr-1.local
test-sdr-4.local
test-cpu-2.local
test-cpu-3.local
test-cpu-6.local
```

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
