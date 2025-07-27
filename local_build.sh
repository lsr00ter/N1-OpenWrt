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

echo "=== Starting N1 OpenWrt Local Build ==="

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
echo "Step 7: Compiling N1 firmware..."
chmod -R 755 .
echo "Using $(nproc) threads for compilation"

# Build with explicit architecture targeting
chmod +x .
make -j$(( $(nproc) + 1 )) || make -j1 V=s

# Package firmware
echo "Step 8: Package armsr as openwrt for N1..."

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
