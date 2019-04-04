# `TERMINOLOGY.md` - Lexicon of important terms

It is important to know the lexicon and defintions for key _terms_ used in this document.  Docker provides [software-defined virtual computing environments][why-docker].

## 1 - Docker
The key terms when discussing Docker are:

+ _[container][whatis-container]_ - a software-defined LINUX operating environment
+ _image_ - a Docker container package file
+  _tag_ - an identifier for a Docker container
+ _repository_ - a SaaS that store and retrieve Docker images by _tag_
+ _namespace_ - an identifier for a _repository_ collection, authentication, and authorization
+ _registry_ - a SaaS for _namespace_ and _repository_ functions

[why-docker]: https://www.docker.com/why-docker
[whatis-container]: https://www.docker.com/resources/what-container

## 2 - Open Horizon
The Open Horizon edge fabric is based on Docker

+ _device_ - a Docker-compatible computing environment, e.g. [RaspberryPi][whatis-raspberrypi], [VirtualBox][whatis-virtualbox] virtual machine, nVidia [Jetson][whatis-jetson]
+ _node_ - a _device_ with Open Horizon edge fabric and exchange credentials
+ _service_ - a composition of one or more Docker containers, including _required_ services
+ _pattern_ - a composition of one or more services which may be deployed to a node
+ _exchange_ - a SaaS for communications, command, and control of nodes
+ _organization_ - a credentialed identifier in the exchange
+ _agreement_ - documentation of a node service registration

[whatis-virtualbox]: https://www.virtualbox.org/
[whatis-jetson]: https://www.nvidia.com/en-us/autonomous-machines/embedded-systems-dev-kits-modules/
[whatis-raspberrypi]: https://www.raspberrypi.org/help/what-%20is-a-raspberry-pi/

## 2.1 - _node_
Devices with Docker and the Open Horizon software installed and configured properly.  For more information on setting up a device please refer to [`setup/README.md`][setup-readme-md].

[setup-readme-md]: https://github.com/dcmartin/open-horizon/blob/master/setup/README.md

## 2.2 - _service_
The Open Horizon edge fabric _service_ is an specification of Docker containers with supporting information.  Each service is defined in a JSON configuration file that includes identification, description, variables, deployment, and composition information.  For more information on building services, please refer to [`SERVICE.md`][service-md]

## 2.3 - _pattern_
A _pattern_ is a composition of one or more _service_ into a package which can be deployed to a _node_.   Patterns are identified by a unique **name** in the exchange per _organization_.

## 2.4 - _exchange_
An _exchange_ is a network-service that provides communication, command, control, and management functionality for _node_, _service_, and _pattern_.  Access to an exchange requires credentials for a registered _organization_

## 2.5 - _organization_
An _organization_ is a collection of exchange artifacts (e.g. node, service, pattern) and associated users with access control to those artifacts.

## 2.6 - _agreement_
Documentation of a successful pattern registration service configuration; there is one agreement per service.


