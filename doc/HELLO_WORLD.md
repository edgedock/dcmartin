# `HELLO.md` - The `hello-world` example

## Introduction
As with all software systems a simple example is required to on-board new users; this service is that example.

In this example a new service, `hello`, will be created, built, and run; demonstrating the operational Docker container.

Please refer to [`CICD.md`][cicd-md] for more information.

[cicd-md]: https://github.com/dcmartin/open-horizon/blob/master/doc/CICD.md

### &#10071;  Default exchange & registry
The Open Horizon exchange and Docker registry defaults are utilized.

+ `HZN_EXCHANGE_URL` - `http://alpha.edge-fabric.com/v1/`
+ `DOCKER_REGISTRY` - `docker.io`

### &#9995; Development host as test device

It is expected that the development host has been configured as an Open Horizon node with the `hzn` command-line-interface (CLI) installed.  In addition, to utilize the localhost as a pattern test node, the user must have both `sudo` and `ssh` privileges for the development host.

## Step 1
Copy IBM Cloud Platform API key file downloaded from [IAM](https://cloud.ibm.com/iam) and set environment variables for Open Horizon organization and Docker namespace:

```
cp ~/Downloads/apiKey.json .
export HZN_ORG_ID=
export DOCKER_NAMESPACE=
```

And run the following commands to clone and configure this repository.

```
git clone http://github.com/dcmartin/open-horizon
cd open-horizon
echo "${HZN_ORG_ID}" > HZN_ORG_ID
echo "${DOCKER_NAMESPACE}" > DOCKER_NAMESPACE
hzn key create ${HZN_ORG_ID} $(whoami)@$(hostname)
mv -f *.key ${HZN_ORG_ID}.key
mv -f *.pem ${HZN_ORG_ID}.pem
```
## Step 2
Create a new directory for the new service `hello`:

```
mkdir hello
```

## Step 3
Link repository scripts (`sh`) and service `makefile` to `hello` directory:

```
cd hello
ln -s ../sh .
ln -s ../service.makefile Makefile
```

## Step 4
Create the **`hello/Dockerfile`** with the following contents

```
FROM ubuntu:bionic
RUN apt-get update && apt-get install -qq -y socat
COPY rootfs /
CMD ["/usr/bin/run.sh"]
```

## Step 5
Create directory for scripts:

```
mkdir -p rootfs/usr/bin
```

## Step 6
Create `run.sh` and `service.sh` scripts in the `rootfs/usr/bin/` directory:

**`hello/rootfs/usr/bin/run.sh`**

```
#!/bin/sh
socat TCP4-LISTEN:80,fork EXEC:/usr/bin/service.sh
```

**`hello/rootfs/usr/bin/service.sh`**

```
#!/bin/sh
echo "HTTP/1.1 200 OK"
echo
echo '{"hello":"world"}'
```

Change the permissions to enable execution:

```
chmod 755 rootfs/usr/bin/run.sh
chmod 755 rootfs/usr/bin/service.sh
```

## Step 7
Create `service.json` configuration file; specify organization unique `url`; the variable values will be substituted during the build process.

**`hello/service.json`**

```
{
  "label":"hello",
  "org":"${HZN_ORG_ID}",
  "url":"${USER}_hello_world",
  "version":"0.0.1",
  "arch":"${BUILD_ARCH}",
  "deployment": {
    "services": {
      "hello": {
        "image": null
      }
    }
  }
}
```

## Step 8
Create `build.json` configuration file; specify `FROM` targets for Docker `build`.

**`hello/build.json`**

```
{
  "build_from":{
    "amd64":"ubuntu:bionic",
    "arm": "arm32v7/ubuntu:bionic",
    "arm64": "arm64v8/ubuntu:bionic"
  }
}
```

## Step 9
Configure environment for both Docker port on localhost:

```
export DOCKER_PORT=12345
```

## Step 10
Build, run, and check the service container locally using the native (i.e. `amd64`) architecture.

```
% make
>>> MAKE -- 11:44:37 -- hello building: hello-beta; tag: dcmartin/amd64_dcmartin.hello-beta:0.0.1
>>> MAKE -- 11:44:38 -- removing container named: amd64_dcmartin.hello-beta
amd64_dcmartin.hello-beta
>>> MAKE -- 11:44:38 -- running container: dcmartin/amd64_dcmartin.hello-beta:0.0.1; name: amd64_dcmartin.hello-beta
2565ecd514322e55bd6c1091982541d30e5db212682887c25d1e814caf4c0445
>>> MAKE -- 11:44:41 -- checking container: dcmartin/amd64_dcmartin.hello-beta:0.0.1; URL: http://localhost:12345
{
  "hello": "world"
}
```

## Step 11
Build, test, and if successful, publish service for __all__ architectures.

```
% make service-build && make service-test && make service-publish
```

## Step 12
Create pattern configuration file to test the `yolo2msghub` service.  The variables will have values substituted during the build process.

**`hello/pattern.json`**

```
{
  "label": "hello",
  "services": [
    {
      "serviceUrl": "${SERVICE_URL}",
      "serviceOrgid": "${HZN_ORG_ID}",
      "serviceArch": "amd64",
      "serviceVersions": [
        {
          "version": "${SERVICE_VERSION}"
        }
      ]
    },
    {
      "serviceUrl": "${SERVICE_URL}",
      "serviceOrgid": "${HZN_ORG_ID}",
      "serviceArch": "arm",
      "serviceVersions": [
        {
          "version": "${SERVICE_VERSION}"
        }
      ]
    },
    {
      "serviceUrl": "${SERVICE_URL}",
      "serviceOrgid": "${HZN_ORG_ID}",
      "serviceArch": "arm64",
      "serviceVersions": [
        {
          "version": "${SERVICE_VERSION}"
        }
      ]
    }
  ]
}
```

## Step 13
Publish pattern for `hello` service.

```
% make pattern-publish
```

## Step 14
Register development host as a test device; multiple devices may be listed, one per line.

```
% echo 'localhost' > TEST_TMP_MACHINES
```

And register test device(s) with `hello` pattern:

```
% make nodes
```

## Step 15
Inspect nodes until fully configured:

```
% make nodes-list
```

## Step 16
Test nodes for correct output:

```
% make nodes-test
```

## Step 17
Clean nodes.

```
% make nodes-clean
```

## Step 18
Clean service.

```
% make service-clean
```


