#!/bin/bash

cd lede

(
    cd package
    git clone https://github.com/tuanqing/install-program package/install-program
    echo "add other app well feeds.conf.default success"
)

cat >feeds.conf.default <<-EOF
# src-git luci https://git.openwrt.org/project/luci.git;openwrt-19.07
# src-git packages https://git.openwrt.org/feed/packages.git
src-git luci https://github.com/Lienol/openwrt-luci.git;18.06
src-git packages https://github.com/Lienol/openwrt-packages.git;main
src-git routing https://git.openwrt.org/feed/routing.git
src-git telephony https://git.openwrt.org/feed/telephony.git
src-git helloworld https://github.com/fw876/helloworld.git
src-git kenzo https://github.com/kenzok8/openwrt-packages.git
src-git small https://github.com/kenzok8/small.git
EOF

rm -rf package/lean/{samba4,luci-app-samba4,luci-app-ttyd}
svn co https://github.com/Lienol/openwrt/branches/main/package/libs/{libaudit,musl-fts,libsemanage} package/libs

./scripts/feeds update -a
./scripts/feeds install -a

zzz="package/lean/default-settings/files/zzz-default-settings"
sed -i 's/samba/samba4/' $zzz
# sed -i 's#openwrt.proxy.ustclug.org#mirrors.bfsu.edu.cn\\/openwrt#' $zzz
sed -i "/openwrt_luci/i sed -i '/Lienol/d' /etc/opkg/distfeeds.conf" $zzz
sed -i "/openwrt_luci/i sed -i '/helloworld/d' /etc/opkg/distfeeds.conf" $zzz

packages=" \
brcmfmac-firmware-43430-sdio brcmfmac-firmware-43455-sdio kmod-brcmfmac wpad \
kmod-fs-ext4 kmod-fs-vfat kmod-fs-exfat dosfstools e2fsprogs antfs-mount \
kmod-usb2 kmod-usb3 kmod-usb-storage kmod-usb-storage-extras kmod-usb-storage-uas \
blkid lsblk parted fdisk cfdisk losetup resize2fs tune2fs pv unzip \
lscpu htop iperf3 curl lm-sensors install-program 
"
sed -i '/FEATURES+=/ { s/cpiogz //; s/ext4 //; s/ramdisk //; s/squashfs //; }' \
    target/linux/armvirt/Makefile
for x in $packages; do
    sed -i "/DEFAULT_PACKAGES/ s/$/ $x/" target/linux/armvirt/Makefile
done

rm -f package/lean/shadowsocksr-libev/patches/0002-Revert-verify_simple-and-auth_simple.patch
sed -i '383,393 d' package/lean/shadowsocksr-libev/patches/0001-Add-ss-server-and-ss-check.patch
sed -i 's/PKG_RELEASE:=5/PKG_RELEASE:=6/' package/lean/shadowsocksr-libev/Makefile
sed -i '/PKG_SOURCE_VERSION:=/d' package/lean/shadowsocksr-libev/Makefile
sed -i '/PKG_SOURCE_URL/a PKG_SOURCE_VERSION:=4799b312b8244ec067b8ae9ba4b85c877858976c' \
    package/lean/shadowsocksr-libev/Makefile
    
# Modify default IP
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate
# firewall custom
echo "iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE" >> package/network/config/firewall/files/firewall.user

cat >.config <<-EOF
## target
CONFIG_TARGET_armvirt=y
CONFIG_TARGET_armvirt_64=y
CONFIG_TARGET_armvirt_64_Default=y
## luci app
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_docker-ce=y
CONFIG_PACKAGE_luci-app-docker=y
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Trojan=y
## luci theme
CONFIG_PACKAGE_luci-theme-netgear=y
## remove
# CONFIG_PACKAGE_chinadns-ng is not set
# CONFIG_PACKAGE_kmod-crypto-user is not set
# CONFIG_PACKAGE_libcares is not set
# CONFIG_PACKAGE_libhttp-parser is not set
# CONFIG_PACKAGE_libnghttp2 is not set
# CONFIG_PACKAGE_luci-app-unblockmusic is not set
# CONFIG_PACKAGE_luci-app-arpbind is not set
# CONFIG_PACKAGE_luci-app-autoreboot is not set
# CONFIG_PACKAGE_luci-app-vsftpd is not set
# CONFIG_PACKAGE_vsftpd-alt is not set
# CONFIG_PACKAGE_luci-lib-fs is not set
# CONFIG_PACKAGE_node is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_kcptun is not set										   
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ChinaDNS_NG is not set
# CONFIG_DEFAULT_luci-app-adbyby-plus is not set
# CONFIG_PACKAGE_luci-app-adbyby-plus is not set
# CONFIG_UnblockNeteaseMusic_Go is not set
# CONFIG_UnblockNeteaseMusic_NodeJS is not set
# CONFIG_PACKAGE_UnblockNeteaseMusic is not set
# CONFIG_PACKAGE_UnblockNeteaseMusicGo is not set
# CONFIG_PACKAGE_luci-app-flowoffload is not set
# CONFIG_PACKAGE_luci-app-ddns is not set
# CONFIG_PACKAGE_luci-app-wol is not set
# CONFIG_PACKAGE_luci-app-nlbwmon is not set
# CONFIG_PACKAGE_nlbwmon is not set
# CONFIG_PACKAGE_luci-app-ramfree is not set
# CONFIG_PACKAGE_luci-app-ssr-plus is not set# CONFIG_UnblockNeteaseMusic_NodeJS is not set
# CONFIG_PACKAGE_luci-app-webadmin is not set
## others
CONFIG_BRCMFMAC_SDIO=y
CONFIG_LUCI_LANG_en=y
EOF

make defconfig
cat .config



