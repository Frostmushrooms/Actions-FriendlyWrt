#!/bin/bash
# 自定义编译配置 - NanoPi R28S (rk3528) / FriendlyWrt 24.10 / 旁路由
# 由 .github/workflows/build.yml 的 "Apply customizations" 步骤在 project/ 目录下 source

set -e

echo ">>> [custom] 关闭 SDK/IB/toolchain，缩小编译量"
sed -i -e '/CONFIG_MAKE_TOOLCHAIN=y/d' configs/rockchip/01-nanopi
sed -i -e 's/CONFIG_IB=y/# CONFIG_IB is not set/g' configs/rockchip/01-nanopi
sed -i -e 's/CONFIG_SDK=y/# CONFIG_SDK is not set/g' configs/rockchip/01-nanopi

echo ">>> [custom] 添加 PassWall / OpenClash 第三方 feed"
cd friendlywrt
if ! grep -q "passwall" feeds.conf.default; then
	cat >> feeds.conf.default <<'FEEDS'
src-git pw_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main
src-git pw_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git;main
src-git openclash https://github.com/vernesong/OpenClash.git;master
FEEDS
fi
./scripts/feeds update pw_packages pw_luci openclash
./scripts/feeds install -a -p pw_packages
./scripts/feeds install -a -p pw_luci
./scripts/feeds install -a -p openclash
cd ..

echo ">>> [custom] 写入插件配置"
cat >> configs/rockchip/01-nanopi <<'CONF'
# ---- PassWall ----
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-i18n-passwall-zh-cn=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_SingBox=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Trojan_Plus=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_simple_obfs=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Trojan_GO=y
CONFIG_PACKAGE_chinadns-ng=y
CONFIG_PACKAGE_tcping=y
# ---- OpenClash ----
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_luci-i18n-openclash-zh-cn=y
# ---- 官方源里的其它插件 ----
CONFIG_PACKAGE_luci-app-homeproxy=y
CONFIG_PACKAGE_luci-i18n-homeproxy-zh-cn=y
CONFIG_PACKAGE_luci-app-argon-config=y
CONFIG_PACKAGE_luci-i18n-argon-config-zh-cn=y
CONFIG_PACKAGE_luci-app-filebrowser=y
CONFIG_PACKAGE_luci-i18n-filebrowser-zh-cn=y
CONFIG_PACKAGE_luci-app-autocore=y
CONFIG_PACKAGE_luci-app-automount=y
CONFIG_PACKAGE_luci-i18n-package-manager-zh-cn=y
CONFIG_PACKAGE_luci-i18n-ttyd-zh-cn=y
CONFIG_PACKAGE_luci-i18n-firewall-zh-cn=y
CONFIG_PACKAGE_luci-i18n-ddns-zh-cn=y
CONFIG_PACKAGE_luci-i18n-samba4-zh-cn=y
CONFIG_PACKAGE_openssh-sftp-server=y
CONF

echo ">>> [custom] 注入旁路由默认配置"
mkdir -p files/etc/uci-defaults
cp -f ../scripts/overlay/etc/uci-defaults/* files/etc/uci-defaults/
chmod +x files/etc/uci-defaults/*

echo ">>> [custom] done"
