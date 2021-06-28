#!/bin/bash

# equery を使いたいので gentoolkit インストール
# 他のebuildを使うため、 layman をインストール
emerge -v app-portage/gentoolkit app-portage/layman

sed -i -e 's/check_official : Yes/check_official : No/' /etc/layman/layman.cfg
layman -o https://github.com/ethus3h/compiz-reloaded-overlay/raw/master/compiz-reloaded.xml -f -a compiz-reloaded

# etc-update を実行して -5 、これは全てマージする
# etc-update で下記が切り替わった
# Automerging trivial changes in: /etc/udev/udev.conf
# Replacing /etc/default/grub with /etc/default/._cfg0000_grub
# Replacing /etc/distcc/hosts with /etc/distcc/._cfg0000_hosts
etc-update --automode -5

# etc-update後 /etc/default/grub , /etc/distcc/hosts が上書きされたので再度
echo 'GRUB_CMDLINE_LINUX="init=/usr/lib/systemd/systemd"' >> /etc/default/grub
echo '10.10.254.16' > /etc/distcc/hosts

echo 'sys-auth/polkit -consolekit -elogind systemd' >> /etc/portage/package.use/compiz

# compize セットアップ https://github.com/ethus3h/compiz-reloaded-overlay
emerge -v x11-misc/lightdm xfce-base/xfwm4 xfce-base/xfce4-panel xfce-base/xfce4-settings xfce-base/xfce4-session x11-terms/mlterm media-fonts/vlgothic app-i18n/mozc app-i18n/fcitx
# x11-wm/compiz-meta 

# opengl つけた方が良いかも
# [ebuild  N     ] xfce-base/xfwm4-4.14.0-r1::gentoo  USE="-opengl -startup-notification -xcomposite -xpresent" 1,097 KiB

# simpleccsm , manager , full を検討した方が良いかも
# [ebuild  N    ~] x11-wm/compiz-meta-0.8.18::compiz-reloaded  USE="ccsm emerald fusionicon -boxmenu -debugutils -full -manager -simpleccsm" 0 KiB

# はじめから systemd に policykit つけた方が良いかも
# [ebuild   R    ] sys-apps/systemd-244.3:0/2::gentoo  USE="acl gcrypt kmod lz4 pam pcre policykit* resolvconf seccomp (split-usr) sysv-utils (-apparmor) -audit -build -cgroup-hybrid -cryptsetup -curl -dns-over-tls -elfutils -gnuefi -http -idn -importd -lzma -nat -qrcode (-selinux) -static-libs -test -vanilla -xkb" 0 KiB


# Calculating dependencies... done!
# [ebuild  N    ~] x11-plugins/compiz-plugins-meta-0.8.18  USE="-community -compicc -experimental -extra -extra-snowflake-textures"
# [ebuild  N    ~] dev-python/compizconfig-python-0.8.18  PYTHON_SINGLE_TARGET="python3_6 -python2_7"
# [ebuild  N    ~] x11-misc/ccsm-0.8.18  USE="-gtk3" PYTHON_SINGLE_TARGET="python3_6 -python2_7"
# [ebuild  N    ~] x11-apps/fusion-icon-0.2.4-r2  USE="gtk3 -qt5" PYTHON_SINGLE_TARGET="python3_6 -python2_7"
# [ebuild  N    ~] x11-wm/emerald-0.8.18  USE="-gtk3"
# [ebuild  N    ~] x11-themes/emerald-themes-0.8.18
# [ebuild  N    ~] x11-wm/compiz-meta-0.8.18  USE="ccsm emerald fusionicon -boxmenu -debugutils -full -manager -simpleccsm"

groupadd -r autologin
gpasswd -a inoue autologin

patch -u /etc/lightdm/lightdm.conf <<EOS
--- lightdm.conf        2020-04-21 19:43:38.746860749 +0900
+++ lightdm.conf.new    2020-04-22 03:18:33.726157154 +0900
@@ -87,6 +87,8 @@
 # exit-on-failure = True if the daemon should exit if this seat fails
 #
 [Seat:*]
+autologin-user=inoue
+autologin-session=xfce
 #type=local
 #pam-service=lightdm
 #pam-autologin-service=lightdm-autologin
EOS

cat - << EOS > /etc/conf.d/xdm
CHECKVT=7
DISPLAYMANAGER="lightdm"
EOS

systemctl enable lightdm
# rc-update add dbus default
# rc-update add xdm default
