# Open Horizon Setup

This repository contains sample scripts to automatically setup nodes for [Open Horizon][open-horizon] as provided in the IBM Cloud.  Detailed [documentation][edge-fabric] for the IBM Cloud Edge Fabric is available on-line.  A Slack [channel][edge-slack] is also available.  You may create and publish your patterns to your organization.  Refer to the [examples][examples] available on GitHub.

You will need an [IBM Cloud][ibm-cloud] account and IBM MessageHub credentials available in the Slack [channel][edge-slack].

# System Installation

System level installation modifies the operating system image boot sequence to install the Open Horizon software.  This technique is suitable for replication.  Please refer to [these][editrc] instructions.

# Network Installation

Installations can be performed over the network when devices are discovered.  This technique is suitable for early-adopters. Please refer to [these][setup] instructions.

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

David C Martin (github@dcmartin.com)

[dcmartin]: https://github.com/dcmartin
[repository]: https://github.com/dcmartin/open-horizon
[releases]: https://github.com/dcmartin/open-horizon/setup/releases
[issue]: https://github.com/dcmartin/open-horizon/setup/issues
[commits]: https://github.com/dcmartin/open-horizon/setup/commits/master
[contributors]: https://github.com/dcmartin/open-horizon/setup/graphs/contributors
[open-horizon]: https://github.com/open-horizon
[edge-fabric]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/getting-started.html
[edge-install]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/adding-devices.html
[edge-slack]: https://ibm-appsci.slack.com/messages/edge-fabric-users/
[examples]: https://github.com/open-horizon/examples
[ibm-cloud]: http://cloud.ibm.com/
[editrc]: https://github.com/dcmartin/open-horizon/tree/master/setup/EDITRC.md
[setup]: https://github.com/dcmartin/open-horizon/tree/master/setup/SETUP.md
[keepchangelog]: http://keepachangelog.com/en/1.0.0/
