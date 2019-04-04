# Travis configuration

[Travis][travis-ci] provides automated execution of tasks in the continuous integration process.  Status of this repository is indicated by the following badge:

[![Build Status](https://travis-ci.org/dcmartin/open-horizon.svg?branch=master)](https://travis-ci.org/dcmartin/open-horizon)

[travis-ci]: https://travis-ci.org/

# Build automation

These tasks are defined in a YAML file for the GIT repository; this [repository][repository] has a [`.travis.yml`][travis-yaml] configuration file.

[travis-yaml]: https://github.com/dcmartin/open-horizon/blob/master/.travis.yml

```
sudo: true
language: c
services: docker
dist: bionic 
branches:
  only:
    - master
env:
  - BUILD_ARCH=amd64 ORG=dcmartin@us.ibm.com URL=com.github.dcmartin.open-horizon TAG=beta
addons:
  apt:
    update: true
    sources:
    - sourceline: deb [arch=amd64,arm,arm64] http://pkg.bluehorizon.network/linux/ubuntu xenial-updates main
      key_url: 'http://pkg.bluehorizon.network/bluehorizon.network-public.key'
    packages:
    - make
    - curl
    - jq
    - ca-certificates
    - gnupg
before_install:
before_script:
  - if [ "${TRAVIS_PULL_REQUEST}" = "false" ]; then echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_ID}" --password-stdin; echo "${IBMCLOUD_APIKEY}" > APIKEY; echo "${YOLO2MSGHUB_APIKEY}" > yolo2msghub/YOLO2MSGHUB_APIKEY; if [ ! -z "${TAG}" ]; then echo "${TAG}" > TAG; fi; else if [ ! -z "${TAG}" ]; then echo "${TAG}" > TAG; fi; fi
script:
  - make build
after_success:
  - make push
```

The configuration provides environmental (`env`) controls for the build process, including installation of software (`apt`).  A virtual machine spawned Docker container executes the corresponding tasks; the container environment limits the capabilities to `build`, `push`, and `publish` targets.  See [MAKE.md][make-md] for more information.

[make-md]: https://github.com/dcmartin/open-horizon/edit/master/doc/MAKE.md
[travis-md]: https://github.com/dcmartin/open-horizon/edit/master/doc/TRAVIS.md
[travis-yaml]: https://github.com/dcmartin/open-horizon/edit/master/.travis.yml

# Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[dcmartin]: https://github.com/dcmartin
[edge-fabric]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/getting-started.html
[edge-install]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/adding-devices.html
[edge-slack]: https://ibm-appsci.slack.com/messages/edge-fabric-users/
[ibm-apikeys]: https://console.bluemix.net/iam/#/apikeys
[ibm-registration]: https://console.bluemix.net/registration/
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: https://github.com/dcmartin/open-horizon/blob/master/setup/README.md


[amd64-layers-shield]: https://images.microbadger.com/badges/image/dcmartin/plex-amd64.svg
[amd64-microbadger]: https://microbadger.com/images/dcmartin/plex-amd64
[armhf-microbadger]: https://microbadger.com/images/dcmartin/plex-armhf
[armhf-layers-shield]: https://images.microbadger.com/badges/image/dcmartin/plex-armhf.svg

[amd64-version-shield]: https://images.microbadger.com/badges/version/dcmartin/plex-amd64.svg
[amd64-arch-shield]: https://img.shields.io/badge/architecture-amd64-blue.svg
[amd64-dockerhub]: https://hub.docker.com/r/dcmartin/plex-amd64
[amd64-pulls-shield]: https://img.shields.io/docker/pulls/dcmartin/plex-amd64.svg
[armhf-arch-shield]: https://img.shields.io/badge/architecture-armhf-blue.svg
[armhf-dockerhub]: https://hub.docker.com/r/dcmartin/plex-armhf
[armhf-pulls-shield]: https://img.shields.io/docker/pulls/dcmartin/plex-armhf.svg
[armhf-version-shield]: https://images.microbadger.com/badges/version/dcmartin/plex-armhf.svg
[i386-arch-shield]: https://img.shields.io/badge/architecture-i386-blue.svg
[i386-dockerhub]: https://hub.docker.com/r/dcmartin/plex-i386
[i386-layers-shield]: https://images.microbadger.com/badges/image/dcmartin/plex-i386.svg
[i386-microbadger]: https://microbadger.com/images/dcmartin/plex-i386
[i386-pulls-shield]: https://img.shields.io/docker/pulls/dcmartin/plex-i386.svg
[i386-version-shield]: https://images.microbadger.com/badges/version/dcmartin/plex-i386.svg
