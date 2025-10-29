################################################################################
#
# linux-voice-assistant
#
################################################################################

LINUX_VOICE_ASSISTANT_VERSION = v1.0.0
LINUX_VOICE_ASSISTANT_SITE = $(call github,OHF-Voice,linux-voice-assistant,$(LINUX_VOICE_ASSISTANT_VERSION))
LINUX_VOICE_ASSISTANT_LICENSE = Apache-2.0
LINUX_VOICE_ASSISTANT_LICENSE_FILES = LICENSE
LINUX_VOICE_ASSISTANT_SETUP_TYPE = setuptools
LINUX_VOICE_ASSISTANT_DEPENDENCIES = python3 portaudio mpv python-zeroconf python-numpy python-cffi python-cryptography python-protobuf python-pymicro-features python-sounddevice python-mpv

# Fix upstream bug in pyproject.toml
define LINUX_VOICE_ASSISTANT_FIX_PYPROJECT
	sed -i 's/"python-mpv=>1,<2"/"python-mpv>=1,<2"/' $(@D)/pyproject.toml
endef

LINUX_VOICE_ASSISTANT_POST_EXTRACT_HOOKS += LINUX_VOICE_ASSISTANT_FIX_PYPROJECT

# Fix API compatibility with pymicro-features 2.x
define LINUX_VOICE_ASSISTANT_FIX_API
	sed -i 's/ProcessSamples/process_samples/g' $(@D)/linux_voice_assistant/microwakeword.py
endef

# LINUX_VOICE_ASSISTANT_POST_EXTRACT_HOOKS += LINUX_VOICE_ASSISTANT_FIX_API

# Install wakeword models
define LINUX_VOICE_ASSISTANT_INSTALL_WAKEWORDS
	mkdir -p $(TARGET_DIR)/usr/lib/python3.13/site-packages/wakewords
	cp -r $(@D)/wakewords/* \
		$(TARGET_DIR)/usr/lib/python3.13/site-packages/wakewords/
endef

LINUX_VOICE_ASSISTANT_POST_INSTALL_TARGET_HOOKS += LINUX_VOICE_ASSISTANT_INSTALL_WAKEWORDS

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

$(eval $(python-package))
