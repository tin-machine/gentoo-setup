#!/bin/bash

parted -s /dev/sda mklabel gpt
parted -s /dev/sda mkpart grub 1 3
parted -s /dev/sda set 1 bios_grub on
parted -s /dev/sda mkpart boot 3 1000
parted -s /dev/sda set 2 boot on
parted -s /dev/sda mkpart swap 1000 9000
parted -s /dev/sda mkpart root 9000 100%
parted -s /dev/sda print

mkswap /dev/sda3
swapon /dev/sda3
free -h

mkfs.ext4 /dev/sda2
mkfs.ext4 /dev/sda4

mount /dev/sda4 /mnt/gentoo
mkdir /mnt/gentoo/boot
mount /dev/sda2 /mnt/gentoo/boot

rc-service ntp-client start
sleep 1
hwclock --systohc

cd /mnt/gentoo

links https://www.gentoo.org/downloads/mirrors/
tar xvJpf stage3-*.tar.xz --xattrs
curl -O http://10.10.254.200:8080/assets/gentoo/etc/portage/make.conf
mv make.conf /mnt/gentoo/etc/portage/make.conf

cp -L /etc/resolv.conf /mnt/gentoo/etc/

mount -t proc proc /mnt/gentoo/proc/
mount --rbind /sys /mnt/gentoo/sys/
mount --make-rslave /mnt/gentoo/sys/
mount --rbind /dev /mnt/gentoo/dev/
mount --make-rslave /mnt/gentoo/dev/

cd /mnt/gentoo/root/
curl -O http://10.10.254.200:8080/assets/gentoo/2nd_stage_setup.bash

chroot /mnt/gentoo /bin/bash
