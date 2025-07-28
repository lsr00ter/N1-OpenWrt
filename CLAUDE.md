# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build System

This project builds OpenWrt firmware for Phicomm N1 (Amlogic S905D) devices based on ImmortalWrt-24.10.

### GitHub Actions Workflow

The main build process uses GitHub Actions (`.github/workflows/N1.yml`):

- **Trigger**: Manual dispatch or scheduled (1st and 16th of each month)
- **Runner**: ubuntu-24.04
- **Build Target**: armsr/armv8 (ARM64 Generic)

### Build Process Steps

1. **Environment Setup**: Installs OpenWrt build dependencies and sets Asia/Shanghai timezone
2. **Source Clone**: Clones ImmortalWrt from <https://github.com/immortalwrt/immortalwrt> openwrt-24.10 branch
3. **Feed Management**: Updates feeds, runs `diy.sh` for custom packages, updates feeds again
4. **Configuration**: Applies `.config` and `files/` overlay to openwrt directory
5. **Compilation**: Downloads packages and compiles firmware with parallel jobs
6. **N1 Packaging**: Uses unifreq/openwrt_packit action to create N1-specific images

### Key Build Variables

- REPO_URL: <https://github.com/immortalwrt/immortalwrt>
- REPO_BRANCH: openwrt-24.10
- KERNEL_REPO_URL: breakingbadboy/OpenWrt
- KERNEL_VERSION_NAME: 6.6.y
- PACKAGE_SOC: diy

## Architecture

### Custom Package Integration (`diy.sh`)

- **luci-app-amlogic**: System management for Amlogic devices
- **luci-app-passwall**: Proxy/VPN management
- **luci-app-ssrplus**: ShadowsocksR Plus proxy tool

Package installation removes conflicts then clones and installs from upstream repos.

### Configuration Structure

- `.config`: Main OpenWrt build configuration targeting armsr/armv8
- `files/etc/config/`: Device-specific network and amlogic configurations
- `files/etc/crontabs/root`: System cron jobs

### N1 Firmware Packaging

Creates bootable images for Phicomm N1 using:

- Platform: amlogic, SOC: s905d, Board: n1
- Kernel modules and DTBs from breakingbadboy/OpenWrt
- Custom bootloader and device tree configurations
- btrfs root filesystem with zstd compression

## Outputs

- **Base firmware**: `openwrt/bin/targets/armsr/armv8/`
- **N1 firmware**: Released as `.img.xz` files to GitHub releases
- **Default access**: IP 192.168.2.2, user root, password password
