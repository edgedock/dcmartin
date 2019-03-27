# `RPI.md` - Install on Raspberry Pi Model 3B+

# Hardware Required

1. [RaspberryPi Model 3B+][device]
1. 16 Gbyte microSD card (32 Gbyte recommended)
1. Micro-USB 5V 3A [power-supply][power-supply] and cable
1. USB SSD drive (_optional_)

[device]: https://www.raspberrypi.org/products/raspberry-pi-3-model-b-plus
[power-supply]: https://www.amazon.com/gp/product/B072FTJH73/ref=ppx_yo_dt_b_asin_title_o00_s00?ie=UTF8&psc=1

# Software Required

+ Balena [Etcher][etcher-io] GUI application for Windows, macOS, LINUX 

[etcher-io]: http://etcher.io/

# Instructions
Perform the following in the order listed to setup the RPi3B+ with appropriate hardware and software to run Open Horizon patterns and services.

## Step 1

Download [Raspbian][raspbian-downloads] for RaspberryPi Model 3B+ and copy the the uncompressed image to the SD card using Etcher  (n.b. <ins>unset option</ins> `Auto un-mount on success`)


[raspbian-downloads]: https://www.raspberrypi.org/downloads/raspbian/

Create `ssh` file in root directory of flashed SD card, e.g. on macOS it is typically `/Volume/boot`:

```
sudo touch /Volume/boot/ssh
```

Create `wpa_supplicant.conf` file in root directory of flashed SD card with appropriate `%%SSID%%` and `%%PASSWORD%%`:

```
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
network={
    ssid="%%SSID%%"
    psk="%%PASSWORD%%"
    key_mgmt=WPA-PSK
}
```

Eject SD card:

```
diskutil eject /Volume/boot
```

## Step 2
Insert flashed and configured SD card into RPi3B+ and attach optional external SSD storage device.  Connect micro-USB cable and power-supply.  RPi3B+ will boot and the device will register with the local DHCP server using the name `raspberrypi`.  To identify the RPi3B+ on the LAN, run the following command to scan the network for all devices matching `raspberry`:

```
sudo nmap -sn -T5 192.168.1.0/24 | egrep -B 2 -i raspberry
```

_Example output_:

```
Nmap scan report for 192.168.1.219
Host is up (0.21s latency).
MAC Address: B8:27:EB:14:51:15 (Raspberry Pi Foundation)
--
Nmap scan report for 192.168.1.220
Host is up (0.21s latency).
MAC Address: B8:27:EB:ED:F0:55 (Raspberry Pi Foundation)
```

## Step 3
Copy SSH keys from the host to the default `pi` account; if SSH keys do not exist, use the `ssh-keygen` command to create.

```
ssh-copy-id pi@192.168.1.220
```

And change the default password for the `pi` account:

```
ssh pi@192.168.1.220 'sudo passwd pi'
```

## Step 4
Install Docker latest release directly from [Docker][docker-com]:

```shell
ssh pi@192.168.1.220 'wget -qO - get.docker.com | sudo bash'
```

## Step 5
Install Open Horizon packages

```
REPO=updates
LIST=/etc/apt/sources.list.d/bluehorizon.list
URL=http://pkg.bluehorizon.network
KEY=${URL}/bluehorizon.network-public.key
ssh pi@192.168.1.220 "wget -qO - ${KEY} | sudo apt-key add -"
ssh pi@192.168.1.220 "echo deb [arch=armhf,arm64,amd64] ${URL}/linux/ubuntu xenial-${REPO} main > /tmp/$$ && sudo mv /tmp/$$ ${LIST}"
ssh pi@192.168.1.220 'sudo apt-get update -y && sudo apt-get install -y bluehorizon horizon horizon-cli'
```

## Step 6
Create development account for current user:

```
ssh pi@192.168.1.220 sudo adduser ${USER}
```

Enter account specifics, including new password, and then copy host SSH credentials to account:

```
ssh-copy-id ${USER}@192.168.1.220 
```

Enable _account_ for automated `sudo` (i.e. no password required); sequence prompts for password:

```shell
ssh pi@192.168.1.220 "echo ${USER} 'ALL=(ALL) NOPASSWD: ALL' > /tmp/010_${USER}-nopasswd"
ssh pi@192.168.1.220 "chmod 400 /tmp/010_${USER}-nopasswd"
ssh pi@192.168.1.220 "sudo chown root /tmp/010_${USER}-nopasswd"
ssh pi@192.168.1.220 "sudo mv /tmp/010_${USER}-nopasswd /etc/sudoers.d/"
```

## Step 7
Configure _account_ for access to Docker commands; logout and login to take effect.

```
ssh pi@192.168.1.220 "sudo addgroup ${USER} docker"
ssh pi@192.168.1.220 "sudo addgroup ${USER} sudo"
```

## Step 8
Once SSH access has been enabled properly, restrictions on access should then be applied; execute the following commands to disable password-based login (as root, use `sudo -s`):

```
cat > /etc/ssh/ssh_config << EOF
Host *
    SendEnv LANG LC_*
    HashKnownHosts yes
    GSSAPIAuthentication yes
EOF
```

```
cat > /etc/ssh/sshd_config << EOF
ChallengeResponseAuthentication no
PasswordAuthentication no
PubkeyAuthentication yes
UsePAM no
EOF
```

# Optional

## A. Add External SSD
Add external SSD storage device and copy Docker and user home directories from SD card to external SSD.  ; use the `lsblk` command to identify the actual identifier.

```
sudo lsblk
```
_Example output_:

```
NAME         MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
loop0          7:0    0    16M  1 loop 
sda            8:0    0 223.6G  0 disk /media/dcmartin/336fb189-d569-46ce-b271-02cb8e46d27d
mtdblock0     31:0    0     4M  0 disk 
mmcblk0      179:0    0  29.8G  0 disk 
├─mmcblk0p1  179:1    0  29.8G  0 part /
├─mmcblk0p2  179:2    0   128K  0 part 
├─mmcblk0p3  179:3    0   448K  0 part 
├─mmcblk0p4  179:4    0   576K  0 part 
├─mmcblk0p5  179:5    0    64K  0 part 
├─mmcblk0p6  179:6    0   192K  0 part 
├─mmcblk0p7  179:7    0   576K  0 part 
├─mmcblk0p8  179:8    0    64K  0 part 
├─mmcblk0p9  179:9    0   640K  0 part 
├─mmcblk0p10 179:10   0   448K  0 part 
├─mmcblk0p11 179:11   0   128K  0 part 
└─mmcblk0p12 179:12   0    80K  0 part 
```

The following commands presume `sda` as the device for the external drive

```
sudo -s
mkdir /sda
echo '/dev/sda /sda ext4' >> /etc/fstab
mount -a
```

Install `rsync` to copy files from SD card to SSD 

```
sudo apt install -y rsync
```

Relocate `/var/lib/docker` to SSD:

```
sudo -s
systemctl stop docker
rsync -a /var/lib/docker /sda
rm -fr /var/lib/docker
ln -s /sda/docker /var/lib
systemctl start docker
```

Relocate `/home` to SSD:

```
sudo -s
rsync -a /home /sda
rm -fr /home
ln -s /sda/home /
```

Logout and login to complete relocation to new home directory.
