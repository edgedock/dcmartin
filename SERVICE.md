# `SERVICE.md` - _Service_ build process automation
Services are defined within a directory hierarchy of this [repository][repository].  Services include:

+ [`cpu`][cpu-service] - provide CPU usage as percentage (0-100)
+ [`wan`][wan-service] - provide Wide-Area-Network information
+ [`hal`][hal-service] - provide Hardware-Abstraction-Layer information
+ [`yolo`][yolo-service] - recognize `person` and other entities from image
+ [`yolo2masgub`][yolo2msghub-service] - transmit `yolo`, `hal`, `cpu`, and `wan` information to Kafka
+ [`motion2mqtt`][motion2mqtt-service] - transmit motion detected images to MQTT

While all services in this repository share a common design (see [`DESIGN.md`][design-md]), that design is independent _service_ build automation process.  The build automation process is futher described in [`BUILD.md`][build-md].

# 1. Service `make` targets

The build process for each service is identical.  As state above, the _default_ `make` target is to `build`, `run`, and `check` the  service.  These targets only support a single Docker container image do _not_ include the required services.  There are additional `make` targets for services; these targets require the installation of the Open Horizon command-line-tool: `hzn`

Open Horizon is available for a variety of architectures and platforms.  For more information please refer to the [`setup/README.md`][setup-readme-md].

+ `service-start` - starts the services and required services
+ `service-stop` - stops the services and required services
+ `service-publish` - publishes the service in the exchange
+ `service-verify` - verifies the published service in the exchange

## 4.1 `service-start`

This target will ensure that the service is built and then initiate the service using the `hzn` CLI commands.  All services specified, including required services, will also be initiated and appropriate virtual private networks will be established.  Please refer to the Open Horizon documentation for more details on the `hzn` command-line-interface.

## 4.2 `service-stop`

This target will stop the services and all required services initiated using the `service-start` target.

## 4.3 `service-publish`

This target will publish the service to the exchange, checking that appropriate modifications of the service `version` and its required services have been made.

## 4.4 `service-verify`

This target will verify that the service is published into the exchange.

[docker-start]: https://www.docker.com/get-started
[make-md]: https://github.com/dcmartin/open-horizon/blob/master/MAKE.md
[makevars-md]: https://github.com/dcmartin/open-horizon/blob/master/MAKEVARS.md
[setup-readme-md]: https://github.com/dcmartin/open-horizon/blob/master/setup/README.md

[travis-md]: https://github.com/dcmartin/open-horizon/blob/master/TRAVIS.md
[design-md]: https://github.com/dcmartin/open-horizon/blob/master/DESIGN.md
[travis-yaml]: https://github.com/dcmartin/open-horizon/blob/master/.travis.yml
[travis-ci]: https://travis-ci.org/
[build-pattern-video]: https://youtu.be/cv_rOdxXidA

[yolo-service]: https://github.com/dcmartin/open-horizon/tree/master/yolo/README.md
[hal-service]: https://github.com/dcmartin/open-horizon/tree/master/hal/README.md
[cpu-service]: https://github.com/dcmartin/open-horizon/tree/master/cpu/README.md
[wan-service]: https://github.com/dcmartin/open-horizon/tree/master/wan/README.md
[yolo2msghub-service]: https://github.com/dcmartin/open-horizon/tree/master/yolo2msghub/README.md
[motion2mqtt-service]: https://github.com/dcmartin/open-horizon/tree/master/motion2mqtt/README.md

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
[edge-slack]: https://ibm-cloudplatform.slack.com/messages/edge-fabric-users/
[ibm-apikeys]: https://console.bluemix.net/iam/#/apikeys
[ibm-registration]: https://console.bluemix.net/registration/
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: https://github.com/dcmartin/open-horizon/blob/master/setup/README.md
