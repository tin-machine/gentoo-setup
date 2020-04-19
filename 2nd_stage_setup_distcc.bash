#!/bin/bash

echo 'add root password'
passwd root

LANG='C' useradd -m -G users,portage,wheel -s /bin/bash inoue
echo 'add user password'
LANG='C' passwd inoue

source /etc/profile
export PS1="(chroot) $PS1"
emerge-webrsync
emerge --sync

MAKEOPTS="-j6" emerge -v gentoo-sources 
cd /usr/src/linux && curl -O https://raw.githubusercontent.com/tin-machine/gentoo-setup/master/usr/src/linux/.config && make oldconfig && make menuconfig

echo "Japan" > /etc/timezone
emerge --config sys-libs/timezone-data

MAKEOPTS="-j6"  emerge -v dev-vcs/git sys-devel/distcc

rm -rf /etc/portage
git clone https://github.com/tin-machine/gentoo-etc-portage.git /etc/portage

gcc_options=$(gcc -v -E -x c -march=native -mtune=native - < /dev/null 2>&1 | grep cc1 | perl -pe 's/^.* - //g;')
sed -i -e "s/^CFLAGS.*/CFRAGS=\"-march=${gcc_options} \$\{COMMON_FLAGS\}\"/" /etc/portage/make.conf

# システムのプロファイルは17 systemd にする
profile=$(eselect profile list |grep '17.0/systemd' | awk '{print $1}' | sed -e 's/\[//' -e 's/\]//')
eselect profile set ${profile}
# ロケールは ja_JP.utf8
eselect_locale=$(eselect locale list |grep 'ja_JP.utf8' | awk '{print $1}' | sed -e 's/\[//' -e 's/\]//')
eselect locale set ${eselect_locale}

echo "ja_JP.UTF-8 UTF-8" > /etc/locale.gen

echo 'GRUB_CMDLINE_LINUX="init=/usr/lib/systemd/systemd"' >> /etc/default/grub

# emergeは distcc-config の内容を見てくれる
distcc-config --set-hosts 10.10.254.16
cat - << EOS >> /etc/portage/make.conf
MAKEOPTS="-j20 -l4"
FEATURES="distcc"
EOS

# distcc で分散コンパイルしたいため、gcc( binutils に含まれる )のバージョンを揃える
eselect_binutils=$(eselect binutils list |grep '2.32' | awk '{print $1}' | sed -e 's/\[//' -e 's/\]//')
eselect binutils set ${eselect_binutils}

etc-update --automode -5
echo 'sys-apps/dbus systemd' > /etc/portage/package.use/dbus
emerge -vDN @world

emerge -v net-misc/dhcpcd net-misc/openssh tmux vim pciutils sudo metalog fcron mlocate grub sys-kernel/genkernel-next sys-kernel/dracut 

# kernel での make では distcc-config の内容は見てくれず、 /etc/distcc/hosts と $PATH の内容を見ていた
echo '10.10.254.16' > /etc/distcc/hosts
export PATH="/usr/lib/ccache/bin:/usr/lib/distcc/bin:${PATH}"

cat - << EOS >> /etc/genkernel.conf
UDEV="yes"
MAKEOPTS="-j20"
# KERNEL_CC="distcc gcc"  # $PATH に distcc が含まれる場合、不要
# UTILS_CC="distcc gcc" # $PATH に distcc が含まれる場合、不要
EOS

cd /usr/src/linux && make -j20 && make modules_install && make install && genkernel --install all && grub-install /dev/sda && grub-mkconfig -o /boot/grub/grub.cfg

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
systemctl preset-all
systemctl enable sshd.service

emerge -C sys-apps/sysvinit sys-apps/openrc

date
