# Open Horizon Setup

This repository contains sample scripts to automatically setup nodes for [Open Horizon][open-horizon] as provided in the IBM Cloud.  Detailed [documentation][edge-fabric] for the IBM Cloud Edge Fabric is available on-line.  A Slack [channel][edge-slack] is also available.

You may create and publish your patterns to your organization.  Refer to the [examples][examples] available on GitHub; a work-in-progress for the [Motion][Motion] software as a pattern is being [developed][here].

## Setup

Please see the Horizon setup [instructions][dcm-oh]

## Initialization
The `init-devices.sh` script automates the setup, installation, and configuration of multiple devices; currently this script has been tested for RaspberryPi running Raspbian Stretch.  The script processes a list of `nodes` identified by the `MAC` addresses, updating the node entries with their resulting configuration.

**RECOMMENDED**: _Install personal `ssh` key using `ssh-copy-id` to the target device prior to utilization of script._

## Usage

1. Copy the [`template.json`][template] file and edit for your environment
1. Run the `init-devices.sh` script with the name of your configuration file and attached network to scan.  The default configuration file name is `horizon.json` and the default network is `192.168.1.0/24`.
```
sudo ./init-devices.sh myconfig.json 192.168.1.0/24
```
Devices discovered on the network are configured for `ssh` access with PKI for each configuration after initial login with distribution username and password; for example, Raspbian LINUX for RaspberryPi uses `pi` and `raspberry` as defaults.

Inspect the resulting configuration file for configuration changes applied to nodes discovered.

## Configuration

Copy and edit the `template.json` file for your environment.  Values are highlighted as `%%VALUE%%`

### Option: `nodes`
A list of nodes identified by MAC address; these entries are changed during initialization to indicate status.  Example initial `nodes` list:
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

### Option: `configurations`
List of configuration definitions of `pattern`, `exchange`, `network` for a set of `nodes`, each with `device` name and authentication `token`.  Any number of `variables` may be defined appropriate for the defined `pattern`.

**Note**: _You must obtain [credentials][kafka-creds] for IBM MessageHub for alpha phase_
```
  "configurations": [
    {
      "id": "cpuconf",
      "pattern": "cpu2msghub",
      "exchange": "production",
      "network": "PRODUCTION",
      "public_key": null,
      "private_key": null,
      "variables": [
        { "key": "MSGHUB_API_KEY", "value": "%%MSGHUB_API_KEY%%" },
        { "key": "MSGHUB_BROKER_URL", "value": "%%MSGHUB_BROKER_URL%%" }
      ],
      "nodes": [
        { "id": "rp1", "device": "test-cpu-1", "token": "foobar" },
        { "id": "rp2", "device": "test-cpu-2", "token": "foobar" },
        { "id": "rp3", "device": "test-cpu-3", "token": "foobar" },
        { "id": "rp4", "device": "test-cpu-4", "token": "foobar" }
      ]
    },
    {
      "id": "sdrconf",
      "pattern": "sdr2msghub",
      "exchange": "production",
      "network": "PRODUCTION",
      "variables": [
        { "key": "MSGHUB_API_KEY", "value": "%%MSGHUB_API_KEY%%" }
      ],
      "public_key": null,
      "private_key": null,
      "nodes": [
        { "id": "rp5", "device": "test-sdr-1", "token": "foobar" },
        { "id": "rp6", "device": "test-sdr-2", "token": "foobar" },
        { "id": "rp7", "device": "test-sdr-3", "token": "foobar" },
        { "id": "rp8", "device": "test-sdr-4", "token": "foobar" }
      ]
    }
  ]
```

### Option: `patterns`
The edge fabric runs _patterns_ which correspond to one or more LINUX containers providing various services.  There are two public patterns in the **IBM** organization which periodically send data an IBM Message Hub (aka Kafka) service _topic_:

+ [`cpu2msghub`][cpu-pattern] - sends a CPU measurement and GPS location message to your **private** topic
+ [`sdr2msghub`][sdr-pattern] - sends a software-defined radio (SDR) audio and GPS location message to a **shared** topic

Both patterns require an API key and list of service broker URL's.

+ MSGHUB_API_KEY - a **private** key for each user; may be shared across multiple devices
+ MSGHUB_BROKER_URL - a list of URL for the IBM Message Hub service
```
  "patterns": [
    {
      "id": "cpu2msghub",
      "org": "IBM",
      "url": "github.com.open-horizon.examples.cpu2msghub"
    },
    {
      "id": "sdr2msghub",
      "org": "IBM",
      "url": "github.com.open-horizon.examples.sdr2msghub"
    }
  ]
```

### Option: `exchanges`
List of exchange definitions for `id`, `org`, `url`, and credentials `username` and `password`
```
  "exchanges": [
    {
      "id": "production",
      "org": "<IBM Cloud login email>",
      "url": "https://alpha.edge-fabric.com/v1",
      "password": "<IBM Cloud Platform API key>"
    }
  ]
```

### Option: `networks`
List of network definitions of `id`, `dhcp`, `ssid`, and `password` for nodes.  Network configuration is _only_ applied once node has been successfully initialized.
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

## Output

When the script completes, the `nodes` list is updated with the configurations applied, for example:

```
    {
      "mac": "B8:27:EB:F7:3A:8C",
      "id": "rp8",
      "ssh": {
        "id": "cpuconf",
        "device": "test-cpu-1",
        "token": "Ah@rdP@$$wOoD"
      },
      "software": {
        "repository": "updates",
        "horizon": "2.20.1",
        "docker": "Docker version 18.09.0, build 4d60db4",
        "command": "/usr/bin/hzn",
        "distribution": {
          "id": "raspbian-stretch-lite",
          "kernel_version": "4.14",
          "release_date": "2018-11-13",
          "version": "November 2018"
        }
      },
      "exchange": {
        "id": "production",
        "url": "https://alpha.edge-fabric.com/v1",
        "node": {
          "dcmartin@us.ibm.com/test-cpu-1": {
            "lastHeartbeat": "2018-11-21T19:08:50.381Z[UTC]",
            "msgEndPoint": "",
            "name": "test-cpu-1",
            "owner": "dcmartin@us.ibm.com/dcmartin@us.ibm.com",
            "pattern": "",
            "publicKey": "",
            "registeredServices": [],
            "softwareVersions": null,
            "token": "********"
          }
        },
        "status": {
          "dbSchemaVersion": 15,
          "msg": "Exchange server operating normally",
          "numberOfAgbotAgreements": 6,
          "numberOfAgbotMsgs": 1,
          "numberOfAgbots": 2,
          "numberOfNodeAgreements": 8,
          "numberOfNodeMsgs": 0,
          "numberOfNodes": 20,
          "numberOfUsers": 28
        }
      },
      "node": {
        "id": "00000000c4a26fd9",
        "organization": "dcmartin@us.ibm.com",
        "pattern": "IBM/cpu2msghub",
        "name": "00000000c4a26fd9",
        "token_last_valid_time": "2018-11-21 18:03:20 +0000 UTC",
        "token_valid": true,
        "ha": false,
        "configstate": {
          "state": "configured",
          "last_update_time": "2018-11-21 18:03:24 +0000 UTC"
        },
        "configuration": {
          "exchange_api": "https://alpha.edge-fabric.com/v1/",
          "exchange_version": "1.65.0",
          "required_minimum_exchange_version": "1.63.0",
          "preferred_exchange_version": "1.63.0",
          "architecture": "arm",
          "horizon_version": "2.20.1"
        },
        "connectivity": {
          "firmware.bluehorizon.network": true,
          "images.bluehorizon.network": true
        }
      },
      "pattern": [
        {
          "name": "Policy for github.com.open-horizon.examples.cpu merged with Policy for github.com.open-horizon.examples.gps merged with cpu2msghub__IBM_arm",
          "current_agreement_id": "ca92b425dd479835fcdb965d12e492e0d87db3e2233035f3b02e027ad56aeb73",
          "consumer_id": "IBM/agbot-1",
          "agreement_creation_time": "2018-11-21 18:03:50 +0000 UTC",
          "agreement_accepted_time": "2018-11-21 18:03:59 +0000 UTC",
          "agreement_finalized_time": "2018-11-21 18:04:05 +0000 UTC",
          "agreement_execution_start_time": "2018-11-21 18:04:14 +0000 UTC",
          "agreement_data_received_time": "",
          "agreement_protocol": "Basic",
          "workload_to_run": {
            "url": "github.com.open-horizon.examples.cpu2msghub",
            "org": "IBM",
            "version": "1.2.5",
            "arch": "arm"
          }
        }
      ],
      "network": {
        "ssid": "TEST",
        "password": "0123456789"
      }
    }
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
[hzn-setup]: https://raw.githubusercontent.com/dcmartin/open-horizon/master/setup/hzn-setup.sh
[image]: http://releases.ubuntu.com/18.04.1/
[examples]: https://github.com/open-horizon/examples
[Motion]: http://motion-project.io/
[here]: https://github.com/dcmartin/open-horizon/tree/master/motion
[template]: https://github.com/dcmartin/open-horizon/blob/master/setup/template.json
[dcm-oh]: https://github.com/dcmartin/open-horizon/tree/master/README.md
