#!/bin/bash

emerge -v app-portage/gentoolkit

emerge -v xfce-base/xfwm4 xfce-base/xfce4-panel xfce-base/xfce4-settings xfce-base/xfce4-session
emerge -v x11-terms/mlterm

# 他のebuildを使うため、 layman をインストール
emerge -v app-portage/layman

# 下記コマンドを実行して -5 、これは全てマージする
etc-update --automode -5
emerge -v x11-misc/lightdm 


cat - << EOS > /etc/conf.d/xdm
CHECKVT=7
DISPLAYMANAGER="lightdm"
EOS

rc-update add dbus default
rc-update add xdm default

emerge -a media-fonts/vlgothic app-i18n/mozc app-i18n/fcitx

# compize セットアップ https://github.com/ethus3h/compiz-reloaded-overlay
emerge --ask x11-wm/compiz-meta xfce-base/xfwm4 xfce-base/xfce4-panel xfce-base/xfce4-settings xfce-base/xfce4-session
