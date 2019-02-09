# `make` - building the software

# Building

The **make** command by **default** performs `build`,`run`,`check`; available targets:

+ `build` - build container using `build.json` and `service.json`
+ `run` - run container locally; map `ports` as in `service.json`
+ `check` - checks the service locally on mapped port
+ `test` - tests the service output using `test-{service}.sh` for conformant payload
+ `push` - push the container to Docker registry; __requires__ `DOCKER_ID` and `docker login`
+ `publish` - publish service to _exchange_; __requires__ `hzn` CLI
+ `verify` - verify service on exchange; __requires__ `hzn` CLI
+ `start` - intiates service and required services locally; __requires__ `hzn` CLI
+ `clean` - remove all generated artefacts, including running containers and images
+  `distclean` - remove all residuals, including variable and key files

### `test`
This target may be used against the local container, the local service (n.b. see `start` target), or any node running the _pattern_.  The service is accessed on its external `port` without mapping.  The payload is processed into a JSON type structure, including _object_, _array_, _number_, _string_.

```
{
  "hzn": { "agreementid": "string", "arch": "string", "cpus": "number", "device_id": "string", "exchange_url": "string", "host_ips": "array", "organization": "string", "pattern": "string", "ram": "number" },
  "date": "number",
  "service": "string",
  "hostname": "string",
  "yolo2msghub": {
    "log_level": "string",
    "debug": "boolean",
    "services": "array",
    "period": "number",
    "yolo": { "log_level": "string", "debug": "boolean", "date": "number", "period": "number", "entity": "string", "time": "number", "count": "number", "width": "number", "height": "number", "scale": "string", "mock": "string", "image": "string" },
    "hal": { "date": "number", "log_level": "string", "debug": "boolean", "period": "number", "lshw": { "id": "string", "class": "string", "claimed": "boolean", "description": "string", "product": "string", "serial": "string", "width": "number", "children": "array" }, "lsusb": "array", "lscpu": { "Architecture": "string", "Byte_Order": "string", "CPUs": "string", "On_line_CPUs_list": "string", "Threads_per_core": "string", "Cores_per_socket": "string", "Sockets": "string", "Vendor_ID": "string", "Model": "string", "Model_name": "string", "Stepping": "string", "CPU_max_MHz": "string", "CPU_min_MHz": "string", "BogoMIPS": "string", "Flags": "string" }, "lspci": "array", "lsblk": "array" },
    "cpu": { "date": "number", "log_level": "string", "debug": "boolean", "period": "number", "interval": "number", "percent": "number" },
    "wan": { "date": "number", "log_level": "string", "debug": "boolean", "period": "number", "speedtest": "null" },
    "date": "number"
  }
}

```
### `start`
The `start` target will initiate the _pattern_ with all required _services_; it depends on `publish` and `verify`
```
% make start
...
export HZN_EXCHANGE_URL=https://alpha.edge-fabric.com/v1/ && hzn dev service start -d test/
Service project /home/dcmartin/GIT/open-horizon/yolo2msghub/test verified.
Service project /home/dcmartin/GIT/open-horizon/yolo2msghub/test verified.
Start service: service(s) hal with instance id prefix com.github.dcmartin.open-horizon.hal_0.0.1_089fdddf-2206-4421-a84a-24b8ce95a3d7
Running service.
Start service: service(s) wan with instance id prefix com.github.dcmartin.open-horizon.wan_0.0.1_6adc547b-941f-46de-b189-213d9d98fe3a
Running service.
Start service: service(s) yolo with instance id prefix com.github.dcmartin.open-horizon.yolo_0.0.1_6e7c975a-ac22-4f8c-bad2-d6b97d2b20ec
Running service.
Start service: service(s) yolo2msghub with instance id prefix d1f279369ee592e401daadf249ae4a1196c42a548d3533fda6d7e240c9f483e1
Running service.
```
## Publishing

The `pattern` target will publish the pattern in the exchange.  The [`service.json`][service-json] file must be changed prior.

### `pattern`
```
% make pattern
...
export HZN_EXCHANGE_URL=https://alpha.edge-fabric.com/v1/ && hzn exchange pattern publish -o "dcmartin@us.ibm.com" -u iamapikey:{apikey} -f pattern.json -p yolo2msghub -k {private-key-file} -K {public-key-file}
Updating yolo2msghub in the exchange...
Storing IBM-6d570b1519a1030ea94879bbe827db0616b9f554-public.pem with the pattern in the exchange...
```
# Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[userinput]: https://github.com/dcmartin/open-horizon/blob/master/yolo2msghub/userinput.json
[service-json]: https://github.com/dcmartin/open-horizon/blob/master/yolo2msghub/service.json
[build-json]: https://github.com/dcmartin/open-horizon/blob/master/yolo2msghub/build.json
[dockerfile]: https://github.com/dcmartin/open-horizon/blob/master/yolo2msghub/Dockerfile
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
