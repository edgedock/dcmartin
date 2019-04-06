# Example

This example combines four existing services output and sends their information to the cloud.

## Assumptions

This example is based on a single developer copying this repository and building a new version of the `yolo2msghub` service and pattern.

The developer requires:

1. Docker Hub account (or other Docker registry)
1. Open Horizon exchange organization
1. A github.com account
1. A travis-ci.org account
1. iMac, macMini, macBook (macOS v12.14+)
1. XCode command-line-tools
1. Docker for macOS
1. Homebrew; installer at https://brew.sh
1. Open Horion `hzn` command-line-tool; installer at http://ibm.biz/get-horizon

and experience with the following:

+ Docker
+ Git
+ Travis
+ LINUX
+ `make`, `bash`, `curl`, `jq`, `socat`, `kafkacat`

## What Will Happen 

The developer will 

1. copy this repository
1. configure for registry & exchange
1. build all services
1. test all services
1. publish all services
1. publish pattern
1. create branches for `test` and `dev`
1. configure Travis
  1. build, test, commit for `test`
  1. build, test, push, publish for `master`
1. develop in `dev` branch
  1. add test case
  1. implement feature
  1. build
  1. test
1. request merge from `dev` to `test`

The automated CI/CD system will

1. detect merge request
1. checkout `test`
1. pull from `dev`
1. build
1. test
  1. failure: reject merge
  1. success: commit `test`

2. detect `test` commit
2. checkout `master`
2. pull from `test` branch
2. build
2. test
  2. failure: reject merge
  2. success: commit `master`

3. detect `master` commit
3. checkout `master`
3. build
3. test
  3. failure: rollback commit
  3. success: push images, publish services, publish pattern


# Step-By-Step

## Step 1
Create accounts on github.com and travis-ci.com; link the accounts.

## Step 2
Fork this repository to the github.com account

## Step 3
Create Git branches for `test` and `dev`

## Step 4
Edit YAML file `.travis.yml` 

## Step 5
Link the github.com repository to travis-ci.com

## Step 6
Set environment variables for repository on travis-ci.com:

+ `DOCKER_LOGIN`
+ `DOCKER_PASSWORD`
+ `DOCKER_NAMESPACE`
+ `HZN_EXCHANGE_APIKEY`
+ `HZN_ORG_ID` - `<user>@<emailservice>.<tld>`
+ `PUBLIC_KEY` - `base64` encoded signing key (public)
+ `PRIVATE_KEY` - `base64` encoded signing key (private)

### For IBM Container registry

+ `DOCKER_LOGIN` - `token`
+ `DOCKER_PASSWORD` - _private_ registry value
+ `DOCKER_NAMESPACE` - _namespace_ registry value
+ `DOCKER_TOKEN` - _public_ registry value
+ `DOCKER_REGISTRY` - `icr.io` (or other, depending on region)

## Step 7
Change to `master` branch and build

```
git checkout master
make service-build && make service-test || echo "build-test failed"
```

Assuming success, push containers and publish services:

```
make service-push && make service-publish  || echo "push-publish failed"
```

## Step 8
Verify published services

```
make service-verify
```

## Step 9
Publish pattern

```
make pattern-publish
```

## **DONE**
The initial building and populating of the Docker registry and the Open Horizon exchange is complete.

Check the patterns in the exchange:

```
./sh/lspatterns.sh | jq '.patterns[].id'
```

Check the services in the exchange

```
./sh/lspatterns.sh | jq '.patterns[].id'
```

