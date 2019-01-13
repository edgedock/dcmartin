#!/usr/bin/with-contenv bash
# ==============================================================================
set -o pipefail # Return exit status of the last command in the pipe that failed
set -o nounset  # Exit script on use of an undefined variable
# set -o errexit  # DO NOT Exit script when a command exits with non-zero status
# set -o errtrace # DO NOT Exit on error inside any functions or sub-shells

# shellcheck disable=SC1091
source /usr/lib/hassio-addons/base.sh

echo $(date) "$0 $*" >&2

if [ ! -s "${CONFIG_PATH}" ]; then
  echo "Cannot find options ${CONFIG_PATH}; exiting" >&2
  exit
fi

### START JSON
JSON='{"config_path":"'"${CONFIG_PATH}"'","hostname":"'"$(hostname)"'","arch":"'$(arch)'","date":'$(/bin/date +%s)

## device name
VALUE=$(jq -r ".name" "${CONFIG_PATH}")
if [ -z "${VALUE}" ] || [ "${VALUE}" == "null" ]; then VALUE=${HOSTNAME}-$(hostname -I | awk '{ print $1 }' | awk -F\. '{ printf("%03d%03d%03d%03d\n", $1, $2, $3, $4) }'); fi
echo "Setting name ${VALUE} [MOTION_DEVICE_NAME]" >&2
JSON="${JSON}"',"name":"'"${VALUE}"'"'
export MOTION_DEVICE_NAME="${VALUE}"

## MQTT
# local MQTT server (hassio addon)
VALUE=$(jq -r ".mqtt.host" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] && [ -z "${VALUE}" ]; then VALUE="core-mosquitto"; fi
echo "Using MQTT at ${VALUE}" >&2
MQTT='{"host":"'"${VALUE}"'"'
export MOTION_MQTT_HOST="${VALUE}"
# port
VALUE=$(jq -r ".mqtt.port" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=1883; fi
echo "Using MQTT port: ${VALUE}" >&2
MQTT="${MQTT}"',"port":'"${VALUE}"'}'
export MOTION_MQTT_PORT="${VALUE}"
# done
JSON="${JSON}"',"mqtt":'"${MQTT}"

###
### MOTION
###

echo "+++ MOTION" >&2

MOTION='{'

# set log_type
VALUE=$(jq -r ".log_type" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE="all"; fi
echo "Set log_type to ${VALUE}" >&2
sed -i "s|.*log_type .*|log_type ${VALUE}|" "${MOTION_CONF}"
MOTION="${MOTION}"',"log_type":"'"${VALUE}"'"'
# set log_level
VALUE=$(jq -r ".log_motion" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=2; fi
echo "Set motion log_level to ${VALUE}" >&2
sed -i "s/.*log_level\s[0-9]\+/log_level ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"log_level":'"${VALUE}"

## CAMERA

# set videodevice
VALUE=$(jq -r ".videodevice" "${CONFIG_PATH}")
if [ "${VALUE}" != "null" ] && [ ! -z "${VALUE}" ]; then 
  echo "Set videodevice to ${VALUE}" >&2
  sed -i "s|.*videodevice .*|videodevice ${VALUE}|" "${MOTION_CONF}"
  MOTION="${MOTION}"',"videodevice":"'"${VALUE}"'"'
fi

# set auto_brightness
VALUE=$(jq -r ".auto_brightness" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE="off"; fi
echo "Set auto_brightness to ${VALUE}" >&2
sed -i "s/.*auto_brightness .*/auto_brightness ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"auto_brightness":"'"${VALUE}"'"'

# set locate_motion_mode
VALUE=$(jq -r ".locate_motion_mode" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE="off"; fi
echo "Set locate_motion_mode to ${VALUE}" >&2
sed -i "s/.*locate_motion_mode .*/locate_motion_mode ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"locate_motion_mode":"'"${VALUE}"'"'

# set locate_motion_style (box, redbox, cross, redcross)
VALUE=$(jq -r ".locate_motion_style" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE="box"; fi
echo "Set locate_motion_style to ${VALUE}" >&2
sed -i "s/.*locate_motion_style .*/locate_motion_style ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"locate_motion_style":"'"${VALUE}"'"'

# set output_pictures (on, off, first, best, center)
VALUE=$(jq -r ".output_pictures" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE="on"; fi
echo "Set output_pictures to ${VALUE}" >&2
sed -i "s/.*output_pictures .*/output_pictures ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"output_pictures":"'"${VALUE}"'"'

# set picture_type (jpeg, ppm)
VALUE=$(jq -r ".picture_type" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE="jpeg"; fi
echo "Set picture_type to ${VALUE}" >&2
sed -i "s/.*picture_type .*/picture_type ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"picture_type":"'"${VALUE}"'"'

# set threshold_tune (jpeg, ppm)
VALUE=$(jq -r ".threshold_tune" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE="off"; fi
echo "Set threshold_tune to ${VALUE}" >&2
sed -i "s/.*threshold_tune .*/threshold_tune ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"threshold_tune":"'"${VALUE}"'"'

# set v4l2_pallette
VALUE=$(jq -r ".v4l2_pallette" "${CONFIG_PATH}")
if [ "${VALUE}" != "null" ] && [ ! -z "${VALUE}" ]; then
  echo "Set v4l2_pallette to ${VALUE}" >&2
  sed -i "s/.*v4l2_pallette\s[0-9]\+/v4l2_pallette ${VALUE}/" "${MOTION_CONF}"
  MOTION="${MOTION}"',"v4l2_pallette":'"${VALUE}"
fi

# set pre_capture
VALUE=$(jq -r ".pre_capture" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=0; fi
echo "Set pre_capture to ${VALUE}" >&2
sed -i "s/.*pre_capture\s[0-9]\+/pre_capture ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"pre_capture":'"${VALUE}"

# set post_capture
VALUE=$(jq -r ".post_capture" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=0; fi
echo "Set post_capture to ${VALUE}" >&2
sed -i "s/.*post_capture\s[0-9]\+/post_capture ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"post_capture":'"${VALUE}"

# set event_gap
VALUE=$(jq -r ".event_gap" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=10; fi
echo "Set event_gap to ${VALUE}" >&2
sed -i "s/.*event_gap\s[0-9]\+/event_gap ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"event_gap":'"${VALUE}"

# set minimum_motion_frames
VALUE=$(jq -r ".minimum_motion_frames" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=1; fi
echo "Set minimum_motion_frames to ${VALUE}" >&2
sed -i "s/.*minimum_motion_frames\s[0-9]\+/minimum_motion_frames ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"minimum_motion_frames":'"${VALUE}"

# set quality
VALUE=$(jq -r ".quality" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=75; fi
echo "Set quality to ${VALUE}" >&2
sed -i "s/.*quality\s[0-9]\+/quality ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"quality":'"${VALUE}"

# set width
VALUE=$(jq -r ".width" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=640; fi
echo "Set width to ${VALUE}" >&2
sed -i "s/.*width\s[0-9]\+/width ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"width":'"${VALUE}"

# set height
VALUE=$(jq -r ".height" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=480; fi
echo "Set height to ${VALUE}" >&2
sed -i "s/.*height\s[0-9]\+/height ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"height":'"${VALUE}"

# set framerate
VALUE=$(jq -r ".framerate" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=5; fi
echo "Set framerate to ${VALUE}" >&2
sed -i "s/.*framerate\s[0-9]\+/framerate ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"framerate":'"${VALUE}"

# set minimum_frame_time
VALUE=$(jq -r ".minimum_frame_time" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=0; fi
echo "Set minimum_frame_time to ${VALUE}" >&2
sed -i "s/.*minimum_frame_time\s[0-9]\+/minimum_frame_time ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"minimum_frame_time":'"${VALUE}"

# set brightness
VALUE=$(jq -r ".brightness" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=0; fi
echo "Set brightness to ${VALUE}" >&2
sed -i "s/.*brightness\s[0-9]\+/brightness ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"brightness":'"${VALUE}"

# set contrast
VALUE=$(jq -r ".contrast" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=0; fi
echo "Set contrast to ${VALUE}" >&2
sed -i "s/.*contrast\s[0-9]\+/contrast ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"contrast":'"${VALUE}"

# set saturation
VALUE=$(jq -r ".saturation" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=0; fi
echo "Set saturation to ${VALUE}" >&2
sed -i "s/.*saturation\s[0-9]\+/saturation ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"saturation":'"${VALUE}"

# set hue
VALUE=$(jq -r ".hue" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=0; fi
echo "Set hue to ${VALUE}" >&2
sed -i "s/.*hue\s[0-9]\+/hue ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"hue":'"${VALUE}"

# set rotate
VALUE=$(jq -r ".rotate" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=0; fi
echo "Set rotate to ${VALUE}" >&2
sed -i "s/.*rotate\s[0-9]\+/rotate ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"rotate":'"${VALUE}"

# set webcontrol_port
VALUE=$(jq -r ".webcontrol_port" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=8080; fi
echo "Set webcontrol_port to ${VALUE}" >&2
sed -i "s/.*webcontrol_port\s[0-9]\+/webcontrol_port ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"webcontrol_port":'"${VALUE}"

# set stream_port
VALUE=$(jq -r ".stream_port" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=8090; fi
echo "Set stream_port to ${VALUE}" >&2
sed -i "s/.*stream_port\s[0-9]\+/stream_port ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"stream_port":'"${VALUE}"

# set stream_quality
VALUE=$(jq -r ".stream_quality" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=50; fi
echo "Set stream_quality to ${VALUE}" >&2
sed -i "s/.*stream_quality\s[0-9]\+/stream_quality ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"stream_quality":'"${VALUE}"

# set threshold
VALUE=$(jq -r ".threshold" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=1500; fi
echo "Set threshold to ${VALUE}" >&2
sed -i "s/.*threshold .*/threshold ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"threshold":'"${VALUE}"

# set lightswitch
VALUE=$(jq -r ".lightswitch" "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=0; fi
echo "Set lightswitch to ${VALUE}" >&2
sed -i "s/.*lightswitch\s[0-9]\+/lightswitch ${VALUE}/" "${MOTION_CONF}"
MOTION="${MOTION}"',"lightswitch":'"${VALUE}"

# palette
VALUE=$(jq -r '.v4l2_palette' "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE=8; fi
echo "Set v4l2_palette to ${VALUE}" >&2
CAMERAS="${CAMERAS}"',"v4l2_palette":'"${VALUE}"
echo "v4l2_palette ${VALUE}" >> "${MOTION_CONF}"

# set username and password
USERNAME=$(jq -r ".username" "${CONFIG_PATH}")
PASSWORD=$(jq -r ".password" "${CONFIG_PATH}")
if [ "${USERNAME}" != "null" ] && [ "${PASSWORD}" != "null" ] && [ ! -z "${USERNAME}" ] && [ ! -z "${PASSWORD}" ]; then
  echo "Set authentication to Basic for both stream and webcontrol" >&2
  sed -i "s/.*stream_auth_method.*/stream_auth_method 1/" "${MOTION_CONF}"
  sed -i "s/.*stream_authentication.*/stream_authentication ${USERNAME}:${PASSWORD}/" "${MOTION_CONF}"
  sed -i "s/.*webcontrol_authentication.*/webcontrol_authentication ${USERNAME}:${PASSWORD}/" "${MOTION_CONF}"
  echo "Enable access for any host" >&2
  sed -i "s/.*stream_localhost .*/stream_localhost off/" "${MOTION_CONF}"
  sed -i "s/.*webcontrol_localhost .*/webcontrol_localhost off/" "${MOTION_CONF}"
  MOTION="${MOTION}"',"stream_auth_method":"Basic"'
else
  echo "WARNING: no username and password; stream and webcontrol limited to localhost only" >&2
  sed -i "s/.*stream_localhost .*/stream_localhost on/" "${MOTION_CONF}"
  sed -i "s/.*webcontrol_localhost .*/webcontrol_localhost on/" "${MOTION_CONF}"
fi

## end motion structure; cameras section depends on well-formed JSON for $MOTION
MOTION="${MOTION}"'}'

## append to configuration JSON
JSON="${JSON}"',"motion":'"${MOTION}"

### DONE w/ MOTION_CONF

## WATSON
WVR_URL=$(jq -r ".watson.url" "${CONFIG_PATH}")
WVR_APIKEY=$(jq -r ".watson.apikey" "${CONFIG_PATH}")
WVR_CLASSIFIER=$(jq -r ".watson.classifier" "${CONFIG_PATH}")
WVR_DATE=$(jq -r ".watson.date" "${CONFIG_PATH}")
WVR_VERSION=$(jq -r ".watson.version" "${CONFIG_PATH}")
if [ ! -z "${WVR_URL}" ] && [ ! -z "${WVR_APIKEY}" ] && [ ! -z "${WVR_DATE}" ] && [ ! -z "${WVR_VERSION}" ] && [ "${WVR_URL}" != "null" ] && [ "${WVR_APIKEY}" != "null" ] && [ "${WVR_DATE}" != "null" ] && [ "${WVR_VERSION}" != "null" ]; then
  echo "Watson Visual Recognition at ${WVR_URL} date ${WVR_DATE} version ${WVR_VERSION}" >&2
  WATSON='{"url":"'"${WVR_URL}"'","date":"'"${WVR_DATE}"'","version":"'"${WVR_VERSION}"'","models":['
  if [ ! -z "${WVR_CLASSIFIER}" ] && [ "${WVR_CLASSIFIER}" != "null" ]; then
    # quote the model names
    CLASSIFIERS=$(echo "${WVR_CLASSIFIER}" | sed 's/\([^,]*\)\([,]*\)/"\1"\2/g')
    echo "Using classifiers(s): ${CLASSIFIERS}" >&2
    WATSON="${WATSON}""${CLASSIFIERS}"
  else
    # add default iif none specified
    WATSON="${WATSON}"'"default"'
  fi
  WATSON="${WATSON}"']}'
  # make available
  export MOTION_WATSON_APIKEY="${WVR_APIKEY}"
fi
if [ -n "${WATSON:-}" ]; then
  JSON="${JSON}"',"watson":'"${WATSON}"
else
  echo "Watson Visual Recognition not specified" >&2
  JSON="${JSON}"',"watson":null'
fi

## DIGITS
VALUE=$(jq -r ".digits.url" "${CONFIG_PATH}")
if [ "${VALUE}" != "null" ] && [ ! -z "${VALUE}" ]; then
  DIGITS_SERVER_URL="${VALUE}"
  DIGITS='{"url":"'"${DIGITS_SERVER_URL}"'"'
  VALUE=$(jq -r ".digits.jobid" "${CONFIG_PATH}")
  if [ ! -z "${VALUE}" ] && [ "${VALUE}" != "null" ]; then
    DIGITS_JOBIDS=$(echo "${VALUE}" | sed 's/\([^,]*\)\([,]*\)/"\1"\2/g')
    echo "Using DIGITS at ${DIGITS_SERVER_URL} and ${DIGITS_JOBIDS}" >&2
    DIGITS="${DIGITS}"',"models":['"${DIGITS_JOBIDS}"']'
  else
    DIGITS="${DIGITS}"',"models":[]'
  fi
  DIGITS="${DIGITS}"'}'
fi
if [ -n "${DIGITS:-}" ]; then
  JSON="${JSON}"',"digits":'"${DIGITS}"
else
  echo "DIGITS not specified" >&2
  JSON="${JSON}"',"digits":null'
fi

## append to configuration JSON
if [ -n "${CAMERAS:-}" ]; then 
  JSON="${JSON}"',"cameras":'"${CAMERAS}"']'
fi

# set post_pictures; enumerated [on,center,first,last,best,most]
VALUE=$(jq -r '.post_pictures' "${CONFIG_PATH}")
if [ "${VALUE}" == "null" ] || [ -z "${VALUE}" ]; then VALUE="center"; fi
echo "Set post_pictures to ${VALUE}" >&2
JSON="${JSON}"',"post_pictures":"'"${VALUE}"'"'
export MOTION_POST_PICTURES="${VALUE}"

###
### DONE w/ JSON
###

JSON="${JSON}"'}'

export MOTION_JSON_FILE="${MOTION_CONF%/*}/${MOTION_DEVICE_NAME}.json"
echo "${JSON}" | jq '.' > "${MOTION_JSON_FILE}"
if [ ! -s "${MOTION_JSON_FILE}" ]; then
  echo "Invalid JSON: ${JSON}" >&2
  exit
else
  echo "Publishing configuration to ${MOTION_MQTT_HOST} topic ${MOTION_DEVICE_DB}/${MOTION_DEVICE_NAME}/start" >&2
  mosquitto_pub -r -q 2 -h "${MOTION_MQTT_HOST}" -p "${MOTION_MQTT_PORT}" -t "${MOTION_DEVICE_DB}/${MOTION_DEVICE_NAME}/start" -f "${MOTION_JSON_FILE}"
fi

###
### START MOTION
###

MOTION_CMD=$(command -v motion)
if [ ! -s "${MOTION_CMD}" ] || [ ! -s "${MOTION_CONF}" ]; then
  echo "No motion installed (${MOTION_CMD}) or motion configuration ${MOTION_CONF} does not exist" >&2
else
  # start motion
  echo "*** Start motion with ${MOTION_CONF}" >&2
  motion -n -c "${MOTION_CONF}" -l /dev/stderr
fi
