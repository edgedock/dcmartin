# Horizon Hardware Abstraction Layer service

Provide lsusb, lscpu, and lspci as-a-service encoded as JSON

## Input Values

This service takes no input values.

## RESTful API

Other Horizon services can use the `hal` service by requiring it in its own service definition.

### **API:** 

```
http://hal:54331/
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
    { "bus_number": "002", "device_id": "003", "device_bus_number": "1b1c", "manufacture_id": "0c04", "manufacture_device_name": "Corsair " },
    { "bus_number": "002", "device_id": "002", "device_bus_number": "8087", "manufacture_id": "0024", "manufacture_device_name": "Intel Corp. Integrated Rate Matching Hub" },
    { "bus_number": "002", "device_id": "001", "device_bus_number": "1d6b", "manufacture_id": "0002", "manufacture_device_name": "Linux Foundation 2.0 root hub" },
    { "bus_number": "006", "device_id": "001", "device_bus_number": "1d6b", "manufacture_id": "0003", "manufacture_device_name": "Linux Foundation 3.0 root hub" },
    { "bus_number": "005", "device_id": "002", "device_bus_number": "04b3", "manufacture_id": "310b", "manufacture_device_name": "IBM Corp. Red Wheel Mouse" },
    { "bus_number": "005", "device_id": "001", "device_bus_number": "1d6b", "manufacture_id": "0002", "manufacture_device_name": "Linux Foundation 2.0 root hub" },
    { "bus_number": "001", "device_id": "005", "device_bus_number": "04b3", "manufacture_id": "300f", "manufacture_device_name": "IBM Corp. " },
    { "bus_number": "001", "device_id": "004", "device_bus_number": "04b3", "manufacture_id": "300e", "manufacture_device_name": "IBM Corp. " },
    { "bus_number": "001", "device_id": "003", "device_bus_number": "04b3", "manufacture_id": "300d", "manufacture_device_name": "IBM Corp. " },
    { "bus_number": "001", "device_id": "002", "device_bus_number": "8087", "manufacture_id": "0024", "manufacture_device_name": "Intel Corp. Integrated Rate Matching Hub" },
    { "bus_number": "001", "device_id": "001", "device_bus_number": "1d6b", "manufacture_id": "0002", "manufacture_device_name": "Linux Foundation 2.0 root hub" },
    { "bus_number": "004", "device_id": "001", "device_bus_number": "1d6b", "manufacture_id": "0003", "manufacture_device_name": "Linux Foundation 3.0 root hub" },
    { "bus_number": "003", "device_id": "006", "device_bus_number": "045e", "manufacture_id": "02ae", "manufacture_device_name": "Microsoft Corp. Xbox NUI Camera" },
    { "bus_number": "003", "device_id": "004", "device_bus_number": "045e", "manufacture_id": "02b0", "manufacture_device_name": "Microsoft Corp. Xbox NUI Motor" },
    { "bus_number": "003", "device_id": "005", "device_bus_number": "045e", "manufacture_id": "02ad", "manufacture_device_name": "Microsoft Corp. Xbox NUI Audio" },
    { "bus_number": "003", "device_id": "003", "device_bus_number": "0409", "manufacture_id": "005a", "manufacture_device_name": "NEC Corp. HighSpeed Hub" },
    { "bus_number": "003", "device_id": "002", "device_bus_number": "0bda", "manufacture_id": "2838", "manufacture_device_name": "Realtek Semiconductor Corp. RTL2838 DVB-T" },
    { "bus_number": "003", "device_id": "001", "device_bus_number": "1d6b", "manufacture_id": "0002", "manufacture_device_name": "Linux Foundation 2.0 root hub" }
  ],
  "lscpu": [
    { "Architecture": "x86_64" },
    { "CPU op-mode(s)": "32-bit, 64-bit" },
    { "Byte Order": "Little Endian" },
    { "CPU(s)": "4" },
    { "On-line CPU(s) list": "0-3" },
    { "Thread(s) per core": "1" },
    { "Core(s) per socket": "4" },
    { "Socket(s)": "1" },
    { "NUMA node(s)": "1" },
    { "Vendor ID": "GenuineIntel" },
    { "CPU family": "6" },
    { "Model": "58" },
    { "Model name": "Intel(R) Core(TM) i5-3570K CPU @ 3.40GHz" },
    { "Stepping": "9" },
    { "CPU MHz": "2137.866" },
    { "CPU max MHz": "3800.0000" },
    { "CPU min MHz": "1600.0000" },
    { "BogoMIPS": "6800.71" },
    { "Virtualization": "VT-x" },
    { "L1d cache": "32K" },
    { "L1i cache": "32K" },
    { "L2 cache": "256K" },
    { "L3 cache": "6144K" },
    { "NUMA node0 CPU(s)": "0-3" },
    { "Flags": "fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm pcid sse4_1 sse4_2 popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm cpuid_fault epb pti ssbd ibrs ibpb stibp tpr_shadow vnmi flexpriority ept vpid fsgsbase smep erms xsaveopt dtherm ida arat pln pts flush_l1d" }
  ],
  "lspci": [
    { "slot": "00:00.0", "device_class_id": "0600", "device_class": "Host bridge", "vendor_class_id": "8086", "vendor_class": "Intel Corporation", "device_id": "0150", "device_name": "Xeon E3-1200 v2/3rd Gen Core processor DRAM Controller" },
    { "slot": "00:01.0", "revision": "09", "device_class_id": "0604", "device_class": "PCI bridge", "vendor_class_id": "8086", "vendor_class": "Intel Corporation", "device_id": "0151", "device_name": "Xeon E3-1200 v2/3rd Gen Core processor PCI Express Root Port" },
    { "slot": "00:02.0", "device_class_id": "0300", "device_class": "VGA compatible controller", "vendor_class_id": "8086", "vendor_class": "Intel Corporation", "device_id": "0162", "device_name": "Xeon E3-1200 v2/3rd Gen Core processor Graphics Controller" },
    { "slot": "00:14.0", "device_class_id": "0c03", "device_class": "USB controller", "vendor_class_id": "8086", "vendor_class": "Intel Corporation", "device_id": "1e31", "device_name": "7 Series/C210 Series Chipset Family USB xHCI Host Controller" },
    { "slot": "00:16.0", "device_class_id": "0780", "device_class": "Communication controller", "vendor_class_id": "8086", "vendor_class": "Intel Corporation", "device_id": "1e3a", "device_name": "7 Series/C216 Chipset Family MEI Controller #1" },
    { "slot": "00:1a.0", "device_class_id": "0c03", "device_class": "USB controller", "vendor_class_id": "8086", "vendor_class": "Intel Corporation", "device_id": "1e2d", "device_name": "7 Series/C216 Chipset Family USB Enhanced Host Controller #2" },
    { "slot": "00:1b.0", "device_class_id": "0403", "device_class": "Audio device", "vendor_class_id": "8086", "vendor_class": "Intel Corporation", "device_id": "1e20", "device_name": "7 Series/C216 Chipset Family High Definition Audio Controller" },
    { "slot": "00:1c.0", "revision": "c4", "device_class_id": "0604", "device_class": "PCI bridge", "vendor_class_id": "8086", "vendor_class": "Intel Corporation", "device_id": "1e10", "device_name": "7 Series/C216 Chipset Family PCI Express Root Port 1" },
    { "slot": "00:1c.3", "revision": "c4", "device_class_id": "0604", "device_class": "PCI bridge", "vendor_class_id": "8086", "vendor_class": "Intel Corporation", "device_id": "1e16", "device_name": "7 Series/C216 Chipset Family PCI Express Root Port 4" },
    { "slot": "00:1c.4", "revision": "c4", "device_class_id": "0604", "device_class": "PCI bridge", "vendor_class_id": "8086", "vendor_class": "Intel Corporation", "device_id": "1e18", "device_name": "7 Series/C210 Series Chipset Family PCI Express Root Port 5" },
    { "slot": "00:1c.5", "revision": "c4", "device_class_id": "0604", "device_class": "PCI bridge", "vendor_class_id": "8086", "vendor_class": "Intel Corporation", "device_id": "1e1a", "device_name": "7 Series/C210 Series Chipset Family PCI Express Root Port 6" },
    { "slot": "00:1c.7", "revision": "c4", "device_class_id": "0604", "device_class": "PCI bridge", "vendor_class_id": "8086", "vendor_class": "Intel Corporation", "device_id": "1e1e", "device_name": "7 Series/C210 Series Chipset Family PCI Express Root Port 8" },
    { "slot": "00:1d.0", "device_class_id": "0c03", "device_class": "USB controller", "vendor_class_id": "8086", "vendor_class": "Intel Corporation", "device_id": "1e26", "device_name": "7 Series/C216 Chipset Family USB Enhanced Host Controller #1" },
    { "slot": "00:1f.0", "device_class_id": "0601", "device_class": "ISA bridge", "vendor_class_id": "8086", "vendor_class": "Intel Corporation", "device_id": "1e44", "device_name": "Z77 Express Chipset LPC Controller" },
    { "slot": "00:1f.2", "device_class_id": "0106", "device_class": "SATA controller", "vendor_class_id": "8086", "vendor_class": "Intel Corporation", "device_id": "1e02", "device_name": "7 Series/C210 Series Chipset Family 6-port SATA Controller [AHCI mode]" },
    { "slot": "00:1f.3", "device_class_id": "0c05", "device_class": "SMBus", "vendor_class_id": "8086", "vendor_class": "Intel Corporation", "device_id": "1e22", "device_name": "7 Series/C216 Chipset Family SMBus Controller" },
    { "slot": "01:00.0", "device_class_id": "0300", "device_class": "VGA compatible controller", "vendor_class_id": "10de", "vendor_class": "NVIDIA Corporation", "device_id": "1c82", "device_name": "GP107 [GeForce GTX 1050 Ti]" },
    { "slot": "01:00.1", "device_class_id": "0403", "device_class": "Audio device", "vendor_class_id": "10de", "vendor_class": "NVIDIA Corporation", "device_id": "0fb9", "device_name": "GP107GL High Definition Audio Controller" },
    { "slot": "03:00.0", "device_class_id": "0106", "device_class": "SATA controller", "vendor_class_id": "1b21", "vendor_class": "ASMedia Technology Inc.", "device_id": "0612", "device_name": "ASM1062 Serial ATA Controller" },
    { "slot": "04:00.0", "device_class_id": "0200", "device_class": "Ethernet controller", "vendor_class_id": "14e4", "vendor_class": "Broadcom Limited", "device_id": "16b1", "device_name": "NetLink BCM57781 Gigabit Ethernet PCIe" },
    { "slot": "05:00.0", "revision": "04", "interface": "01", "device_class_id": "0604", "device_class": "PCI bridge", "vendor_class_id": "1b21", "vendor_class": "ASMedia Technology Inc.", "device_id": "1080", "device_name": "ASM1083/1085 PCIe to PCI Bridge" },
    { "slot": "07:00.0", "device_class_id": "0c03", "device_class": "USB controller", "vendor_class_id": "1b21", "vendor_class": "ASMedia Technology Inc.", "device_id": "1042", "device_name": "ASM1042 SuperSpeed USB Host Controller" }
  ]
}
```
