#!/bin/bash

if [ -z $(command -v "VBoxManage") ]; then
  echo "*** ERROR $0 $$: Virtual Box is not installed"
  exit 1
fi

dev_node=$1
if [ -z "${dev_node}" ]; then
  dev_node="/dev/disk2"
fi
vm=$2
if [ -z "${vm}" ]; then
  vm="horizon"
fi

# check if the first parameter points to a filename that looks like a
# disk device node
if  [[ $dev_node != /dev/disk? ]] ; then
  echo "*** ERROR $0 $$: Device $dev_node does not start with /dev/disk, but it should."
  exit 1
elif [ ! -e "${dev_node}" ]; then
  echo "*** ERROR $0 $$: Device $dev_node does not exist"
  exit 1
fi

echo "Setting permissions to disk ..."
sudo chmod 666 $dev_node
if [ $? != 0 ]; then 
  echo "*** ERROR $0 $$: Could not set device node permissions. Cannot proceed!"
  exit 1
fi

echo "Unmounting SD card from system ..."
sudo diskutil unmountDisk $dev_node
if [ $? != 0 ]; then
  echo "*** ERROR $0 $$: Could not unmount disk $dev_node. Cannot proceed!"
  exit 1
fi

vmdk_file=/tmp/$$.vmdk
if [ -e $vmdk_file ]; then
  echo "WARN: VMDK file should not yet exist!"
  rm -f "${vmdk_file}"
fi

echo "Creating VMDK file that maps to disk $dev_node"
sudo VBoxManage internalcommands createrawvmdk -filename $vmdk_file -rawdisk $dev_node
if [ $? != 0 ]; then
  echo "*** ERROR $0 $$: Could not create VMDK file $vmdk_file. Cannot proceed!"
  exit 1
fi

echo "Setting permissions to file node ..."
sudo chmod 666 $vmdk_file
if [ $? != 0 ]; then 
  echo "*** ERROR $0 $$: Could not set vdmk file permissions. Cannot proceed!"
  exit 1
fi

echo "Extracting first SATA port ..."
echo VBoxManage showvminfo "$vm"
port=`VBoxManage showvminfo "$vm"  | grep '^SATA' | tail -1 | awk '{print $2}' | sed -e 's/(//;s/,//'`
if [ $? != 0 ]; then
  echo "*** ERROR $0 $$: Could not find SATA port. You need to manually attach $vmdk_file to the VM."
  exit 1
fi

# take next port
let "port+=1"

echo "Unmounting SD card from system ..."
sudo diskutil unmountDisk $dev_node
if [ $? != 0 ]; then
  echo "*** ERROR $0 $$: Could not unmount disk $dev_node. Cannot proceed!"
  exit 1
fi

echo "Attaching VMDK file to virtual machine ..."
VBoxManage storageattach "$vm" --medium $vmdk_file --storagectl SATA --port $port --type hdd
if [ $? != 0 ]; then
  echo "*** ERROR $0 $$: Could not attach VMDK file to VM. You need to do this manually."
  exit 1
fi

echo "Done!"

echo "You can now start the virtual machine. Please make sure that any partitions on the disk are unmounted when the machine is started. Otherwise you will get an error message."
