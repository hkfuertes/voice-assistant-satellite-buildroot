################################################################################
#
# linux-voice-assistant
#
################################################################################

# v1.1.12 release commit
LINUX_VOICE_ASSISTANT_VERSION = 1d84fa089846c689f149048e32963ed61e6d36b5
LINUX_VOICE_ASSISTANT_SITE = $(call github,OHF-Voice,linux-voice-assistant,$(LINUX_VOICE_ASSISTANT_VERSION))
LINUX_VOICE_ASSISTANT_LICENSE = Apache-2.0
LINUX_VOICE_ASSISTANT_LICENSE_FILES = LICENSE
LINUX_VOICE_ASSISTANT_SETUP_TYPE = setuptools
LINUX_VOICE_ASSISTANT_DEPENDENCIES = python3 \
    portaudio \
    mpv \
    python-zeroconf \
    python-numpy-wheel \
    python-cffi \
    python-cryptography \
    python-protobuf \
    python-pymicro-features \
    python-soundcard \
    python-mpv \
    tensorflow-lite-c-prebuilt

define LINUX_VOICE_ASSISTANT_INSTALL_WAKEWORDS_AND_SOUNDS
    mkdir -p $(TARGET_DIR)/usr/lib/python3.13/site-packages/wakewords
    mkdir -p $(TARGET_DIR)/usr/lib/python3.13/site-packages/sounds
    cp -r $(@D)/wakewords/* $(TARGET_DIR)/usr/lib/python3.13/site-packages/wakewords/
    cp -r $(@D)/sounds/* $(TARGET_DIR)/usr/lib/python3.13/site-packages/sounds/
endef

LINUX_VOICE_ASSISTANT_POST_INSTALL_TARGET_HOOKS += LINUX_VOICE_ASSISTANT_INSTALL_WAKEWORDS_AND_SOUNDS


define LINUX_VOICE_ASSISTANT_LINK_TFLITE
    mkdir -p $(TARGET_DIR)/usr/lib/python3.13/site-packages/lib/linux_arm64
    ln -sf /usr/lib/libtensorflow-lite.so \
        $(TARGET_DIR)/usr/lib/python3.13/site-packages/lib/linux_arm64/libtensorflowlite_c.so
endef

LINUX_VOICE_ASSISTANT_POST_PATCH_HOOKS += LINUX_VOICE_ASSISTANT_LINK_TFLITE

define PYTHON_LINUX_VOICE_ASSISTANT_INSTALL_INIT
    mkdir -p $(TARGET_DIR)/etc/init.d
	$(INSTALL) -D -m 0755 $(LINUX_VOICE_ASSISTANT_PKGDIR)/files/S95linux-voice-assistant.sh \
		$(TARGET_DIR)/etc/init.d/S95linux-voice-assistant
endef

LINUX_VOICE_ASSISTANT_POST_INSTALL_TARGET_HOOKS += PYTHON_LINUX_VOICE_ASSISTANT_INSTALL_INIT

$(eval $(python-package))
