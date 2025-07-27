#!/bin/bash

# Add packages
echo "Cloning essential repositories ..."
git clone https://github.com/ophub/luci-app-amlogic --depth=1 clone/amlogic
git clone https://github.com/xiaorouji/openwrt-passwall --depth=1 clone/passwall
git clone https://github.com/fw876/helloworld.git --depth=1 clone/helloworld

# Update helloworld repo
echo "Updating helloworld repository..."
git -C clone/helloworld pull

# Remove conflicting packages
echo "Removing conflicting packages..."
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/packages/net/shadowsocks-libev
rm -rf feeds/packages/net/shadowsocksr-libev
rm -rf feeds/packages/net/v2ray-core
rm -rf feeds/packages/net/xray-core

# Install packages to feeds
echo "Installing packages to feeds..."
cp -rf clone/amlogic/luci-app-amlogic feeds/luci/applications/
cp -rf clone/passwall/luci-app-passwall feeds/luci/applications/
cp -rf clone/helloworld/luci-app-ssr-plus feeds/luci/applications/

# Install helloworld packages (contains many SSR plus dependencies)
echo "Installing helloworld packages..."
cp -rf clone/helloworld/shadowsocksr-libev feeds/packages/net/
cp -rf clone/helloworld/shadowsocks-rust feeds/packages/net/
cp -rf clone/helloworld/v2ray-core feeds/packages/net/
cp -rf clone/helloworld/xray-core feeds/packages/net/
cp -rf clone/helloworld/trojan feeds/packages/net/
cp -rf clone/helloworld/chinadns-ng feeds/packages/net/
cp -rf clone/helloworld/dns2socks feeds/packages/net/
cp -rf clone/helloworld/microsocks feeds/packages/net/
cp -rf clone/helloworld/ipt2socks feeds/packages/net/
cp -rf clone/helloworld/naiveproxy feeds/packages/net/
cp -rf clone/helloworld/redsocks2 feeds/packages/net/

# Copy additional dependencies if they exist
[ -d "clone/helloworld/mosdns" ] && cp -rf clone/helloworld/mosdns feeds/packages/net/
[ -d "clone/helloworld/hysteria" ] && cp -rf clone/helloworld/hysteria feeds/packages/net/
[ -d "clone/helloworld/tuic-client" ] && cp -rf clone/helloworld/tuic-client feeds/packages/net/
[ -d "clone/helloworld/v2ray-plugin" ] && cp -rf clone/helloworld/v2ray-plugin feeds/packages/net/
[ -d "clone/helloworld/dns2socks-rust" ] && cp -rf clone/helloworld/dns2socks-rust feeds/packages/net/

# Install packages via feeds system
echo "Installing packages via feeds system..."
./scripts/feeds install -f -p helloworld shadowsocksr-libev shadowsocks-rust v2ray-core xray-core
./scripts/feeds install -f chinadns-ng dns2socks microsocks ipt2socks naiveproxy trojan
./scripts/feeds install -f luci-app-ssr-plus

# Configure aarch64-specific build flags for packages
echo "Configuring aarch64 optimizations for additional packages..."

# Fix linker configuration globally for OpenWrt build
echo "Fixing linker configuration for aarch64..."
if [ -f "include/package-defaults.mk" ]; then
    # Create a temporary patch to fix linker flags
    if ! grep -q "fuse-ld=bfd" include/package-defaults.mk; then
        echo "Applying linker fix to package-defaults.mk..."
        sed -i 's/-fuse-ld=ld\.bfd/-fuse-ld=bfd/g' include/package-defaults.mk 2>/dev/null || true
    fi
fi

# Set Go/Rust package architecture targeting
if [ -f "feeds/packages/lang/golang/golang-values.mk" ]; then
    echo "Setting Go architecture to arm64 for aarch64"
    sed -i 's/GO_ARCH:=.*/GO_ARCH:=arm64/' feeds/packages/lang/golang/golang-values.mk
fi

if [ -f "feeds/packages/lang/rust/rust-values.mk" ]; then
    echo "Setting Rust target architecture for aarch64"
    # Ensure aarch64 specific flags are applied
    echo 'RUSTC_CFLAGS+=-mcpu=cortex-a53 -mtune=cortex-a53' >> feeds/packages/lang/rust/rust-values.mk
    # Fix Rust linker configuration
    sed -i 's/CARGO_RUSTFLAGS+=.*-Clink-arg=-fuse-ld=.*/CARGO_RUSTFLAGS+=-Clink-arg=-fuse-ld=bfd/' feeds/packages/lang/rust/rust-values.mk 2>/dev/null || true
fi

# Clean packages
# rm -rf clone
