#!/bin/bash

# Local N1 OpenWrt Build Script
# Based on .github/workflows/N1.yml

set -e

# Environment variables
export REPO_URL="https://github.com/immortalwrt/immortalwrt"
export REPO_BRANCH="openwrt-24.10"
export TZ="Asia/Shanghai"
export DEBIAN_FRONTEND=noninteractive
export WORKDIR="/workdir"
export GITHUB_WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# aarch64 Cross-compilation environment
export ARCH="aarch64"
export TARGET_ARCH="aarch64"
export TARGET_OPTIMIZATION="-O2 -pipe -mcpu=cortex-a53"
export CONFIG_ARCH="aarch64"
export GNU_TARGET_NAME="aarch64-openwrt-linux-musl"
export REAL_GNU_TARGET_NAME="aarch64-openwrt-linux-musl"

# Additional environment for Go packages like xray-core
export HOSTCC="gcc"
export HOSTCXX="g++"
export HOSTCC_NOCACHE="gcc"
export HOSTCXX_NOCACHE="g++"
export HOST_CFLAGS="-O2 -pipe"
export HOST_CXXFLAGS="-O2 -pipe"

# Go toolchain for aarch64 - Enhanced for xray-core
export GOOS="linux"
export GOARCH="arm64"
export CGO_ENABLED=1
export CC_FOR_TARGET="aarch64-openwrt-linux-musl-gcc"
export CXX_FOR_TARGET="aarch64-openwrt-linux-musl-g++"

# Critical Go cross-compilation fixes for aarch64
export GO111MODULE=on
export GOPROXY=direct
export GOSUMDB=off
export CGO_LDFLAGS="-L$STAGING_DIR/lib -L$STAGING_DIR/usr/lib"
export CGO_CPPFLAGS="-I$STAGING_DIR/include -I$STAGING_DIR/usr/include"
export GO_GCC_HELPER_CC="aarch64-openwrt-linux-musl-gcc"
export GO_GCC_HELPER_CXX="aarch64-openwrt-linux-musl-g++"

# Rust toolchain for aarch64 - Fixed linker
export CARGO_BUILD_TARGET="aarch64-unknown-linux-musl"
export RUSTC_TARGET_ARCH="aarch64-unknown-linux-musl"
export RUSTFLAGS="-C target-cpu=cortex-a53 -C target-feature=+neon -C link-arg=-fuse-ld=bfd"
export CARGO_RUSTFLAGS="-C target-cpu=cortex-a53 -C target-feature=+neon -mno-outline-atomics -C link-arg=-fuse-ld=bfd"

# General cross-compilation settings
export CROSS_COMPILE="aarch64-openwrt-linux-musl-"
export CC="aarch64-openwrt-linux-musl-gcc"
export CXX="aarch64-openwrt-linux-musl-g++"
export AR="aarch64-openwrt-linux-musl-ar"
export STRIP="aarch64-openwrt-linux-musl-strip"
export RANLIB="aarch64-openwrt-linux-musl-ranlib"

# Fix linker configuration - correct bfd linker flag
export TARGET_LINKER="bfd"
export LDFLAGS="-Wl,-O1 -Wl,--as-needed -Wl,--gc-sections"

echo "=== Starting N1 OpenWrt Local Build ==="

# Load aarch64 toolchain environment
echo "Loading aarch64 toolchain environment..."
source $GITHUB_WORKSPACE/aarch64-toolchain.env

# Initialize environment
echo "Step 1: Installing dependencies..."
sudo -E apt-get -qq update
sudo -E apt-get -qq install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential bzip2 ccache clang cmake cpio curl device-tree-compiler ecj fastjar flex gawk gettext gcc-multilib g++-multilib git gnutls-dev gperf haveged help2man intltool lib32gcc-s1 libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses-dev libpython3-dev libreadline-dev libssl-dev libtool libyaml-dev libz-dev lld llvm lrzsz mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf python3 python3-pip python3-ply python3-docutils python3-pyelftools qemu-utils re2c rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev zstd
sudo -E apt-get -qq autoremove --purge
sudo -E apt-get -qq clean
sudo timedatectl set-timezone "$TZ"

# Create workdir
echo "Step 2: Setting up work directory..."
sudo mkdir -p $WORKDIR
sudo chown $USER:$(id -gn) $WORKDIR

# Clone source code
echo "Step 3: Cloning ImmortalWrt source..."
cd $WORKDIR
if [ -d "openwrt" ]; then
    echo "Removing existing openwrt directory..."
    rm -rf openwrt
fi
git clone $REPO_URL -b $REPO_BRANCH --single-branch --depth=1 openwrt
ln -sf $WORKDIR/openwrt $GITHUB_WORKSPACE/openwrt

# Update & Install feeds
echo "Step 4: Updating and installing feeds..."
chmod +x $GITHUB_WORKSPACE/diy.sh
cd openwrt

# Initial feeds update
./scripts/feeds update -a
./scripts/feeds install -a

# Run DIY script to install additional packages
echo "Installing SSR Plus and additional packages..."
$GITHUB_WORKSPACE/diy.sh

# Final feeds update after DIY script
echo "Final feeds update after package installation..."
./scripts/feeds update -a
./scripts/feeds install -a

# Load N1 custom config
echo "Step 5: Loading N1 custom configuration..."
rm -rf files .config
cp -r $GITHUB_WORKSPACE/files $GITHUB_WORKSPACE/.config ./

# Download packages
echo "Step 6: Downloading packages..."
make defconfig
make download -j$(( $(nproc) * 2 ))
find dl -size -1k -exec ls -l {} \;
find dl -size -1k -exec rm -f {} \;

# Compile firmware
echo "Step 7: Compiling N1 firmware with aarch64 optimizations..."
chmod -R 755 .
echo "Using $(nproc) threads for compilation"

# Set additional build environment for aarch64
export CONFIG_TARGET_OPTIMIZATION="-O2 -pipe -mcpu=cortex-a53 -mtune=cortex-a53"
export CFLAGS="-O2 -pipe -mcpu=cortex-a53 -mtune=cortex-a53"
export CXXFLAGS="-O2 -pipe -mcpu=cortex-a53 -mtune=cortex-a53"
export LDFLAGS="-Wl,-O1 -Wl,--as-needed -Wl,--gc-sections"

# Fix CMAKE linker issues for aarch64
export CMAKE_C_FLAGS="-O2 -pipe -mcpu=cortex-a53 -mtune=cortex-a53"
export CMAKE_CXX_FLAGS="-O2 -pipe -mcpu=cortex-a53 -mtune=cortex-a53"
export CMAKE_EXE_LINKER_FLAGS="-fuse-ld=bfd"
export CMAKE_SHARED_LINKER_FLAGS="-fuse-ld=bfd"
export CMAKE_MODULE_LINKER_FLAGS="-fuse-ld=bfd"

# Ensure toolchain paths are set correctly
export PATH="$WORKDIR/openwrt/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/bin:$PATH"
export STAGING_DIR="$WORKDIR/openwrt/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl"

# Force architecture settings
echo "CONFIG_ARCH=\"aarch64\"" >> .config
echo "CONFIG_TARGET_ARCH_PACKAGES=\"aarch64_generic\"" >> .config
echo "CONFIG_TARGET_OPTIMIZATION=\"-O2 -pipe -mcpu=cortex-a53\"" >> .config
make defconfig

# Build with explicit architecture targeting
make -j$(( $(nproc) + 1 )) V=s ARCH=aarch64 TARGET_ARCH=aarch64 || make -j1 V=s ARCH=aarch64 TARGET_ARCH=aarch64

# Package firmware
echo "Step 8: Packaging firmware..."
if [ ! -f "bin/targets/armsr/armv8/"*rootfs.tar.gz ]; then
    echo "Error: rootfs.tar.gz not found!"
    exit 1
fi

# Step 9: Package armsr as openwrt (N1 specific)
echo "Step 9: Package armsr as openwrt for N1..."

# Set environment variables exactly like GitHub workflow
export OPENWRT_ARMVIRT="openwrt/bin/targets/armsr/armv8/*rootfs.tar.gz"
export KERNEL_REPO_URL="breakingbadboy/OpenWrt"
export KERNEL_VERSION_NAME="6.6.y"
export PACKAGE_SOC="diy"
export GZIP_IMGS=".xz"
export SCRIPT_DIY_PATH="mk_s905d_n1.sh"
export WHOAMI="nantayo"
export SW_FLOWOFFLOAD=0
export SFE_FLOW=0

# Clone openwrt_packit if needed
if [ ! -d "openwrt_packit" ]; then
    echo "Cloning openwrt_packit..."
    git clone https://github.com/unifreq/openwrt_packit.git
fi

cd openwrt_packit

# Copy mk_s905d_n1.sh if exists in project root
if [ -f "../mk_s905d_n1.sh" ]; then
    cp ../mk_s905d_n1.sh ./
    echo "Using project-specific mk_s905d_n1.sh"
fi

# Run N1 packaging script directly
echo "Running mk_s905d_n1.sh..."
chmod +x mk_s905d_n1.sh
if ./mk_s905d_n1.sh; then
    echo "✓ N1 packaging completed successfully!"
else
    echo "⚠ N1 packaging failed, but base firmware is still available"
fi

cd ..

echo "=== Build completed successfully! ==="
echo "Base firmware: $WORKDIR/openwrt/bin/targets/armsr/armv8/"
echo "N1 firmware (if packaged): $WORKDIR/openwrt/openwrt_packit/out/"
echo ""
echo "Build process completed!"
