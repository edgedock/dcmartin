# Install Ubuntu 18 (Bionic) on nVidia TX2

The nVidia TX2 is configured using the nVidia JetPack.  The latest version for TX2 is version 3.3 and is Ubuntu 16.04.  To install Ubuntu 18.04 (Bionic) you will need both the v3.3 JetPack as well as the current 4.1.1.  Both may be downloaded from the nVidia Developer [portal][nvidia-developer].  These instructions depend on the utilization of a VMWare Fusion or Workstation virtual machine running Ubuntu version 14.04 LTS. Other virtual machine systems may work (n.b. USB connectivity is required), but Ubuntu 14.04 is **mandatory**.

[nvidia-developer]: https://developer.nvidia.com/embedded/jetpack

The two JetPack versions used in this document are:

+ `JetPack-L4T-4.1.1-linux-x64_b57.run`
+ `JetPack-L4T-3.3-linux-x64_b39.run`

## Step 1 
To maintain separation, create two different directories, one for each version:

```
% mkdir ~/JP33 ~/JP411

```

Then move the downloaded JetPacks into the respective directory:

```
% mv JetPack-L4T-3.3-linux-x64_b39.run ~/JP33/
% mv JetPack-L4T-4.1.1-linux-x64_b57.run ~/JP411/
```
## Step 2
Each JetPack will download a variety of additional items that may be necessary in future development.  First run the earlier version:

```
% cd ~/JP33 
% bash JetPack-L4T-3.3-linux-x64_b39.run

```

A graphical user-interface provides the ability to configure the JetPack and download additional software; default is _full_ and is recommended.  Once the software has been downloaded and the application indicates it is ready to proceed, quit the JetPack.

Repeat the process for the newer version:

```
% cd ~/JP411
% bash JetPack-L4T-4.1.1-linux-x64_b57.run
```

## Step 3
Once both JetPacks have been configured and downloaded, copy the contents of the newer release to the older:

```
% sudo rsync -a ~/JP411/Xavier/Linux_for_Tegra/rootfs ~/JP33/64_TX2/Linux_for_Tegra/rootfs
```

## Step 4
Once the copy is complete, change directory and run the following command to configure the binaries:

```
% cd ~/JP33/64_TX2/Linux_for_Tegra
% sudo ./apply_binaries.sh
```

## Step 5
When that command completes, reset the TX2 into recovery mode with a USB cable connected and run the following command:

```
% sudo ./flash.sh jetson-tx2 mmcblk0p1
```

If this command results in failure, check whether the nVidia TX is connected by running the `lsusb` command; there should be an entry for `nVidia`.



