#!/bin/bash

# Add packages
echo "Cloning essential repositories ..."
git clone https://github.com/ophub/luci-app-amlogic --depth=1 clone/amlogic
git clone https://github.com/xiaorouji/openwrt-passwall --depth=1 clone/passwall
# git clone https://github.com/fw876/helloworld.git --depth=1 clone/helloworld

# Update helloworld repo
echo "Updating helloworld repository..."
# git -C clone/helloworld pull

# Remove conflicting packages
echo "Removing conflicting packages..."
rm -rf feeds/luci/applications/luci-app-passwall
# rm -rf feeds/packages/net/shadowsocks-libev
# rm -rf feeds/packages/net/shadowsocksr-libev
# rm -rf feeds/packages/net/v2ray-core
# rm -rf feeds/packages/net/xray-core

# Install packages to feeds
echo "Installing packages to feeds..."
cp -rf clone/amlogic/luci-app-amlogic feeds/luci/applications/
cp -rf clone/passwall/luci-app-passwall feeds/luci/applications/
# cp -rf clone/helloworld/luci-app-ssr-plus feeds/luci/applications/

# Install helloworld packages (contains many SSR plus dependencies)
echo "Installing helloworld packages..."
# cp -rf clone/helloworld/shadowsocksr-libev feeds/packages/net/
# cp -rf clone/helloworld/shadowsocks-rust feeds/packages/net/
# cp -rf clone/helloworld/v2ray-core feeds/packages/net/
# cp -rf clone/helloworld/xray-core feeds/packages/net/
# cp -rf clone/helloworld/trojan feeds/packages/net/
# cp -rf clone/helloworld/chinadns-ng feeds/packages/net/
# cp -rf clone/helloworld/dns2socks feeds/packages/net/
# cp -rf clone/helloworld/microsocks feeds/packages/net/
# cp -rf clone/helloworld/ipt2socks feeds/packages/net/
# cp -rf clone/helloworld/naiveproxy feeds/packages/net/
# cp -rf clone/helloworld/redsocks2 feeds/packages/net/

# Copy additional dependencies if they exist
# [ -d "clone/helloworld/mosdns" ] && cp -rf clone/helloworld/mosdns feeds/packages/net/
# [ -d "clone/helloworld/hysteria" ] && cp -rf clone/helloworld/hysteria feeds/packages/net/
# [ -d "clone/helloworld/tuic-client" ] && cp -rf clone/helloworld/tuic-client feeds/packages/net/
# [ -d "clone/helloworld/v2ray-plugin" ] && cp -rf clone/helloworld/v2ray-plugin feeds/packages/net/
# [ -d "clone/helloworld/dns2socks-rust" ] && cp -rf clone/helloworld/dns2socks-rust feeds/packages/net/

# Install packages via feeds system
echo "Installing packages via feeds system..."
# ./scripts/feeds install -f -p helloworld shadowsocksr-libev shadowsocks-rust v2ray-core xray-core
# ./scripts/feeds install -f chinadns-ng dns2socks microsocks ipt2socks naiveproxy trojan
# ./scripts/feeds install -f luci-app-ssr-plus

# Method 3 - Add this repo as an OpenWrt feed
sed -i "/helloworld/d" "feeds.conf.default"
echo "src-git helloworld https://github.com/fw876/helloworld.git" >> "feeds.conf.default"
./scripts/feeds update helloworld
./scripts/feeds install -a -f -p helloworld

# Clean packages
rm -rf clone
