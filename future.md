### Future of this project
Recently I discovered that the Amazon Echo Dot 2 is hackable with a working Alpine version but only on 32bits.

The end goal (if dreaming is free) is to have `linux-voice-assistant` running with `microwakeword` on the Amazon Echo Dot 2nd (`amazon-biscuit`) with this buildroot as rootfs and pmOS kernel.

- Make armv7 image for current pi
- Test building this for the UZ801 dongle (uses pmOS kernel and its aarch64 capable) with an usb conference speaker/mic
- Test pmOS on my Echo Dot
- Test build for Echo Dot, following the same recipe used for UZ801, as the only current kernel I found was pmOS's
