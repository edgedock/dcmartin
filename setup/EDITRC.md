# Open Horizon Setup

This repository contains sample scripts to automatically setup nodes for [Open Horizon][open-horizon] as provided in the IBM Cloud.  Detailed [documentation][edge-fabric] for the IBM Cloud Edge Fabric is available on-line.  A Slack [channel][edge-slack] is also available.  You may create and publish your patterns to your organization.  Refer to the [examples][examples] available on GitHub.  Please see DCMARTIN/open-horizon [instructions][dcm-oh].

You will need an [IBM Cloud][ibm-cloud] account and IBM MessageHub credentials available in the Slack [channel][edge-slack].

# Basic Installation

A basic device installation modifies the operating system image boot sequence to install the Open Horizon software.

1. Flash uSD card with operating system image
1. Run `mkconfig.sh` to configure installation defaults:

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
[issue]: https://github.com/dcmartin/open-horizon/setup/issues

[horizon-setup]: https://github.com/dcmartin/open-horizon/blob/master/setup/hzn-install.sh
[hassio-setup]: https://github.com/dcmartin/open-horizon/blob/master/setup/hassio-install.sh

[dcmartin]: https://github.com/dcmartin
[repository]: https://github.com/dcmartin/open-horizon
[basic]: https://github.com/dcmartin/open-horizon/tree/master/setup/BASIC.md
[setup]: https://github.com/dcmartin/open-horizon/tree/master/setup/SETUP.md

[keepchangelog]: http://keepachangelog.com/en/1.0.0/
[edge-slack]: https://ibm-appsci.slack.com/messages/edge-fabric-users/
[ibm-registration]: https://console.bluemix.net/registration/
[open-horizon]: https://github.com/open-horizon
[edge-fabric]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/getting-started.html
[edge-install]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/adding-devices.html
[macos-install]: https://github.com/open-horizon/anax/releases
[examples]: https://github.com/open-horizon/examples
[template]: https://github.com/dcmartin/open-horizon/blob/master/setup/template.json

[ibm-cloud]: http://cloud.ibm.com/
[ibm-cloud-iam]: https://cloud.ibm.com/iam/
