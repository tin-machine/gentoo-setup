#!/bin/bash

source /etc/profile
export PS1="(chroot) $PS1"
emerge-webrsync
emerge --sync

MAKEOPTS="-j8" emerge -v gentoo-sources 
cd /usr/src/linux && curl -O https://raw.githubusercontent.com/tin-machine/gentoo-setup/master/usr/src/linux/.config && make menuconfig

LANG='C' useradd -m -G users,portage,wheel -s /bin/bash inoue
echo 'add user password'
LANG='C' passwd inoue

echo "Japan" > /etc/timezone
emerge --config sys-libs/timezone-data

emerge -v dev-vcs/git dev-util/ccache sys-devel/distcc

cat - << EOS >> ~/.bashrc
export USE_CCACHE=1
export CCACHE_DIR=~/.ccache
# export CC='ccache gcc'
EOS

rm -rf /etc/portage
git clone https://github.com/tin-machine/gentoo-etc-portage.git /etc/portage

# システムのプロファイルは17 systemd にする
profile=$(eselect profile list |grep '17.0/systemd' | awk '{print $1}' | sed -e 's/\[//' -e 's/\]//')
eselect profile set ${profile}
# ロケールは ja_JP.utf8
eselect_locale=$(eselect locale list |grep 'ja_JP.utf8' | awk '{print $1}' | sed -e 's/\[//' -e 's/\]//')
eselect locale set ${eselect_locale}

echo "ja_JP.UTF-8 UTF-8" > /etc/locale.gen

echo 'GRUB_CMDLINE_LINUX="init=/usr/lib/systemd/systemd"' >> /etc/default/grub

etc-update --automode -5
echo 'sys-apps/dbus systemd' > /etc/portage/package.use/dbus
emerge -vDN @world

emerge -v net-misc/dhcpcd net-misc/openssh tmux vim pciutils sudo metalog fcron mlocate grub sys-kernel/genkernel-next sys-kernel/dracut 

sed -i -e 's/^#UDEV/UDEV/' /etc/genkernel.conf
echo 'MAKEOPTS="-j9"' >> /etc/genkernel.conf
echo 'KERNEL_CC="ccache gcc"' >> /etc/genkernel.conf
echo 'UTILS_CC="ccache gcc"' >> /etc/genkernel.conf
cd /usr/src/linux && CC='ccache gcc' make -j6 && make modules_install && make install && genkernel --install all && grub-install /dev/sda && grub-mkconfig -o /boot/grub/grub.cfg

eselect editor set 3
. /etc/profile

echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

e2label /dev/sda2 boot
e2label /dev/sda4 root

swapoff /dev/sda3
mkswap -L swap /dev/sda3
swapon LABEL=swap

cat - << EOS > /etc/fstab
LABEL=boot    /boot       ext4    noauto,noatime  1 2
LABEL=root    /           ext4    noatime         0 1
LABEL=swap    none        swap    sw              0 0
EOS

# ネットワーク
echo '[Match]
Name=en*
 
[Network]
DHCP=yes' > /etc/systemd/network/50-dhcp.network

systemctl enable systemd-networkd.service

ln -snf /run/systemd/resolve/resolv.conf /etc/resolve.conf
systemctl enable systemd-resolved.service

systemctl enable sshd.service

systemctl preset-all

emerge -C sys-apps/sysvinit sys-apps/openrc

date
