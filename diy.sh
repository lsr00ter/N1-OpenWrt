#!/bin/bash

# Remove conflicting packages first
echo "Removing conflicting packages..."
rm -rf feeds/luci/applications/luci-app-passwall

# Clone required repositories
echo "Cloning repositories..."
git clone https://github.com/ophub/luci-app-amlogic --depth=1 clone/amlogic
git clone https://github.com/xiaorouji/openwrt-passwall --depth=1 clone/passwall

# Install cloned packages to feeds
echo "Installing packages to feeds..."
cp -rf clone/amlogic/luci-app-amlogic feeds/luci/applications/
cp -rf clone/passwall/luci-app-passwall feeds/luci/applications/

# Add helloworld feed
echo "Adding helloworld feed..."
sed -i "/helloworld/d" "feeds.conf.default"
echo "src-git helloworld https://github.com/fw876/helloworld.git" >> "feeds.conf.default"

# Update and install helloworld packages
echo "Installing helloworld packages..."
./scripts/feeds update helloworld
./scripts/feeds install -a -f -p helloworld

# Clean up temporary files
echo "Cleaning up..."
rm -rf clone
