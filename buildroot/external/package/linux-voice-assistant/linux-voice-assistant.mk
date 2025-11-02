################################################################################
#
# linux-voice-assistant
#
################################################################################

LINUX_VOICE_ASSISTANT_VERSION = 7a4b3e661a6fad570753ae09b3adfad3fb4fbf6f
LINUX_VOICE_ASSISTANT_SITE = $(call github,OHF-Voice,linux-voice-assistant,$(LINUX_VOICE_ASSISTANT_VERSION))
LINUX_VOICE_ASSISTANT_LICENSE = Apache-2.0
LINUX_VOICE_ASSISTANT_LICENSE_FILES = LICENSE
LINUX_VOICE_ASSISTANT_SETUP_TYPE = setuptools
LINUX_VOICE_ASSISTANT_DEPENDENCIES = python3 portaudio mpv python-zeroconf python-numpy python-cffi python-cryptography python-protobuf python-pymicro-features python-sounddevice python-mpv 

# Install debug versions with extra logging
define LINUX_VOICE_ASSISTANT_INSTALL_DEBUG_FILES
    @echo "Installing debug versions of __main__.py and microwakeword.py"
    cp -f $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/linux-voice-assistant/files/debug/__main__.py \
        $(@D)/linux_voice_assistant/__main__.py
    cp -f $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/linux-voice-assistant/files/debug/microwakeword.py \
        $(@D)/linux_voice_assistant/microwakeword.py
endef

LINUX_VOICE_ASSISTANT_POST_PATCH_HOOKS += LINUX_VOICE_ASSISTANT_INSTALL_DEBUG_FILES


# Install wakeword models
define LINUX_VOICE_ASSISTANT_INSTALL_WAKEWORDS
    mkdir -p $(TARGET_DIR)/usr/lib/python3.13/site-packages/wakewords
    cp -r $(@D)/wakewords/* \
        $(TARGET_DIR)/usr/lib/python3.13/site-packages/wakewords/
endef

LINUX_VOICE_ASSISTANT_POST_INSTALL_TARGET_HOOKS += LINUX_VOICE_ASSISTANT_INSTALL_WAKEWORDS


# En linux-voice-assistant.mk:
define LINUX_VOICE_ASSISTANT_EXTRACT_TFLITE
    mkdir -p $(TARGET_DIR)/usr/lib/python3.13/site-packages/lib/linux_arm64
    cp -f $(@D)/lib/linux_arm64/libtensorflowlite_c.so \
        $(TARGET_DIR)/usr/lib/python3.13/site-packages/lib/linux_arm64/
endef

LINUX_VOICE_ASSISTANT_POST_PATCH_HOOKS += LINUX_VOICE_ASSISTANT_EXTRACT_TFLITE

# Install init script and configuration
define LINUX_VOICE_ASSISTANT_INSTALL_INIT_SYSV
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/linux-voice-assistant/files/S90linux-voice-assistant \
        $(TARGET_DIR)/etc/init.d/S90linux-voice-assistant
    mkdir -p $(TARGET_DIR)/etc/linux-voice-assistant
    echo "SATELLITE_NAME=$(BR2_PACKAGE_LINUX_VOICE_ASSISTANT_NAME)" > \
        $(TARGET_DIR)/etc/linux-voice-assistant/config
    echo "WAKE_MODEL=$(BR2_PACKAGE_LINUX_VOICE_ASSISTANT_WAKE_MODEL)" >> \
        $(TARGET_DIR)/etc/linux-voice-assistant/config
    if [ -n "$(BR2_PACKAGE_LINUX_VOICE_ASSISTANT_AUDIO_INPUT)" ]; then \
        echo "AUDIO_INPUT_DEVICE=$(BR2_PACKAGE_LINUX_VOICE_ASSISTANT_AUDIO_INPUT)" >> \
            $(TARGET_DIR)/etc/linux-voice-assistant/config; \
    fi
    if [ -n "$(BR2_PACKAGE_LINUX_VOICE_ASSISTANT_AUDIO_OUTPUT)" ]; then \
        echo "AUDIO_OUTPUT_DEVICE=$(BR2_PACKAGE_LINUX_VOICE_ASSISTANT_AUDIO_OUTPUT)" >> \
            $(TARGET_DIR)/etc/linux-voice-assistant/config; \
    fi
endef

LINUX_VOICE_ASSISTANT_POST_INSTALL_TARGET_HOOKS += LINUX_VOICE_ASSISTANT_INSTALL_INIT_SYSV

$(eval $(python-package))
