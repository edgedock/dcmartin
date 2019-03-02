# Install on nVidia TX2 w/ Ubuntu 18

The nVidia TX2 is configured using the nVidia JetPack.  The latest version for TX2 is version 3.3 and is Ubuntu 16.04.  To install you will need both the v3.3 JetPack as well as the current 4.1.1.  Both may be downloaded from the [nVidia Developer portal][nvidia-developer].  These instructions depend on the utilization of a VMWare Fusion or Workstation virtual machine running Ubuntu version 14.04 LTS. Other virtual machine systems may work (n.b. USB connectivity is required) as well as other versions of Ubuntu on the host computer; refer to the nVidia Developer portal for more information.

[nvidia-developer]: https://developer.nvidia.com/embedded/jetpack

The two JetPack versions used in this document are:

+ `JetPack-L4T-4.1.1-linux-x64_b57.run`
+ `JetPack-L4T-3.3-linux-x64_b39.run`

## Step 1 
To maintain separation, create two different directories, one for each version:

```
mkdir ~/JP33 ~/JP411
```

Then move the downloaded JetPacks into the respective directory:

```
mv JetPack-L4T-3.3-linux-x64_b39.run ~/JP33/
mv JetPack-L4T-4.1.1-linux-x64_b57.run ~/JP411/
```
## Step 2
Each JetPack will download a variety of additional items that may be necessary in future development.  First run the earlier version:

```
cd ~/JP33 
bash JetPack-L4T-3.3-linux-x64_b39.run
```

A graphical user-interface provides the ability to configure the JetPack and download additional software; default is _full_ and is recommended.  Once the software has been downloaded and the application indicates it is ready to proceed, quit the JetPack.

Repeat the process for the newer version:

```
cd ~/JP411
bash JetPack-L4T-4.1.1-linux-x64_b57.run
```

## Step 3
Once both JetPacks have been configured and downloaded, remove the original `rootfs/` directory, make a new one, then uncompress and copy the contents of the newer release operating system:

```
sudo rm -fr ~/JP33/64_TX2/Linux_for_Tegra/rootfs
mkdir ~/JP33/64_TX2/Linux_for_Tegra/rootfs
bunzip2 -c ~/JP411/jetpack_download/Tegra_Linux_Sample-Root-Filesystem_R3.1.1.0_aarch64.tbz2 \
  | ( cd ~/JP33/64_TX2/Linux_for_Tegra/rootfs/ ; tar xf - )
bunzip2 -c ~/JP411/jetpack_download/Jetson_Linux_R3.1.1.0_aarch64.tbz2 \
  | ( cd ~/JP33/64_TX2 ; sudo tar xf - )
```

## Step 4
Once the copy is complete, change directory and run the following command to configure the binaries:

```
cd ~/JP33/64_TX2/Linux_for_Tegra
sudo ./apply_binaries.sh
```

## Step 5
When that command completes, reset the TX2 into recovery mode with a USB cable connected and run the following command:

```
sudo ./flash.sh jetson-tx2 mmcblk0p1
```
If this command results in failure, check whether the nVidia TX is connected by running the `lsusb` command; there should be an entry for `nVidia`.

## Step 6
After rebooting the TX2, login with default login `nvidia` with password `nvidia` and update:

```
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y
```

## Step 7
Add external SSD hard drive:

```
sudo -s
mkdir /sda
echo '/dev/sda /sda /ext4' >> /etc/fstab
mount -a
```

Install `rsync`

```
sudo apt install -y rsync
```

Relocate `/var/lib/docker` to SSD:

```
sudo -s
systemctl stop docker
rsync -a /var/lib/docker /sda/docker
rm -fr /var/lib/docker
ln -s /sda/docker /var/lib/docker
systemctl start docker
```

Relocate `/home` to SSD:

```
sudo -s
rsync -a /home /sda/home
rm -fr /home
ln -s /sda/home /home
```

## Step 9
Secure built-in accounts `nvidia` and `ubuntu`, create new account, add group permissions:

```
sudo passwd nvidia
sudo passwd ubuntu
sudo adduser <yourid>
sudo addgroup <yourid> sudo
sudo addgroup <yourid> docker
```

Logout of `nvidia` account and re-login with `<yourid>`.

## Step X
Install Open Horizon

```
wget -qO ibm.biz/horizon-setup | sudo bash
```





