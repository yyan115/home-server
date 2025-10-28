#!/bin/bash
# RAID1 setup for 2x 8TB HDDs
# Written script to keep track of raid commands
# This will erase all data on /dev/sda and /dev/sdb

set -e  # Exit on error

echo "Installing mdadm..."
sudo apt update
sudo apt install -y mdadm

echo "Wiping existing partitions..."
sudo wipefs -a /dev/sda
sudo wipefs -a /dev/sdb

echo "Creating new GPT partition tables..."
sudo parted /dev/sda mklabel gpt
sudo parted /dev/sda mkpart primary 0% 100%
sudo parted /dev/sdb mklabel gpt
sudo parted /dev/sdb mkpart primary 0% 100%

echo "Creating RAID1 array..."
sudo mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1

echo "Formatting as ext4..."
sudo mkfs.ext4 /dev/md0

echo "Creating mount point..."
sudo mkdir -p /mnt/raid

echo "Mounting RAID array..."
sudo mount /dev/md0 /mnt/raid

echo "Getting RAID UUID..."
RAID_UUID=$(sudo blkid -s UUID -o value /dev/md0)
echo "RAID UUID: $RAID_UUID"

echo "Adding to /etc/fstab..."
echo "UUID=$RAID_UUID /mnt/raid ext4 defaults 0 2" | sudo tee -a /etc/fstab

echo "Saving mdadm config..."
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
sudo update-initramfs -u

echo "RAID setup complete!"
echo "Check status with: cat /proc/mdstat"
