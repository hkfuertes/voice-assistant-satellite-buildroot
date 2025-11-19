################################################################################
#
# linux-voice-assistant-wrapper
#
################################################################################

LINUX_VOICE_ASSISTANT_WRAPPER_VERSION = 1.0.0
LINUX_VOICE_ASSISTANT_WRAPPER_SITE = $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/linux-voice-assistant-wrapper/src
LINUX_VOICE_ASSISTANT_WRAPPER_SITE_METHOD = local
LINUX_VOICE_ASSISTANT_WRAPPER_LICENSE = MIT
LINUX_VOICE_ASSISTANT_WRAPPER_LICENSE_FILES = LICENSE
LINUX_VOICE_ASSISTANT_WRAPPER_SETUP_TYPE = setuptools

# Python dependencies (without gpiozero - installed via pip)
LINUX_VOICE_ASSISTANT_WRAPPER_DEPENDENCIES = \
	host-python3 \
	host-python-pip \
	python3 \
	linux-voice-assistant \
	python-spidev

# Install LED support packages via pip (like wyoming-satellite does)
define LINUX_VOICE_ASSISTANT_WRAPPER_INSTALL_LED_DEPS
	$(HOST_DIR)/bin/pip3 install \
		--prefix=$(TARGET_DIR)/usr \
		--no-deps \
		rpi-lgpio gpiozero
endef

LINUX_VOICE_ASSISTANT_WRAPPER_POST_INSTALL_TARGET_HOOKS += LINUX_VOICE_ASSISTANT_WRAPPER_INSTALL_LED_DEPS

# Install init script
define LINUX_VOICE_ASSISTANT_WRAPPER_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/linux-voice-assistant-wrapper/files/S95linux-voice-assistant-wrapper.sh \
		$(TARGET_DIR)/etc/init.d/S95linux-voice-assistant-wrapper
endef

# Enable SPI in Raspberry Pi firmware config (if using RPi)
ifeq ($(BR2_PACKAGE_RPI_FIRMWARE),y)
define LINUX_VOICE_ASSISTANT_WRAPPER_RPI_FIRMWARE_FIXUP
	if [ -f $(BINARIES_DIR)/rpi-firmware/config.txt ]; then \
		grep -q "dtparam=spi=on" $(BINARIES_DIR)/rpi-firmware/config.txt || \
		echo "dtparam=spi=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
	fi
endef

LINUX_VOICE_ASSISTANT_WRAPPER_POST_INSTALL_TARGET_HOOKS += LINUX_VOICE_ASSISTANT_WRAPPER_RPI_FIRMWARE_FIXUP
endif

$(eval $(python-package))
