# `HELLO.md` - The `hello-world` example

## Introduction
As with all software systems a simple example is required to on-board new users; this service is that example.

In this example a new service, `hello`, will be created, built, and run; demonstrating the operational Docker container.

## Step 1
Copy (clone/fork) this repository and configure; please refer to `CICD.md` for more information.

## Step 2
Create a new directory for the new service `hello`:

```
cd $GD
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
Create the Dockerfile:

```
cat > Dockerfile << EOF
FROM ubuntu:bionic
RUN apt-get update && apt-get install -qq -y socat
COPY rootfs /
CMD ["/usr/bin/run.sh"]
EOF
```

## Step 5
Create directory for scripts:

```
mkdir -p rootfs/usr/bin
```

## Step 6
Create `run.sh` and `service.sh` scripts

```
pushd rootfs/usr/bin
cat > run.sh << EOF
#!/bin/sh
socat TCP4-LISTEN:80,fork EXEC:/usr/bin/service.sh
EOF
cat > service.sh << EOF
#!/bin/sh
echo "HTTP/1.1 200 OK"
echo
echo '{"hello":"world"}'
EOF
chmod 755 run.sh
chmod 755 service.sh
popd
```

## Step 7
Create `service.json` and `build.json` configuration files:

```
echo '{"org":"${HZN_ORG_ID}","url":"${URL}","version":"${VER}","arch":"${BUILD_ARCH}"}' > service.json
echo '{"build_from":{"amd64":"ubuntu:bionic"}}' > build.json
```

## Step 8
Configure environment for both Docker port on localhost as well as service label, identifier (`URL`), and version (`VER`):

```
export DOCKER_PORT=12345
export SERVICE_LABEL="hello"
export URL="${USER}"
export VER="0.0.1"
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
