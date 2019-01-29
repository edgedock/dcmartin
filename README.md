# Open Horizon

Open Horizon is a distributed, decentralized, automated system for the orchestration of workloads at the _edge_ of the *cloud*.  More information is available on [Github][open-horizon].  Devices with Horizon installed may _register_ for patterns using services provided by the IBM Cloud.

## Credentials

**Note:** _You will need an IBM Cloud [account][ibm-registration]_

Credentials are required to participate; request access on the IBM Applied Sciences [Slack][edge-slack] by providing an IBM Cloud Platform API key, which can be [created][ibm-apikeys] using your IBMid.  An API key will be provided for an IBM sponsored Kafka service during the alpha phase.  The same API key is used for both the CPU and SDR addon-patterns.

# Setup

Refer to these [instructions][setup].  Installation package for macOS is also [available][macos-install]

```
wget -qO - ibm.biz/horizon-setup | sudo bash
sudo addgroup $(whoami) docker
sudo apt install -y git make
mkdir ~/gitdir
cd ~/gitdir
git clone http://github.com/dcmartin/open-horizon
make
```

# Services

There are sample services available:

1. [`cpu`][cpu-service] -  CPU usage as a percentage
1. [`wan`][wan-service] -  Wide Area Network information
1. [`hal`][hal-service] -  Hardware Abstraction Layer information
1. [`yolo`][yolo-service] -  Entity recognition and counting

[yolo-service]: https://github.com/dcmartin/open-horizon/tree/master/yolo
[hal-service]: https://github.com/dcmartin/open-horizon/tree/master/hal
[cpu-service]: https://github.com/dcmartin/open-horizon/tree/master/cpu
[wan-service]: https://github.com/dcmartin/open-horizon/tree/master/wan

# Patterns

There are sample patterns available:

1. [`yolo2msghub`][yolo2msghub-pattern] - Transmits `yolo`,`cpu`,`gps`,`hal` services payload to a Kafka broker
1. [`motion`][motion-pattern] - Motion detection, image capture, and publish to a MQTT broker

[yolo2msghub-pattern]: https://github.com/dcmartin/open-horizon/tree/master/yolo2msghub
[motion-pattern]: https://github.com/dcmartin/open-horizon/tree/master/motion

# Further Information 

Refer to the following for more information on [getting started][edge-fabric] and [installation][edge-install].

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

David C Martin (github@dcmartin.com)

[commits]: https://github.com/dcmartin/open-horizon/commits/master
[contributors]: https://github.com/dcmartin/open-horizon/graphs/contributors
[dcmartin]: https://github.com/dcmartin
[edge-fabric]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/getting-started.html
[edge-install]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/adding-devices.html
[edge-slack]: https://ibm-appsci.slack.com/messages/edge-fabric-users/
[ibm-apikeys]: https://console.bluemix.net/iam/#/apikeys
[ibm-registration]: https://console.bluemix.net/registration/
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: https://github.com/open-horizon/anax/releases
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: https://github.com/dcmartin/open-horizon/blob/master/setup/README.md
