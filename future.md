# Future Roadmap

This document outlines the exploration paths and technical challenges encountered while expanding platform support for this voice assistant satellite project.

## Primary Goal

**Target:** Run this Buildroot-based system on Amazon Echo Dot 2 (`amazon-biscuit`)

- Currently `armv7` (32-bit) is the only supported architecture with available Alpine kernel
- If `aarch64` kernel becomes available, migrate to 64-bit build
- Main advantage: Extremely cheap, hackable hardware with working Linux support

## Technical Challenges

### Kernel Integration

- Need to integrate prebuilt kernel (currently only Alpine/postmarketOS kernels available)
- Possible solution: Configure Buildroot to use external kernel build
- Status: Not yet implemented

### Python NumPy and OpenBLAS _(32bit)_

- **NumPy Issue:** Buildroot's `python-numpy` package is outdated and non-functional
- **Wheel Installation Problem:** ARM wheels from `piwheel` don't include `openblas` dependencies
- **OpenBLAS Compilation:** Not straightforward in Buildroot environment
- **Pre-built Binaries:** Alpine APK and Debian DEB packages failed to integrate properly
- Status: Blocking ARM32 builds

### TensorFlow Lite Optimization

- Need to validate CPU optimizations (NEON instructions) work correctly on ARM32
- Buildroot compiles TensorFlow v2.11 natively (no glibc/musl issues)
- Switched to prebuilt v2.17 in [PR #9](https://github.com/hkfuertes/voice-assistant-satellite-buildroot/pull/9)
- Status: Requires testing

## Why Buildroot Over Alpine/postmarketOS

**Decision:** Use Buildroot as base system instead of Alpine/postmarketOS

**Reasoning:**
- Alpine and postmarketOS use `musl` libc
- Pre-compiled TensorFlow libraries are built against `glibc`, causing binary incompatibility
- Compiling TensorFlow from source for `musl` is complex and time-consuming
- **Buildroot advantage:** Compiles entire system (including TensorFlow) from source, avoiding library compatibility issues

**Trade-off:** More complex initial setup, but full control over compilation and dependencies

## Attempted Platforms

### Raspberry Pi (ARM32)

**Goal:** Validate `armv7` Buildroot image on known-good hardware (Pi 3, Zero 2W)

**Status:** Blocked by NumPy/OpenBLAS issues

**Purpose:** Test platform before attempting Echo Dot port

### UZ801 Dongle

**Goal:** Alternative cheap hardware platform (postmarketOS kernel, `aarch64` capable)

**Status:** Failed - continuous fastboot reboot loop after successful rootfs build

**Notes:** Used Buildroot approach, but kernel integration issues prevented boot

### Amazon Echo Dot 2

**Goal:** Final target platform

**Status:** Not tested - waiting for ARM32 build resolution or `aarch64` kernel availability

## Project Status

**Currently on hold** - Technical blockers in ARM32 toolchain prevented progress. Knowledge gained was redirected to Proxmox LXC container deployment.

## Next Steps (If Resuming)

1. **Solve OpenBLAS integration** - Critical blocker for NumPy on ARM32
2. **Test external kernel integration** with Buildroot
3. **Validate NEON optimizations** for TensorFlow Lite on ARM32
4. **Attempt Echo Dot port** once ARM32 build is stable
5. **Monitor for `aarch64` kernel** availability for Echo Dot

---

**Last Updated:** November 2025
