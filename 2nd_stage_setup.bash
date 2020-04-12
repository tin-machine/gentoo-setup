#!/bin/bash

source /etc/profile
export PS1="(chroot) $PS1"
emerge-webrsync
emerge --sync

echo "Japan" > /etc/timezone
emerge --config sys-libs/timezone-data

emerge -v dev-vcs/git

# curl -O http://10.10.254.200:8080/assets/gentoo/etc/portage/make.conf
# mv make.conf /mnt/gentoo/etc/portage/make.conf
rm -rf /etc/portage
git clone https://github.com/tin-machine/gentoo-etc-portage.git /etc/portage

echo "ja_JP.UTF-8 UTF-8" > /etc/locale.gen

cat - << EOS >> ~/.bashrc
export USE_CCACHE=1
export CCACHE_DIR=~/.ccache
# export set CC='ccache gcc'
EOS

# システムのプロファイルは17 systemd にする
profile=$(eselect profile list |grep '17.0/systemd' | awk '{print $1}' | sed -e 's/\[//' -e 's/\]//')
eselect profile set ${profile}
# ロケールは ja_JP.utf8
eselect_locale=$(eselect locale list |grep 'ja_JP.utf8' | awk '{print $1}' | sed -e 's/\[//' -e 's/\]//')
eselect locale set ${eselect_locale}

emerge -v gentoo-sources genkernel dev-util/ccache
emerge -v net-misc/dhcpcd net-misc/openssh tmux vim pciutils sudo metalog fcron mlocate grub
LANG='C' useradd -m -G users,portage,wheel -s /bin/bash inoue
echo 'add password'
LANG='C' passwd inoue

eselect editor set 3
visudo

cd /usr/src/linux
make menuconfig
make -j6 && make modules_install && make install && genkernel --install initramfs && grub-install /dev/sda && grub-mkconfig -o /boot/grub/grub.cfg

e2label /dev/sda2 boot
e2label /dev/sda4 root
mkswap -L swap /dev/sda3

swapoff /dev/sda3
mkswap -L swap /dev/sda3
swapon LABEL=swap

cat - << EOS > /etc/fstab
LABEL=boot    /boot       ext4    noauto,noatime  1 2
LABEL=root    /           ext4    noatime         0 1
LABEL=swap    none        swap    sw              0 0
EOS

rc-update add sshd default
rc-update add metalog default
rc-update add fcron default
crontab /etc/crontab

date
