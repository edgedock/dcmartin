# Horizon Hardware Abstraction Layer service

Provide lsusb, lscpu, and lspci as-a-service encoded as JSON

## Input Values

This service takes no input values.

## RESTful API

Other Horizon services can use the `hal` service by requiring it in its own service definition.

### **API:** 

```
http://hal:8585/
```
---

#### Parameters:

None

#### Response:

```
{
 "lsusb": [],
 "lscpu": [],
 "lspci": []
}
```

#### Example:

```
{
  "lsusb": [
    {
      "bus_number": "001",
      "device_id": "003",
      "device_bus_number": "0424",
      "manufacture_id": "ec00",
      "manufacture_device_name": "Standard Microsystems Corp. SMSC9512/9514 Fast Ethernet Adapter"
    },
    {
      "bus_number": "001",
      "device_id": "002",
      "device_bus_number": "0424",
      "manufacture_id": "9514",
      "manufacture_device_name": "Standard Microsystems Corp. SMC9514 Hub"
    },
    {
      "bus_number": "001",
      "device_id": "001",
      "device_bus_number": "1d6b",
      "manufacture_id": "0002",
      "manufacture_device_name": "Linux Foundation 2.0 root hub"
    }
  ],
  "lscpu": {
    "Architecture": "armv7l",
    "Byte Order": "Little Endian",
    "CPU(s)": "4",
    "On-line CPU(s) list": "0-3",
    "Thread(s) per core": "1",
    "Core(s) per socket": "4",
    "Socket(s)": "1",
    "Model": "4",
    "Model name": "ARMv7 Processor rev 4 (v7l)",
    "CPU max MHz": "1200.0000",
    "CPU min MHz": "600.0000",
    "BogoMIPS": "76.80",
    "Flags": "half thumb fastmult vfp edsp neon vfpv3 tls vfpv4 idiva idivt vfpd32 lpae evtstrm crc32"
  },
  "lspci": null,
  "lsblk": [
    {
      "name": "mmcblk0",
      "maj:min": "179:0",
      "rm": "0",
      "size": "29.8G",
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
          "mountpoint": "/boot"
        },
        {
          "name": "mmcblk0p2",
          "maj:min": "179:2",
          "rm": "0",
          "size": "29.8G",
          "ro": "0",
          "type": "part",
          "mountpoint": "/"
        }
      ]
    }
  ]
}
```
