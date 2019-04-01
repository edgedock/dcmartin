# `OLD.md` - Old examples

The Open Horizon [page on github.com][open-horizon-github] provides open-source code for components and examples.  There are two examples currently available for use during the alpha phase. These examples include:

[open-horizon-github]: http://github.com/open-horizon/

+ Patterns
  + cpu2msghub - capture CPU and GPS data and to send Kafka 
  + sdr2msghub - capture audio from FM radio broadcasts and send to Kafka
+ Services
  + cpu - return CPU usage percentage (0.0-100.0]
  + gps - return GPS coordinates - statically defined, captured from device, or Internet IP derived
  + sdr - capture FM radio broadcasts
  + _network_ - **out-of-scope**
  + _pi3-streamer_ - **out-of-scope**
  + _weatherstation_ - **out-of-scope**

[edge-fabric-staging-docs]: https://github.ibm.com/Edge-Fabric/staging-docs

This CI/CD process was developed based on the existing example patterns and services; only functional patterns and services available in the `IBM` organization were utilized; other examples were not utilized.  The [documentation][edge-fabric-staging-docs] for these examples provided guidance and insight on the requirements for the build process; no documentation was available for any existing release process or build automation.
## `examples` Repository

The [`examples`][open-horizon-examples-github] repository provides a breakdown into three subdirectories:
  
  + `edge/` - source code for Edge services
  + `tools/` - Alpine LINUX package for `kafkacat`
  + `cloud/` - source code for Cloud services

The `tools/` and `cloud/` components are out-of-scope.  The `edge/` subdirectory contains subdirectories for documentation (`doc/`), as well as for the following:
  
  + `msghub` - source code for services utilizing Kafka; in subdirectories: `cpu2msghub/` and `sdr2msghub/`
  + `services` - source code for other services
  + `wiotp` - Watson IoT Platform (**out-of-scope**)

Of the two Kafka-based services, the `cpu2msghub` service is simpler and was selected as the prototype for subsequent build process and release management automation for continuous integration and continuous delivery.

## `edge/msghub/cpu2msghub`
 
 This subdirectory contains the source code and build files for the `cpu2msghub` _service_.   The `cpu2msghub` _service_ requires two additional services form the `IBM` organization, nominally _cpu_ and _gps_,  identified by their sets of  `org`,`url`,`arch`, and `version`.
 
 The build process includes one `Makefile` with targets for:
 
 + `build` - builds the container including copy of Kafka APK
 + `run` - runs the container (locally) using a static set of `docker run` options
 + `check` - checks the output of the locally run container
 + `stop` - stops the locally run container
 + `hznbuild` - fetches dependencies for _cpu_ and _gps_ from within repository to `dev` environment
 + `hznstart`- starts the service (and required services) in `dev` environment
 + `hznstop` - stops the service (and required services) in `dev` environment
 + `publish-service` - publishes the service into the exchange
 + `publish-pattern` - publishes the pattern into the exchange
 + `clean` - removes build artifacts
 
There is no TravisCI build automation.  Review of the build process identified several challenges to automation.  The targets depend on extensive use of environment variables. These variables are statically defined in the `Makefile`, including the pattern _name_ (i.e. `cpu2msghub`), its version (`CPU2MSGHUB_VERSION`), as well as the versions of its required services (`CPU_VERSION` and `GPS_VERSION`).