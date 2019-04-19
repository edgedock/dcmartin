export MYDOMAIN=com.ibm.example.efg
export HZN_PATTERN=IBM_efg_rpi_i2c_oled

export HZN_DEVICE_ID=0000000085414566
export HZN_DEVICE_TOKEN=w4280

export ARCH=arm                   # arch of your edge node: amd64, or arm for Raspberry Pi, or arm64 for TX2
export SERVICE_NAME=rpii2coled # the name of the service, used in the docker image path and in the service url
export SERVICE_VERSION=0.0.1   # the service version, and also used as the tag for the docker image. Must be in OSGI version format.

export DOCKER_HUB_ID=edgedock

export EVENT_STREAM_API_KEY="QfonJaAb9NVQSMqDq4qQYaZXnPBhOd74h3GoNn2oJFI5wBTI"
export EVENT_STREAM_ADMIN_URL="https://kafka-admin-prod02.messagehub.services.us-south.bluemix.net:443"
export EVENT_STREAM_BROKER_URL="kafka03-prod02.messagehub.services.us-south.bluemix.net:9093,kafka04-prod02.messagehub.services.us-south.bluemix.net:9093,kafka05-prod02.messagehub.services.us-south.bluemix.net:9093,kafka01-prod02.messagehub.services.us-south.bluemix.net:9093,kafka02-prod02.messagehub.services.us-south.bluemix.net:9093"

# There is normally no need for you to edit these variables
export HZN_ORGANIZATION=$HZN_ORG_ID
export EXCHANGE_NODEAUTH="$HZN_DEVICE_ID:$HZN_DEVICE_TOKEN"

# You only need to set this if you are running 'hzn dev' without the full edge fabric agent installed
export HZN_EXCHANGE_URL="https://alpha.edge-fabric.com/v1"

