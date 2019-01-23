# YOLO service

Provide YOLO as-a-service ReSTful API

This service takes no input values; image is captured from /dev/video0 at default resolution (n.b. Sony Playstation3 Eye camera default is 320x240).  If no image can be captured, a default image `mock.jpg` (aka `darknet/data/personx4.jpg`) is utilized and the `mock` attribute in the response is set to `true`.

## Service Tag

Other Horizon services can require the `yolo` service through service tag:

1. Intel/AMD 64-bit: `dcmartin@us.ibm.com/com.github.dcmartin.open-horizon.yolo_0.0.1_amd64`
1. ARMv7x32: `dcmartin@us.ibm.com/com.github.dcmartin.open-horizon.yolo_0.0.1_arm`
1. ARMv8x64: `dcmartin@us.ibm.com/com.github.dcmartin.open-horizon.yolo_0.0.1_arm64`

## RESTful API

This service provisions an HTTP-only interface on port 80 and may be referred to by its name: `http://yolo:80/`

```
% curl -s http://yolo:80/
{
  "devid": "069c30609fd8",
  "date": 1548280505,
  "time": 4.309698,
  "person": 4,
  "width": 2592,
  "height": 1944,
  "scale": "320x240",
  "mock": "true",
  "image": "<BASE64_JPEG>"
}
```

## Example

![mock-output.jpg](mock-output.jpg?raw=true "YOLO")
