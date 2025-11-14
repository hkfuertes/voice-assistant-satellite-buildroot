### Future of this project
Recently I discovered that the Amazon Echo Dot 2 (`amazon-biscuit`) is hackable with a working Alpine version but only on 32bits, and Alpine wich is `musl`.

I attempted to build the same buildroot for arm32 bit and although it might be possible I was not able to. Let me explain directly inline with my original plan.

THE plan:
- **Make armv7 image for current Pi**: Raspberry Pi (3 and 02W) are able to operate in 64 and 32bit modes. In essence, generating a 32bit arm image with buildroot should be really really simple, but in reallity there are several complications:
  - Python Numpy, has to be installed via Wheel, as the `python-numpy` package provided with buildroot is very old and does not work. The thing is that the wheel for `armv7`, comes from **piwheel** that does not integrate all the dependant libraries, namely `openblas`. Its not trivial to build openblas with buildroot (at least for me) and using a prebuilt (via alpine apk or debian deb) was not working for me.
  - TensorFlowLite is already provided by buildroot on a somewhat recent version (2.11 vs 2.17) and can be compiled for armv7, but still need to figure out if the cpu optimization apply here (`NEON`). If in the future I want to go back and try, I replaced the build version (2.11) with a prebuilt version (2.17), here is the pr to undo: https://github.com/hkfuertes/voice-assistant-satellite-buildroot/pull/9
- **Test building this for the UZ801 dongle** (uses pmOS kernel and its aarch64 capable) _with an usb conference speaker/mic_: I recently also discovered this really cheap dongles in aliexpress that can run full blown Alpine.
  - Running Alpine and follow any tutorial on the oficial repo is not an option, as all the prebuilt libraries for tensorflow are built with `glibc` not `musl` and therefore are incompatible.
  - I was able to build the rootfs but the dongle rebooted continously to fastboot.
- _... I lost passion/interest in this project, and decided that the knowledge with the rootfs creation was better used in my setup with a proxmox lxc container..._
  - **Test pmOS on my Echo Dot**: _Yet to be tested._
  - _Test build for Echo Dot, following the same recipe used for UZ801, as the only current kernel I found was pmOS's_
