# Open Horizon Setup

This repository contains sample scripts to automatically setup nodes for [Open Horizon][open-horizon] as provided in the IBM Cloud.  Detailed [documentation][edge-fabric] for the IBM Cloud Edge Fabric is available on-line.  A Slack [channel][edge-slack] is also available.  You may create and publish your patterns to your organization.  Refer to the [examples][examples] available on GitHub.

You will need an [IBM Cloud][ibm-cloud] account and IBM MessageHub credentials available in the Slack [channel][edge-slack].

# System Installation

System level installation modifies the operating system image boot sequence to install the Open Horizon software.  This technique is suitable for replication.  Please refer to [these][system] instructions.

# Network Installation

Installations can be performed over the network when devices are discovered.  This technique is suitable for early-adopters. Please refer to [these][network] instructions.

# Manual Installation

## Supported devices
A target device or virtual environment is required; either of the following are sufficient.

### LINUX (Ubuntu) Virtual Machine
Download an Ubuntu [image][ubuntu-image] and start a new virtual machine, e.g. using [VirtualBox][virtualbox], with the CD/DVD image as the boot device; change networking from `NAT` to `Bridged`.  **Note**: Install the VirtualBox Extensions Pack.  Connect to VM using `ssh` or use the GUI to start a Terminal session.

### RaspberryPi3+ with Raspbian Stretch
1. Download Raspbian [image][raspbian-image] for the RaspberryPi3 and flash a 32 Gbyte+ micro-SD card.  On macOS use [Etcher][etcher-io], **but** <ins>unset the option</ins> to `Auto un-mount on success`.
1. Create the file `ssh` in the root directory of the mounted SD-card; on macOS use `touch /Volumes/boot/ssh`.  This step will enable remote access using the `ssh` command with the default login `pi` and password `raspberry`.
1. Eject the SD-card (e.g. on macOS use `diskutil eject /Volume/boot`).
1. Insert uSD-card into a RPi3 and connect to _wired_ ethernet (or create appropriate `wpa_supplicant.conf` file in the root directory).

## Process
For either Ubuntu VM or Raspbian Raspberry Pi3 the software can be installed manually.  Log into the VM or RPi3 and run the command below to install Horizon.  This installation script [`hzn-setup.sh`][horizon-setup] is used to install the Horizon software under LINUX; the short-cut URL is `ibm.biz/horizon-setup`:
```
wget -qO - ibm.biz/horizon-setup | sudo bash
```
When this installation finishes the device will still need to be registered for a specific pattern.  Refer to the _Horizon Addons_ section below for information on using Home Assistant addons to initiate device patterns and listen for sensor output.

# Horizon Addons

Add the repository [`https://github.com/dcmartin/hassio-addons`][dcm-addons] to the Add-on Store.  Install and start the following addons (n.b. both require `MSGHUB_API_KEY` to `listen` for Kafka messages):

+ [cpu2msghub][cpu2msghub-addon]: specifies the IBM published [cpu2msghub][cpu2msghub-pattern] pattern, which sends CPU load from `/sys/proc` and GPS location to a _private_ Kafka topic; optionally listens to the _private_ Kafka topic and publishes a JSON payload to topic `kafka/cpu-load` on designated MQTT server, e.g. `core-mosquitto`
+ [sdr2msghub][sdr2msghub-addon]: specifies the IBM published [sdr2msghub][sdr2msghub-pattern] pattern, which sends software-defined-radio (SDR) audio and GPS location to a _shared_ Kafka topic; optionally listens to the _shared_ Kafka topic and publishes a JSON payload to topic `kafka/sdr-audio` on designated MQTT server, e.g. `core-mosquitto`
  - Optional: Converts audio received into text using IBM Watson Speech-to-Text (STT) service.
  - Optional: Parses text into language using IBM Natural Language Understanding (NLU) service.

## Sample Output

![sdr2msghub sentiment](https://github.com/dcmartin/hassio-addons/raw/master/sdr2msghub/sdr2msghub_sentiment.png?raw=true "SDR2MSGHUB")
![cpu2msghub sentiment](https://github.com/dcmartin/hassio-addons/raw/master/cpu2msghub/cpu2msghub_cpu.png?raw=true "CPU2MSGHUB")

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
[cpu2msghub-addon]: https://github.com/dcmartin/hassio-addons/tree/master/cpu2msghub
[cpu2msghub-pattern]: https://github.com/open-horizon/examples/tree/master/edge/msghub/cpu2msghub
[dcm-addons]: https://github.com/dcmartin/hassio-addons
[dcmartin]: https://github.com/dcmartin
[docker]: https://www.docker.com/
[edge-fabric]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/getting-started.html
[edge-install]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/adding-devices.html
[edge-slack]: https://ibm-appsci.slack.com/messages/edge-fabric-users/
[etcher-io]: https://www.balena.io/etcher/
[examples]: https://github.com/open-horizon/examples
[ha-addons]: https://github.com/hassio-addons
[ha-home]: https://www.home-assistant.io/
[hassio-install]: https://www.home-assistant.io/hassio/installation/
[hassio-setup]: https://github.com/dcmartin/open-horizon/blob/master/setup/hassio-install.sh
[horizon-setup]: https://github.com/dcmartin/open-horizon/blob/master/setup/hzn-install.sh
[ibm-apikeys]: https://console.bluemix.net/iam/#/apikeys
[ibm-cloud]: http://cloud.ibm.com/
[ibm-registration]: https://console.bluemix.net/registration/
[issue]: https://github.com/dcmartin/open-horizon/setup/issues
[keepchangelog]: http://keepachangelog.com/en/1.0.0/
[network]: https://github.com/dcmartin/open-horizon/tree/master/setup/NETWORK.md
[open-horizon]: https://github.com/open-horizon
[raspbian-image]: https://www.raspberrypi.org/downloads/raspbian/
[releases]: https://github.com/dcmartin/open-horizon/setup/releases
[repository]: https://github.com/dcmartin/open-horizon/setup
[sdr2msghub-addon]: https://github.com/dcmartin/hassio-addons/tree/master/sdr2msghub
[sdr2msghub-pattern]: https://github.com/open-horizon/examples/tree/master/edge/msghub/sdr2msghub
[setup-readme]: https://github.com/dcmartin/open-horizon/blob/master/setup/README.md
[setupdir]: https://github.com/dcmartin/open-horizon/tree/master/setup
[system]: https://github.com/dcmartin/open-horizon/tree/master/setup/SYSTEM.md
[ubuntu-image]: http://releases.ubuntu.com/18.04.1/
[virtualbox]: http://www.virtualbox.org/
