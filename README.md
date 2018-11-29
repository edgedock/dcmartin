# Open Horizon

Open Horizon is a distributed, decentralized, automated system for the orchestration of workloads at the _edge_ of the *cloud*.  More information is available on [Github][oh-github].  Devices with Horizon installed may _register_ for patterns using services provided by the IBM Cloud.

## Credentials

**Note:** _You will need an IBM Cloud [account][ibm-registration]_

Credentials are required to participate; request access on the IBM Applied Sciences [Slack][edge-slack] by providing an IBM Cloud Platform API key, which can be [created][ibm-apikeys] using your IBMid.  An API key will be provided for an IBM sponsored Kafka service during the alpha phase.  The same API key is used for both the CPU and SDR addon-patterns.

## Target device

A target device or virtual environment is required; either of the following are sufficient.

### LINUX (Ubuntu) Virtual Machine
Download an Ubuntu [image][ubuntu-image] and start a new virtual machine, e.g. using [VirtualBox][VirtualBox], with the CD/DVD image as the boot device; change networking from `NAT` to `Bridged`.  **Note**: Install the VirtualBox Extensions Pack.  Connect to VM using `ssh` or use the GUI to start a Terminal session.

### RaspberryPi3+ with Raspbian Stretch
1. Download Raspbian [image][raspbian-image] for the RaspberryPi3 and flash a 32 Gbyte+ micro-SD card.  On macOS use [Etcher][etcher-io], **but** <ins>unset the option</ins> to `Auto un-mount on success`.
1. Create the file `ssh` in the root directory of the mounted SD-card; on macOS use `touch /Volumes/boot/ssh`.  This step will enable remote access using the `ssh` command with the default login `pi` and password `raspberry`.
1. Eject the SD-card (e.g. on macOS use `diskutil eject /Volume/boot`).
1. Insert uSD-card into a RPi3 and connect to _wired_ ethernet (or create appropriate `wpa_supplicant.conf` file in the root directory).

## Installation

### Manual installation (easiest)
For either Ubuntu VM or Raspbian Raspberry Pi3 the software can be installed manually.  Log into the VM or RPi3 and run the command below to install Horizon.  This installation script [`hzn-setup.sh`][hznsetup] is used to install the Horizon software under LINUX.
```
wget -qO - ibm.biz/horizon-setup | sudo bash
```

### Automated installation (for multiple devices)
If you have a collection of RaspberryPi3 devices and wish to initialize automatically, refer to the [instructions][setup-readme] to using the [`init-devices.sh`][initdev] script the [setup][setupdir] sub-directory of [this][repository] repository.  Automated installation requires the MAC addresses of the devices.

### Detailed installation instructions

More detailed instructions are [available][edge-install].  Installation package for macOS is also [available][macos-install]

## Usage

### Home Assistant

The [Home-Assistant][ha-home] (HA) open source software provides support for a wide variety of home automation sensors from almost all vendors on the market.  In addition, HA provides an _addon_ capability through its supervisor.  These [addons][ha-addons] provide a wide variety of capabilities, all packaged as [Docker][docker] containers.

There are two existing demonstration _addons_ for Horizon:

1. [cpu2msghub][cpu2msghub-addon]: specifies the IBM published [cpu2msghub][cpu2msghub-pattern] pattern, which sends CPU load from `/sys/proc` and GPS location to a _private_ Kafka topic; optionally listens to the _private_ Kafka topic and publishes a JSON payload to topic `kafka/cpu-load` on designated MQTT service, e.g. `core-mosquitto`
1. [sdr2msghub][sdr2msghub-addon]: specifies the IBM published [sdr2msghub][sdr2msghub-pattern] pattern, which sends software-defined-radio (SDR) audio and GPS location to a _shared_ Kafka topic; optionally listens to the _shared_ Kafka topic and publishes a JSON payload to topic `kafka/sdr-audio` on designated MQTT service, e.g. `core-mosquitto`
  - Optional: Converts audio received into text using IBM Watson Speech-to-Text (STT) service.
  - Optional: Parses text into language using IBM Natural Language Understanding (NLU) service.
  
Home-Assistant, including the supervisor, can be installed for an Ubuntu VM or Raspbian RaspberryPi3; run the command below on the VM or Rpi3 (FYI: default login for Raspbian is `pi` with password `raspberry`).
```
wget -qO - ibm.biz/hassio-setup | sudo bash
```
After installation completes, utilize the `Hassio` Add-on Store to include [`dcmartin/hassio-addons`][dcm-addons].  Please refer to each addon's README.md file for details.

#### HA Configuration

The HomeAssistant addons for `sdr2msghub` and `cpu2msghub` provide sample YAML files for configuration.

+ [`sdr2msghub`][sdr2msghub-yaml]
+ [`cpu2msghub`][cpu2msghub-yaml]

# Sample Output

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

[sdr2msghub-yaml]: https://github.com/dcmartin/hassio-addons/blob/master/sdr2msghub/sdr2msghub.yaml
[cpu2msghub-yaml]: https://github.com/dcmartin/hassio-addons/blob/master/cpu2msghub/cpu2msghub.yaml
[commits]: https://github.com/dcmartin/open-horizon/commits/master
[contributors]: https://github.com/dcmartin/open-horizon/graphs/contributors
[dcmartin]: https://github.com/dcmartin
[issue]: https://github.com/dcmartin/open-horizon/issues
[repository]: https://github.com/dcmartin/open-horizon
[watson-nlu]: https://console.bluemix.net/catalog/services/natural-language-understanding
[watson-stt]: https://console.bluemix.net/catalog/services/speech-to-text
[edge-slack]: https://ibm-appsci.slack.com/messages/edge-fabric-users/
[ibm-apikeys]: https://console.bluemix.net/iam/#/apikeys
[docker]: https://www.docker.com/
[ha-addons]: https://github.com/hassio-addons
[hassio-install]: https://www.home-assistant.io/hassio/installation/
[ha-home]: https://www.home-assistant.io/
[ibm-registration]: https://console.bluemix.net/registration/
[edge-fabric]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/getting-started.html
[edge-install]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/adding-devices.html
[macos-install]: https://github.com/open-horizon/anax/releases
[sdr2msghub-pattern]: https://github.com/open-horizon/examples/tree/master/edge/msghub/sdr2msghub
[cpu2msghub-pattern]: https://github.com/open-horizon/examples/tree/master/edge/msghub/cpu2msghub
[sdr2msghub-addon]: https://github.com/dcmartin/hassio-addons/tree/master/sdr2msghub
[cpu2msghub-addon]: https://github.com/dcmartin/hassio-addons/tree/master/cpu2msghub
[setup-readme]: https://github.com/dcmartin/open-horizon/blob/master/setup/README.md
[setupdir]: https://github.com/dcmartin/open-horizon/tree/master/setup
[initdev]: https://github.com/dcmartin/open-horizon/blob/master/setup/init-devices.sh
[oh-github]: http://github.com/open-horizon/
[dcm-addons]: https://github.com/dcmartin/hassio-addons 
[hznsetup]: https://github.com/dcmartin/open-horizon/blob/master/setup/hzn-install.sh
[VirtualBox]: https://www.virtualbox.org/
[edge-slack]: https://ibm-appsci.slack.com/messages/edge-fabric-users/
[ibm-registration]: https://console.bluemix.net/registration/
[ubuntu-image]: http://releases.ubuntu.com/18.04.1/
[raspbian-image]: https://www.raspberrypi.org/downloads/raspbian/
[etcher-io]: https://www.balena.io/etcher/



