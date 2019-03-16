# `DESIGN.md` - service design

These services are all designed on a common pattern to provide a low-latency response to status requests while providing asynchronous updating.

## 1. `rootfs/`
This pattern begins with the `rootfs/` directory which is copied to the `/` (root directory) of the container; within the `rootfs/usr/bin/` directory are two key files: `run.sh` and `service.sh`; these scripts work together to provide a RESTful status API for the service.  The default API responds to any HTTP `GET` request on the designated port, by default port `80`.

### 1.1 `run.sh` and `service.sh` scripts

1.1.1 The `run.sh` script is the **`CMD`** in every `Dockerfile`.  It collects service metadata from Open Horizon and **exports** a `HZN` environment variable containing that information.

1.1.2 If a script is found with environment `SERVICE_LABEL`name  (e.g. `/usr/bin/cpu.sh`) , `run.sh` invokes it as a background process

1.1.3 The `run.sh` script then invokes the `socat` command to process incoming requests using the `service.sh` script;  waiting (forever) until `socat` exits.

1.1.4 With each invocation`service.sh`checks for status from the _service_ in a well-known location, e.g. `/tmp/cpu.json`, and builds a payload content-type of `application/json` containing the `HZN` metadata as well as the _service_ status.

For example, the `cpu` service returns the following when tested locally:

```
{
  "hzn": {
    "agreementid": "",
    "arch": "",
    "cpus": 0,
    "device_id": "",
    "exchange_url": "",
    "host_ips": [
      ""
    ],
    "organization": "",
    "pattern": "",
    "ram": 0
  },
  "date": 1549930249,
  "service": "cpu",
  "hostname": "cbfe11909de4-172017000002",
  "pid": 20,
  "cpu": {
    "date": 1549930249,
    "log_level": "info",
    "debug": false,
    "period": 60,
    "interval": 1,
    "percent": 22
  }
}
```

**NOTE:** The environment variables defined by the Open Horizon pattern are _not_ defined when testing a container stand-alone.  

### 1.2 `<service>.sh` script

Each service provides a script with its name (e.g. `cpu.sh`) and that script performs asynchrous updates and writes status updates to its well-known location (e.g. `/tmp/cpu.json`).  The _service_ script should never exit.  Most services include a periodicity value, e.g. `CPU_PERIOD`, indicating how often the service should update its status.

### 1.2.1 example `cpu.sh`

The `cpu.sh` script example demonstrates this pattern with a never-ending `while true; do` loop, initiating its status with its `CONFIG` information from the `userInput` provided, and polling the `/proc/stat` attribute of the `cpu` on a default `CPU_PERIOD` of `60` seconds (n.b that's belt-and-suspenders, BTW).  The calculation of `SLEEP` time is based on an expectation of non-zero latency in performing the system cpu process inspection.

```
#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

if [ -z "${CPU_INTERVAL}" ]; then CPU_INTERVAL=1; fi
if [ -z "${CPU_PERIOD}" ]; then CPU_PERIOD=60; fi

CONFIG='{"date":'$(date +%s)',"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"period":'${CPU_PERIOD}',"interval":'${CPU_INTERVAL}'}'
echo "${CONFIG}" > ${TMPDIR}/${SERVICE_LABEL}.json

while true; do
  DATE=$(date +%s)
  OUTPUT="${CONFIG}"

  # https://github.com/Leo-G/DevopsWiki/wiki/How-Linux-CPU-Usage-Time-and-Percentage-is-calculated
  RAW=$(grep -iE '^cpu ' /proc/stat)
  CT1=$(echo "${RAW}" | awk '{ printf("%d",$2+$3+$4+$5+$6+$7+$8+$9) }')
  CI1=$(echo "${RAW}" | awk '{ printf("%d",$5+$6) }')
  sleep ${CPU_INTERVAL}
  RAW=$(grep -iE '^cpu ' /proc/stat)
  CT2=$(echo "${RAW}" | awk '{ printf("%d",$2+$3+$4+$5+$6+$7+$8+$9) }')
  CI2=$(echo "${RAW}" | awk '{ printf("%d",$5+$6) }')

  PERCENT=$(echo "scale=2; 100 * (($CT2 - $CT1) - ($CI2 - $CI1)) / ($CT2 - $CT1)" | bc -l)
  if [ -z "${PERCENT}" ]; then PERCENT=null; fi
  OUTPUT=$(echo "${OUTPUT}" | jq '.percent='${PERCENT})

  # output
  echo "${OUTPUT}" | jq '.date='$(date +%s) > "${TMPDIR}/$$"
  mv -f "${TMPDIR}/$$" "${TMPDIR}/${SERVICE_LABEL}.json"
  # wait for ..
  SLEEP=$((CPU_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SLEEP} > 0 ]; then
    sleep ${SLEEP}
  fi
done
``` 

### 1.2.2 example `yolo2msghub.sh`

A slightly more complicated script that combines multiple `requiredServices`, notably `hal`, `cpu`,  `wan`, and `yolo`, to provide a composite service includes all the status outputs.  In this example, each of the sub-services is processed to only include the payload service content, 

```
#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

JSON='[{"name": "yolo", "url": "http://yolo" },{"name": "hal", "url": "http://hal" },{"name":"cpu","url":"http://cpu"},{"name":"wan","url":"http://wan"}]'

# OPTIONS
OPTIONS='{"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"services":'${JSON}',"period":'${YOLO2MSGHUB_PERIOD}'}'
echo "${OPTIONS}" > ${TMPDIR}/${SERVICE_LABEL}.json

# make topic
TOPIC=$(curl -sSL -H 'Content-Type: application/json' -H "X-Auth-Token: ${YOLO2MSGHUB_APIKEY}" "${YOLO2MSGHUB_ADMIN_URL}/admin/topics" -d '{"name":"'${SERVICE_LABEL}'"}')
if [ "$(echo "${TOPIC}" | jq '.errorCode!=null')" == 'true' ]; then
  echo "+++ WARN $0 $$ -- topic ${SERVICE_LABEL} message:" $(echo "${TOPIC}" | jq -r '.errorMessage') &> /dev/stderr
fi

# Horizon CONFIG
if [ -z "${HZN}" ]; then
  echo "*** ERROR $0 $$ -- environment HZN is unset; exiting" &> /dev/stderr
  exit 1
fi

# do all SERVICES forever
SERVICES=$(echo "${JSON}" | jq -r '.[]|.name')
while true; do
  DATE=$(date +%s)
  # make output
  OUTPUT="${OPTIONS}"
  for S in $SERVICES; do
    URL=$(echo "${JSON}" | jq -r '.[]|select(.name=="'${S}'").url')
    if [ ! -z "${URL}" ]; then
      OUT=$(curl -sSL "${URL}" 2> /dev/null | jq '.'"${S}")
    fi
    if [ -z "${OUT:-}" ]; then
      OUT='null'
    fi
    OUTPUT=$(echo "${OUTPUT:-}" | jq '.'"${S}"'='"${OUT}")
  done
  OUTPUT=$(echo "${OUTPUT}" | jq '.date='$(date +%s))

  echo "${OUTPUT}" > "${TMPDIR}/$$"
  mv -f "${TMPDIR}/$$" "${TMPDIR}/${SERVICE_LABEL}.json"

  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- output: ${OUTPUT}" &> /dev/stderr; fi

  # send via kafka
  if [ $(command -v kafkacat) ] && [ ! -z "${YOLO2MSGHUB_BROKER}" ] && [ ! -z "${YOLO2MSGHUB_APIKEY}" ]; then
    echo "${HZN}" | jq -c '.'${SERVICE_LABEL}'='"${OUTPUT}" \
      | kafkacat \
          -P \
          -b "${YOLO2MSGHUB_BROKER}" \
          -X api.version.request=true \
          -X security.protocol=sasl_ssl \
          -X sasl.mechanisms=PLAIN \
          -X sasl.username=${YOLO2MSGHUB_APIKEY:0:16}\
          -X sasl.password="${YOLO2MSGHUB_APIKEY:16}" \
          -t "${SERVICE_LABEL}"
  else
    echo "+++ WARN $0 $$ -- kafka invalid" &> /dev/stderr
  fi
  # wait for ..
  SLEEP=$((YOLO2MSGHUB_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SLEEP} > 0 ]; then
    sleep ${SLEEP}
  fi
done
```

##### Example payload

```
{
  "hzn": {
    "agreementid": "",
    "arch": "",
    "cpus": 0,
    "device_id": "",
    "exchange_url": "",
    "host_ips": [
      ""
    ],
    "organization": "",
    "pattern": "",
    "ram": 0
  },
  "date": 1549934160,
  "service": "yolo2msghub",
  "hostname": "9b1c65c1768d-172017000004",
  "pid": 21,
  "yolo2msghub": {
    "log_level": "info",
    "debug": false,
    "services": [
      {
        "name": "yolo",
        "url": "http://yolo"
      },
      {
        "name": "hal",
        "url": "http://hal"
      },
      {
        "name": "cpu",
        "url": "http://cpu"
      },
      {
        "name": "wan",
        "url": "http://wan"
      }
    ],
    "period": 30
  }
}
```

# Changelog & Releases

Releases are based on [Semantic Versioning][semver], and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.
[semver]: https://semver.org/


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
