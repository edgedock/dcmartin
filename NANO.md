# `NANO.md` - Setup and Install for Open Horizon

Setup information for the Nano is at: [JetsonNano-Start][nano-start]

[nano-start]: http://nvidia.com/jetsonnano-start

[nvidia-developer]: https://developer.nvidia.com/embedded/jetpack

# Hardware Required

1. Jetson Nano
1. HDMI or DisplayPort cable and monitor
1. USB keyboard and mouse
1. Wired (RJ45) Ethernet cable and network
1. 32 Gbyte (64 Gbyte recommended)
1. Micro-USB 5V 2.4A power-supply and cable

# Software Required

+ Balena Etcher GUI application for Windows, macOS, LINUX 

# Instructions
Perform the following in the order listed to setup the Jetson Nano with appropriate hardware and software to run Open Horizon patterns and services.

## Step 1
Access [Jetson Nano Start][nano-start], download the Jetson Nano Developer Kit (5.3 Gbyte), and copy the the uncompressed image (12.1 Gbyte) to the SD card using [Etcher][etcher-io]

[etcher-io]: http://etcher.io/

## Step 2
Insert SD card into Nano, connect monitor, keyboard, mouse and optional external SSD storage device.  Connect micro-USB cable connected to power-supply.  Nano will boot and present GUI to setup.
## Step 3
Configure account for access to Docker commands; logout and login to take effect.

```
sudo addgroup ${SUDO_USER} docker
```

## Step 4
Enable account for automated `sudo` (i.e. no password required); prompts for password:

```
sudo -s
echo "${SUDO_USER} ALL=(ALL) NOPASSWD: ALL" >  /etc/sudoers.d/010_${SUDO_USER}-nopasswd
chmod 400  /etc/sudoers.d/010_${SUDO_USER}-nopasswd
```

## Step 5
Remove existing Docker (installed as `docker.io` package):

[docker-com]: http://www.docker.com/

```
apt remove -y docker.io
apt autoremove -y
apt purge -y
```

Install latest release directly from [Docker][docker-com]:

```
wget -qO - get.docker.com | sudo bash
```
## Step 6
Install Open Horizon packages

```
sudo -s
APT_REPO=updates \
  && APT_LIST=/etc/apt/sources.list.d/bluehorizon.list \
  && PUBLICKEY_URL=http://pkg.bluehorizon.network/bluehorizon.network-public.key \
  && wget -qO - "${PUBLICKEY_URL}" | apt-key add - \
  && echo "deb [arch=armhf,arm64,amd64] http://pkg.bluehorizon.network/linux/ubuntu xenial-${APT_REPO} main" > "${APT_LIST}" \
  && apt-get update -y && apt-get install -y bluehorizon horizon horizon-cli
```

## Step 7
Install SSH keys from development environment to Nano account.  The device will _not_ have its assigned name on the LAN until it has been rebooted after initial boot.  To identify the Nano on the LAN, **return to host computer** and run the following command to scan the network for all devices with `nvidia`:

```
sudo nmap -sn -T5 192.168.1.0/24 | egrep -B 2 -i nvidia
```
_Example output_:

```
Nmap scan report for 192.168.1.30
Host is up (0.090s latency).
MAC Address: 00:04:4B:8C:62:2E (Nvidia)
--
Nmap scan report for 192.168.1.206
Host is up (0.0061s latency).
MAC Address: 00:04:4B:CC:48:99 (Nvidia)
```

Copy SSH keys from the development environment to the account created on the Nano; if SSH keys do not exist, use the `ssh-keygen` command to create.

```
ssh-copy-id 192.168.1.206
```

Access from the development environment to the Nano device will be automated; test access using the `ssh` command:

```
ssh 192.168.1.206
```

In addition, the Nano account will not require password for `sudo` access, enabling remote command and control, for example:

```
ssh 192.168.1.206 `sudo apt-get update`
```

## Step 8
Once SSH access has been enabled properly, restrictions on access should then be applied; execute the following commands to disable password-based login:

```
sudo -s
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

## A. Enable WiFi
Turn on WiFi if additional adapter is attached.

```
sudo nmcli dev wifi connect <SSID> password <PASSWORD>
```


## B. Add External SSD
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
echo '/dev/sda /sda /ext4' >> /etc/fstab
mount -a
```

Install `rsync`(n.b. high quality and performance utility) to copy files from SD card to SSD 

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

Logout and login to complete relocation to new home directory.
