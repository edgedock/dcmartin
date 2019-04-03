# `DESIGN.md` - service design


# Introduction
These services are all designed on a common pattern to provide a low-latency response to status requests with providing asynchronous updates.  The principle components are `run.sh` and `service.sh`.   There is one implementation of each script with a copy in every _base_ service (e.g. `base-ubuntu`).

# A. `run.sh`
The elemental component of all services in this repository is the `run.sh` script; for example:

+ [`open-horizon/base-ubuntu/rootfs/usr/bin/run.sh`][base-ubuntu-run-sh]

This script is defined as the initial command in the [`Dockerfile`][base-ubuntu-dockerfile] and is executed when the container starts; the container stops when the script exits; the script is designed to never exit.

[base-ubuntu-run-sh]: https://github.com/dcmartin/open-horizon/blob/master/base-ubuntu/rootfs/usr/bin/run.sh
[base-ubuntu-dockerfile]: https://github.com/dcmartin/open-horizon/blob/master/base-ubuntu/Dockerfile

## A.1 `hzn-tools.sh`
There are library functions provided in the `hzn-tools.sh` script; they include:

### &#128073; `hzn_init()`

Initializes a data structure to record the `HZN`  values (see below). If the environment variable `HZN_EXCHANGE_APIKEY` is defined and the pattern is found in the exchange, the  details for the pattern will be downloaded and added to the status.

### &#128073; `hzn_config()`
Once the service has been initialized the `hzn_config()` function returns the JSON configuration

## Step 1 - Initialize status
When a service container is instantiated on a node it is provided with a set of environment variables by the Open Horizon edge fabric. 

**NOTE:** The environment variables defined by the Open Horizon pattern are _not_ defined when testing a container stand-alone.  

1. `HZN_ORGANIZATION` - the organization for the service (e.g. `dcmartin@us.ibm.com`)
2. `HZN_EXCHANGE_URL` - the exchange host URL
3. `HZN_AGREEMENTID` - the agreement identifier
4. `HZN_ARCH`- system architecture (e.g. `arm`, `arm64`, `amd64`, `ppc64le`)
5. `HZN_CPUS` - CPU cores requested
6. `HZN_PATTERN` - the name of the pattern (e.g. `dcmartin@us.ibm.com/yolo2-msghub`)
7. `HZN_HOST_IPS` - the TCP/IP addresses of the host
8. `HZN_RAM` - RAM kilobytes requested

```
# initialize horizon
if [ -z "$(hzn_init)" ]; then
  echo "*** ERROR$0 $$ -- horizon initilization failure; exiting" &> /dev/stderr
  exit 1
else
  export HZN=$(hzn_config)
fi
```

## Step 2 - Invoke the _service_ script
The script detects if an executable program exists with the name of the service; if it does exist, the executable is invoked as a background process.  The `SERVICE_LABEL` is defined as an environment variable in the `service.json` configuration template.

```
# label
if [ ! -z "${SERVICE_LABEL:-}" ]; then
  CMD=$(command -v "${SERVICE_LABEL:-}.sh")
  if [ ! -z "${CMD}" ]; then
    ${CMD} &
  fi
else
  echo "+++ WARN $0 $$ -- executable ${SERVICE_LABEL:-}.sh not found" &> /dev/stderr
fi
```

For example, in the `deployment` section of the the `cpu/service.json`configuration template the `SERVICE_LABEL` is set to `cpu`:

```
  "deployment": {
    "services": {
      "cpu": {
        "environment": [ "SERVICE_LABEL=cpu", "SERVICE_VERSION=0.0.3" ],
        "image": null,
        "privileged": true,
        "binds": null,
        "devices": null,
        "specific_ports": null
      }
    }
  }
```

## Step 3 - Respond to HTTP
The last section of the `run.sh` script utilizes the `socat` utility to listen on a designated port and respond by invoking the `service.sh` script.  The `LOCALHOST_PORT` environment variable may be specified to over-ride the default port `80`.

```
# port
if [ -z "${LOCALHOST_PORT:-}" ]; then
  LOCALHOST_PORT=80
else
  echo "+++ WARN: using localhost port ${LOCALHOST_PORT}" &> /dev/stderr
fi

# start listening
socat TCP4-LISTEN:${LOCALHOST_PORT},fork EXEC:service.sh
```

# B. `service.sh`
This script processes the output from the `SERVICE_LABEL` script invoked as a background process (see _Step 2_ from above) and produces an HTTP-compliant response.  With each invocation`service.sh`checks for status from the _service_ and builds a payload content-type of `application/json`.

## B.1 `service-tools.sh`
There are a set of support functions to control the `service.sh` script output:

### &#128073; `service_init()`
Initializes the service.

### &#128073; `service_config()`
Configures the service according to the supplied JSON argument

### &#128073; `service_update()`
Updates the service status; this function is called by the specific `SERVICE_LABEL` script.

### &#128073; `service_output()`
Provides the service status in the provided file.

# C. _service_`.sh`

## Example: `cpu.sh`

```
#!/bin/bash
  
# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh

###
### initialize
###

## initialize horizon
hzn_init

## configure service

CONFIG='{"log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-false}',"period":"'${CPU_PERIOD}'","interval":"'${CPU_INTERVAL}'","services":'"${SERVICES:-null}"'}'

## initialize servive
service_init ${CONFIG}

###
### MAIN
###

## create initial output
OUTPUT_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$.json"
echo '{"date":'$(date +%s)'}' > "${OUTPUT_FILE}"
service_update "${OUTPUT_FILE}"

# iterate forever
while true; do
  DATE=$(date +%s)
  OUTPUT=$(jq -c '.' "${OUTPUT_FILE}")

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
  echo "${OUTPUT}" | jq '.date='$(date +%s) > "${OUTPUT_FILE}"
  # update service
  service_update "${OUTPUT_FILE}"
  # wait for ..
  SECONDS=$((CPU_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi
done
``` 

For example, the `cpu` service returns the following when executed locally:

```
{
  "cpu": {
    "date": 1554262315,
    "percent": 0.73
  },
  "date": 1554262314,
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
    "ram": 0,
    "pattern": null
  },
  "config": {
    "log_level": "info",
    "debug": false,
    "period": "60",
    "interval": "1",
    "services": null
  },
  "service": {
    "label": "cpu",
    "version": "0.0.3"
  }
}
```


## Example: `yolo2msghub.sh`

A slightly more complicated script that combines multiple `requiredServices`, notably `hal`, `cpu`,  `wan`, and `yolo`, to provide a composite service includes all the status outputs.  In this example, each of the sub-services is processed to only include the payload service content, 

```
#!/bin/bash
  
# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh

###
### initialization
###

## initialize horizon
hzn_init

## configure service

SERVICES='[{"name": "hal", "url": "http://hal" },{"name":"cpu","url":"http://cpu"},{"name":"wan","url":"http://wan"}]'
CONFIG='{"date":'$(date +%s)',"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"services":'${SERVICES}',"period":'${YOLO2MSGHUB_PERIOD}'}'
echo "${CONFIG}" > ${TMPDIR}/${SERVICE_LABEL}.json

## initialize servive
service_init ${CONFIG}

###
### MAIN
###

## initial output
OUTPUT_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$.json"
echo '{"date":'$(date +%s)'}' > "${OUTPUT_FILE}"
service_update "${OUTPUT_FILE}"

# make topic
TOPIC=$(curl -sSL -H 'Content-Type: application/json' -H "X-Auth-Token: ${YOLO2MSGHUB_APIKEY}" "${YOLO2MSGHUB_ADMIN_URL}/admin/topics" -d '{"name":"'${SERVICE_LABEL}'"}')
if [ "$(echo "${TOPIC}" | jq '.errorCode!=null')" == 'true' ]; then
  echo "+++ WARN $0 $$ -- topic ${SERVICE_LABEL} message:" $(echo "${TOPIC}" | jq -r '.errorMessage') &> /dev/stderr
fi

## configure service we're sending
API='yolo'
URL="http://${API}"

while true; do
  DATE=$(date +%s)

  # get service
  PAYLOAD=$(mktemp)
  curl -sSL "${URL}" -o ${PAYLOAD} 2> /dev/null
  echo '{"date":'$(date +%s)',"'${API}'":' > ${OUTPUT_FILE}
  if [ -s "${PAYLOAD}" ]; then
    jq '.'"${API}" ${PAYLOAD} >> ${OUTPUT_FILE}
  else
    echo 'null' >> ${OUTPUT_FILE}
  fi
  rm -f ${PAYLOAD}
  echo '}' >> ${OUTPUT_FILE}
  # output
  service_update "${OUTPUT_FILE}"

  # send via kafka
  if [ $(command -v kafkacat) ] && [ ! -z "${YOLO2MSGHUB_BROKER}" ] && [ ! -z "${YOLO2MSGHUB_APIKEY}" ]; then
      PAYLOAD=$(mktemp)
      echo "${HZN:-}" > ${PAYLOAD}
      PAYLOAD_DATA=$(mktemp)
      echo '{"date":'$(date +%s)',"'${SERVICE_LABEL}'":' > ${PAYLOAD_DATA}
      cat "${TMPDIR}/${SERVICE_LABEL}.json" >> ${PAYLOAD_DATA}
      echo '}' >> ${PAYLOAD_DATA}
      jq -s add ${PAYLOAD} ${PAYLOAD_DATA} | jq -c '.' > ${PAYLOAD}.$$ && mv -f ${PAYLOAD}.$$ ${PAYLOAD}
      if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- payload:" $(jq -c '.yolo2msghub.yolo|.image=null' ${PAYLOAD}) &> /dev/stderr; fi
      kafkacat "${PAYLOAD}" \
          -P \
          -b "${YOLO2MSGHUB_BROKER}" \
          -X api.version.request=true \
          -X security.protocol=sasl_ssl \
          -X sasl.mechanisms=PLAIN \
          -X sasl.username=${YOLO2MSGHUB_APIKEY:0:16}\
          -X sasl.password="${YOLO2MSGHUB_APIKEY:16}" \
          -t "${SERVICE_LABEL}"
      rm -f ${PAYLOAD} ${PAYLOAD_DATA}
  else
    echo "+++ WARN $0 $$ -- kafka invalid" &> /dev/stderr
  fi

  # wait for ..
  SECONDS=$((YOLO2MSGHUB_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi
done
```

##### Example payload

```
{
  "wan": {
    "date": 1554262927,
    "speedtest": {
      "client": {
        "rating": "0",
        "loggedin": "0",
        "isprating": "3.7",
        "ispdlavg": "0",
        "ip": "67.169.35.196",
        "isp": "Comcast Cable",
        "lon": "-121.7875",
        "ispulavg": "0",
        "country": "US",
        "lat": "37.2329"
      },
      "bytes_sent": 3620864,
      "download": 18453057.862042435,
      "timestamp": "2019-04-03T03:41:39.676229Z",
      "share": null,
      "bytes_received": 23285508,
      "ping": 21.84,
      "upload": 2541162.260748782,
      "server": {
        "latency": 21.84,
        "name": "San Jose, CA",
        "url": "http://sjc.host.speedtest.net:8080/speedtest/upload.php",
        "country": "United States",
        "lon": "-121.8727",
        "cc": "US",
        "host": "sjc.host.speedtest.net:8080",
        "sponsor": "Speedtest.net",
        "url2": "http://sjc2.speedtest.net/speedtest/upload.php",
        "lat": "37.3041",
        "id": "10384",
        "d": 10.9325856080155
      }
    }
  },
  "cpu": {
    "date": 1554263572,
    "percent": 25.74
  },
  "hal": {
    "date": 1554262009,
    "lshw": {
      "id": "4b84c3b1d7d1",
      "class": "system",
      "claimed": true,
      "description": "Computer",
      "product": "Raspberry Pi 3 Model B Plus Rev 1.3",
      "serial": "000000003eb8a500",
      "width": 32,
      "children": [
        {
          "id": "core",
          "class": "bus",
          "claimed": true,
          "description": "Motherboard",
          "physid": "0",
          "capabilities": {
            "raspberrypi_3-model-b-plus": true,
            "brcm_bcm2837": true
          },
          "children": [
            {
              "id": "cpu:0",
              "class": "processor",
              "claimed": true,
              "description": "CPU",
              "product": "cpu",
              "physid": "0",
              "businfo": "cpu@0",
              "units": "Hz",
              "size": 1400000000,
              "capacity": 1400000000,
              "capabilities": {
                "cpufreq": "CPU Frequency scaling"
              }
            },
            {
              "id": "cpu:1",
              "class": "processor",
              "disabled": true,
              "claimed": true,
              "description": "CPU",
              "product": "cpu",
              "physid": "1",
              "businfo": "cpu@1",
              "units": "Hz",
              "size": 1400000000,
              "capacity": 1400000000,
              "capabilities": {
                "cpufreq": "CPU Frequency scaling"
              }
            },
            {
              "id": "cpu:2",
              "class": "processor",
              "disabled": true,
              "claimed": true,
              "description": "CPU",
              "product": "cpu",
              "physid": "2",
              "businfo": "cpu@2",
              "units": "Hz",
              "size": 1400000000,
              "capacity": 1400000000,
              "capabilities": {
                "cpufreq": "CPU Frequency scaling"
              }
            },
            {
              "id": "cpu:3",
              "class": "processor",
              "disabled": true,
              "claimed": true,
              "description": "CPU",
              "product": "cpu",
              "physid": "3",
              "businfo": "cpu@3",
              "units": "Hz",
              "size": 1400000000,
              "capacity": 1400000000,
              "capabilities": {
                "cpufreq": "CPU Frequency scaling"
              }
            },
            {
              "id": "memory",
              "class": "memory",
              "claimed": true,
              "description": "System memory",
              "physid": "4",
              "units": "bytes",
              "size": 972234752
            }
          ]
        },
        {
          "id": "network",
          "class": "network",
          "claimed": true,
          "description": "Ethernet interface",
          "physid": "1",
          "logicalname": "eth0",
          "serial": "02:42:c0:a8:90:02",
          "units": "bit/s",
          "size": 10000000000,
          "configuration": {
            "autonegotiation": "off",
            "broadcast": "yes",
            "driver": "veth",
            "driverversion": "1.0",
            "duplex": "full",
            "ip": "192.168.144.2",
            "link": "yes",
            "multicast": "yes",
            "port": "twisted pair",
            "speed": "10Gbit/s"
          },
          "capabilities": {
            "ethernet": true,
            "physical": "Physical interface"
          }
        }
      ]
    },
    "lsusb": [
      {
        "bus_number": "001",
        "device_id": "001",
        "device_bus_number": "1d6b",
        "manufacture_id": "Bus 001 Device 001: ID 1d6b:0002",
        "manufacture_device_name": "Bus 001 Device 001: ID 1d6b:0002"
      },
      {
        "bus_number": "001",
        "device_id": "003",
        "device_bus_number": "0424",
        "manufacture_id": "Bus 001 Device 003: ID 0424:2514",
        "manufacture_device_name": "Bus 001 Device 003: ID 0424:2514"
      },
      {
        "bus_number": "001",
        "device_id": "002",
        "device_bus_number": "0424",
        "manufacture_id": "Bus 001 Device 002: ID 0424:2514",
        "manufacture_device_name": "Bus 001 Device 002: ID 0424:2514"
      },
      {
        "bus_number": "001",
        "device_id": "004",
        "device_bus_number": "1415",
        "manufacture_id": "Bus 001 Device 004: ID 1415:2000",
        "manufacture_device_name": "Bus 001 Device 004: ID 1415:2000"
      },
      {
        "bus_number": "001",
        "device_id": "005",
        "device_bus_number": "0424",
        "manufacture_id": "Bus 001 Device 005: ID 0424:7800",
        "manufacture_device_name": "Bus 001 Device 005: ID 0424:7800"
      }
    ],
    "lscpu": {
      "Architecture": "armv7l",
      "Byte_Order": "Little Endian",
      "CPUs": "4",
      "On_line_CPUs_list": "0-3",
      "Threads_per_core": "1",
      "Cores_per_socket": "4",
      "Sockets": "1",
      "Vendor_ID": "ARM",
      "Model": "4",
      "Model_name": "Cortex-A53",
      "Stepping": "r0p4",
      "CPU_max_MHz": "1400.0000",
      "CPU_min_MHz": "600.0000",
      "BogoMIPS": "89.60",
      "Flags": "half thumb fastmult vfp edsp neon vfpv3 tls vfpv4 idiva idivt vfpd32 lpae evtstrm crc32"
    },
    "lspci": null,
    "lsblk": [
      {
        "name": "mmcblk0",
        "maj:min": "179:0",
        "rm": "0",
        "size": "29.7G",
        "ro": "0",
        "type": "disk",
        "mountpoint": null,
        "children": [
          {
            "name": "mmcblk0p1",
            "maj:min": "179:1",
            "rm": "0",
            "size": "43.9M",
            "ro": "0",
            "type": "part",
            "mountpoint": null
          },
          {
            "name": "mmcblk0p2",
            "maj:min": "179:2",
            "rm": "0",
            "size": "29.7G",
            "ro": "0",
            "type": "part",
            "mountpoint": "/etc/hosts"
          }
        ]
      }
    ],
    "lsdf": [
      {
        "mount": "/dev/root",
        "spacetotal": "30G",
        "spaceavail": "26G"
      }
    ]
  },
  "yolo2msghub": {
    "date": 1554263618,
    "yolo": {
      "info": {
        "type": "JPEG",
        "size": "320x240",
        "bps": "8-bit",
        "color": "sRGB"
      },
      "time": 37.862802,
      "count": 0,
      "detected": [
        {
          "entity": "person",
          "count": 0
        }
      ],
      "image": "<redacted>",
      "date": 1554263602
    }
  },
  "date": 1554227810,
  "hzn": {
    "agreementid": "2abd5656decd7b7343586ee6be739fbb49c8ff2ab3107be9962738d94b40986e",
    "arch": "arm",
    "cpus": 1,
    "device_id": "test-arm-1",
    "exchange_url": "https://alpha.edge-fabric.com/v1/",
    "host_ips": [
      "127.0.0.1",
      "192.168.1.220",
      "172.17.0.1"
    ],
    "organization": "dcmartin@us.ibm.com",
    "ram": 0,
    "pattern": "dcmartin@us.ibm.com/yolo2msghub-beta"
  },
  "config": {
    "date": 1554227810,
    "log_level": "info",
    "debug": false,
    "services": [
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
  },
  "service": {
    "label": "yolo2msghub",
    "version": "0.0.11"
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
