#!/bin/sh
echo "hello"
sudo apt-get update
sudo apt-get install -y nfs-common
sudo mkdir -p /mnt/disks/filestore
sudo mount -o nolock ${filestore_ip}:/cloudroot_share /mnt/disks/filestore