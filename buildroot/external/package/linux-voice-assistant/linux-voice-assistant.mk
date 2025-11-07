################################################################################
#
# linux-voice-assistant
#
################################################################################

LINUX_VOICE_ASSISTANT_VERSION = 2b04484f4c225773130cd137c49ea443e2c6e9c5
LINUX_VOICE_ASSISTANT_SITE = $(call github,OHF-Voice,linux-voice-assistant,$(LINUX_VOICE_ASSISTANT_VERSION))
LINUX_VOICE_ASSISTANT_LICENSE = Apache-2.0
LINUX_VOICE_ASSISTANT_LICENSE_FILES = LICENSE
LINUX_VOICE_ASSISTANT_SETUP_TYPE = setuptools
LINUX_VOICE_ASSISTANT_DEPENDENCIES = python3 \
    portaudio \
    mpv \
    python-zeroconf \
    python-numpy \
    python-cffi \
    python-cryptography \
    python-protobuf \
    python-pymicro-features \
    python-soundcard \
    python-mpv \
    tensorflow-lite

# Install wakeword models
define LINUX_VOICE_ASSISTANT_INSTALL_WAKEWORDS
    mkdir -p $(TARGET_DIR)/usr/lib/python3.13/site-packages/wakewords
    cp -r $(@D)/wakewords/* \
        $(TARGET_DIR)/usr/lib/python3.13/site-packages/wakewords/
endef

LINUX_VOICE_ASSISTANT_POST_INSTALL_TARGET_HOOKS += LINUX_VOICE_ASSISTANT_INSTALL_WAKEWORDS


# En linux-voice-assistant.mk:
define LINUX_VOICE_ASSISTANT_LINK_TFLITE
    mkdir -p $(TARGET_DIR)/usr/lib/python3.13/site-packages/lib/linux_arm64
    ln -sf /usr/lib/libtensorflow-lite.so \
        $(TARGET_DIR)/usr/lib/python3.13/site-packages/lib/linux_arm64/libtensorflowlite_c.so
endef

LINUX_VOICE_ASSISTANT_POST_PATCH_HOOKS += LINUX_VOICE_ASSISTANT_LINK_TFLITE

$(eval $(python-package))
