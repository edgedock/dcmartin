# `HELLO.md` - The `hello-world` example

## Introduction
As with all software systems a simple example is required to on-board new users; this service is that example.

In this example a new service, `hello`, will be created, built, and run; demonstrating the operational Docker container.

## Step 1
Copy (clone/fork) this repository and configure; please refer to `CICD.md` for more information.

```
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon
% export HZN_ORG_ID=
% export DOCKER_NAMESPACE=
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
Create the Dockerfile with the following contents

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

**`run.sh`**

```
#!/bin/sh
socat TCP4-LISTEN:80,fork EXEC:/usr/bin/service.sh
```

**`service.sh`**

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
Edit `service.json` configuration file to specify organization unique `url` and `version`:

**`service.json`**

```
{"org":"${HZN_ORG_ID}","url":"${USER}-${HOST}","version":"0.0.1","arch":"${BUILD_ARCH}"}
```

**`build.json`**

```
{"build_from":{"amd64":"ubuntu:bionic"}}
```

## Step 8
Configure environment for both Docker port on localhost as well as service label, identifier (`URL`), and version (`VER`):

```
export DOCKER_PORT=12345
export SERVICE_LABEL="hello"
export SERVICE_URL="${USER}"
export SERVICE_VERSION="0.0.1"
```

## Step 9
Build, run, and check the service container locally using the default (i.e. `amd64`) architecture.

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

## Step 10
Build service, test, and publish for all architectures.

```
% make service-build && make service-test && make service-publish
```

## Step 11
Publish test pattern for `hello` service:

```
% make pattern-publish
```

## Step 12
Register test device for pattern:

```
% make nodes
% make nodes-test
```
