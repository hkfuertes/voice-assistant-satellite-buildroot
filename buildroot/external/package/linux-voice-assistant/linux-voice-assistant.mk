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
LINUX_VOICE_ASSISTANT_DEPENDENCIES = python3 portaudio mpv python-zeroconf python-numpy python-cffi python-cryptography python-protobuf python-pymicro-features python-sounddevice python-mpv python-aioesphomeapi

define PYTHON_LINUX_VOICE_ASSISTANT_INSTALL_WAKEWORDS
	mkdir -p $(TARGET_DIR)/usr/lib/python3.13/site-packages/wakewords
	cp -r $(@D)/linux_voice_assistant/wakewords/* \
		$(TARGET_DIR)/usr/lib/python3.13/site-packages/wakewords/
endef

PYTHON_LINUX_VOICE_ASSISTANT_POST_INSTALL_TARGET_HOOKS += PYTHON_LINUX_VOICE_ASSISTANT_INSTALL_WAKEWORDS

# Copy wakeword models after installation
define LINUX_VOICE_ASSISTANT_COPY_WAKEWORDS
	mkdir -p $(TARGET_DIR)/usr/share/linux-voice-assistant/wakewords
	if [ -d $(@D)/wakewords ]; then \
		cp -r $(@D)/wakewords/* $(TARGET_DIR)/usr/share/linux-voice-assistant/wakewords/; \
	fi
endef

LINUX_VOICE_ASSISTANT_POST_INSTALL_TARGET_HOOKS += LINUX_VOICE_ASSISTANT_COPY_WAKEWORDS

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
