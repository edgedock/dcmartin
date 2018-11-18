## About

This repository contains a sample script to automatically setup nodes for [Open Horizon][open-horizon] as provided in the IBM Cloud.

Detailed [documentation][edge-fabric] for the IBM Cloud Edge Fabric is available on-line.  A Slack [channel][edge-slack] is also available.

**Note**: _You will need an IBM Cloud [account][ibm-registration]_

## Configuration

Change the `template.json` file for your environment.

### Option: `nodes`

A list of nodes identified by MAC address; these entries are changed during initialization to indicate status.

Example initial `nodes` list:

```
  "nodes": [
    { "mac": "B8:27:EB:D0:95:AD", "id": "rp1" },
    { "mac": "B8:27:EB:01:E6:05", "id": "rp2" },
    { "mac": "B8:27:EB:90:6F:4A", "id": "rp3" },
    { "mac": "B8:27:EB:BD:1D:F3", "id": "rp4" },
    { "mac": "B8:27:EB:51:A7:48", "id": "rp5" },
    { "mac": "B8:27:EB:DD:A0:94", "id": "rp6" },
    { "mac": "B8:27:EB:7B:F9:FB", "id": "rp7" },
    { "mac": "B8:27:EB:F7:3A:8C", "id": "rp8" },
    { "mac": "B8:27:EB:A2:6F:D9", "id": "rp9" }
  ] 
```

Example status of node from list during initialization; state information includes:

+ *ssh* 
  - `id` for configuration used, including `device` name and `token`
+ *software* 
  - `repository` for package, `horizon` version and `command`, and `docker` version information
+ *exchange* 
  - `id` and `status` of exchange, `node` list, including `node.id` for `device` name and `node.pattern` for assigned pattern

```
    { "mac": "B8:27:EB:F7:3A:8C", "id": "rp8",
      "ssh": { "id": "cpu2msghub@cgiroua", "token": "Ah@rdP@$$wOoD", "device": "test-cpu-1" },
      "software": {
        "repository": "testing",
        "horizon": "2.20.0",
        "docker": "Docker version 18.09.0, build 4d60db4",
        "command": "/usr/bin/hzn"
      },
      "exchange": {
        "id": "cgiroua",
        "status": null,
        "node": {
          "id": "00000000c4a26fd9",
          "organization": null,
          "pattern": null,
          "name": null,
          "token_last_valid_time": "",
          "token_valid": null,
          "ha": null,
          "configstate": { "state": "unconfigured", "last_update_time": "" },
          "configuration": {
            "exchange_api": "https://alpha.edge-fabric.com/v1/",
            "exchange_version": "1.63.0",
            "required_minimum_exchange_version": "1.63.0",
            "preferred_exchange_version": "1.63.0",
            "architecture": "arm",
            "horizon_version": "2.20.0"
          },
          "connectivity": { "firmware.bluehorizon.network": true, "images.bluehorizon.network": true }
        }
      }
    }
```

### Option: `configurations`

List of configuration definitions of `pattern`, `exchange`, `network` for a set of `nodes`, each with `device` name and authentication `token`

Any number of `variables` may be defined appropriate for the defined `pattern`.

**Note**: _You must obtain [credentials][kafka-creds] for IBM MessageHub for alpha phase_

```
  "configurations": [
    { 
      "id": "configuration-1",
      "pattern": "cpu2msghub",
      "exchange": "exchange-1",
      "network": "PRODUCTION",
      "public_key": null,
      "private_key": null,
      "variables": [
        { "key": "MSGHUB_API_KEY", "value": "%%MSGHUB_API_KEY%%" }
      ],
      "nodes": [
        { "id": "rp1", "device": "test-cpu-1", "token": "Ah@rdP@$$wOoD" },
        { "id": "rp2", "device": "test-cpu-2", "token": "Ah@rdP@$$wOoD" },
        { "id": "rp3", "device": "test-cpu-3", "token": "Ah@rdP@$$wOoD" },
        { "id": "rp4", "device": "test-cpu-4", "token": "Ah@rdP@$$wOoD" }
      ] 
    },
    {
      "id": "configuration-2",
      "pattern": "sdr2msghub",
      "exchange": "exchange-1",
      "network": "PRODUCTION",
      "variables": [
        { "key": "MSGHUB_API_KEY", "value": "%%MSGHUB_API_KEY%%" }
      ],
      "public_key": null,
      "private_key": null,
      "nodes": [ 
        { "id": "rp5", "device": "test-sdr-1", "token": "Ah@rdP@$$wOoD" },
        { "id": "rp6", "device": "test-sdr-2", "token": "Ah@rdP@$$wOoD" },
        { "id": "rp7", "device": "test-sdr-3", "token": "Ah@rdP@$$wOoD" },
        { "id": "rp8", "device": "test-sdr-4", "token": "Ah@rdP@$$wOoD" }
      ]
    }
  ]
```

### Option: `patterns`

List of pattern definitions of `id`, `org`, and `url` for the patterns available in the `exchange`.

```
  "patterns": [
    {
      "id": "cpu2msghub",
      "org": "IBM",
      "url": "https://github.com/open-horizon/examples/wiki/service-cpu2msghub"
    },
    {
      "id": "sdr2msghub",
      "org": "IBM",
      "url": "https://github.com/open-horizon/examples/wiki/service-sdr2msghub"
    }
  ]
```

### Option: `exchanges`

List of exchange definitions for `id`, `org`, `url`, and credentials `username` and `password`

```
  "exchanges": [
    {
      "id": "exchange-1",
      "org": "%%HORIZON_ORG_ID%%",
      "url": "%%HORIZON_EXCHANGE_URL%%",
      "username": "%%EXCHANGE_USERNAME%%",
      "password": "%%EXCHANGE_PASSWORD%%"
    }
  ]
```

### Option: `networks`

List of network definitions of `id`, `dhcp`, `ssid`, and `password` for nodes.

Network configuration is _only_ applied once node has been successfully initialized.

```
  "networks": [
    {
      "id": "setup",
      "dhcp": "dynamic",
      "ssid": "%%WIFI_SSID%%",
      "password": "%%WIFI_PASSWORD%%"
    },
    {
      "id": "PRODUCTION",
      "dhcp": "dynamic",
      "ssid": "TEST",
      "password": "0123456789"
    }
  ]
```

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

David C Martin (github@dcmartin.com)

[commits]: https://github.com/dcmartin/open-horizon/setup/commits/master
[contributors]: https://github.com/dcmartin/open-horizon/setup/graphs/contributors
[releases]: https://github.com/dcmartin/open-horizon/setup/releases

[dcmartin]: https://github.com/dcmartin
[issue]: https://github.com/dcmartin/open-horizon/setup/issues
[keepchangelog]: http://keepachangelog.com/en/1.0.0/
[repository]: https://github.com/dcmartin/hassio-addons
[watson-nlu]: https://console.bluemix.net/catalog/services/natural-language-understanding
[watson-stt]: https://console.bluemix.net/catalog/services/speech-to-text
[edge-slack]: https://ibm-appsci.slack.com/messages/edge-fabric-users/
[ibm-registration]: https://console.bluemix.net/registration/
[kafka-creds]: https://console.bluemix.net/services/messagehub/b5f8df99-d3f6-47b8-b1dc-12806d63ae61/?paneId=credentials&new=true&env_id=ibm:yp:us-south&org=51aea963-6924-4a71-81d5-5f8c313328bd&space=f965a097-fcb8-4768-953e-5e86ea2d66b4
[open-horizon]: https://github.com/open-horizon
[cpu-pattern]: https://github.com/open-horizon/examples/tree/master/edge/msghub/cpu2msghub
[edge-fabric]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/getting-started.html
[edge-install]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/adding-devices.html
[macos-install]: https://github.com/open-horizon/anax/releases
[hzn-setup]: https://raw.githubusercontent.com/dcmartin/hassio-addons/master/horizon/hzn-setup.sh
