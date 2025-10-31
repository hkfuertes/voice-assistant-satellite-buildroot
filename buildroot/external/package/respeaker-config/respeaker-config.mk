################################################################################
#
# respeaker-config
#
################################################################################

RESPEAKER_CONFIG_VERSION = 1.0
RESPEAKER_CONFIG_LICENSE = MIT
RESPEAKER_CONFIG_DEPENDENCIES = linux

RESPEAKER_CONFIG_SOURCE = 

define RESPEAKER_CONFIG_CHECK_KERNEL_CONFIG
	if [ ! -f $(LINUX_DIR)/.config ]; then \
		echo "ERROR: Linux kernel not configured"; \
		exit 1; \
	fi; \
	if ! grep -q "CONFIG_SND_SOC_WM8960=m" $(LINUX_DIR)/.config && \
	   ! grep -q "CONFIG_SND_SOC_WM8960=y" $(LINUX_DIR)/.config; then \
		echo ""; \
		echo "ERROR: respeaker-config requires CONFIG_SND_SOC_WM8960 in kernel"; \
		echo "Please enable it via: make linux-menuconfig"; \
		echo "Or add package/respeaker-config/linux.fragment to"; \
		echo "BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES"; \
		echo ""; \
		exit 1; \
	fi
endef

RESPEAKER_CONFIG_PRE_BUILD_HOOKS += RESPEAKER_CONFIG_CHECK_KERNEL_CONFIG

define RESPEAKER_CONFIG_INSTALL_TARGET_CMDS
	# Install ALSA configuration
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/respeaker-config/files/asound.conf \
		$(TARGET_DIR)/etc/asound.conf

	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/respeaker-config/files/asound.state \
		$(TARGET_DIR)/var/lib/alsa/asound.state
	
	# Install init script
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/respeaker-config/files/S50respeaker \
		$(TARGET_DIR)/etc/init.d/S50respeaker

	mkdir -p $(BINARIES_DIR)/rpi-firmware/overlays
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/respeaker-config/files/seeed-2mic-voicecard.dtbo \
		$(BINARIES_DIR)/rpi-firmware/overlays/
endef

define RESPEAKER_CONFIG_RPI_FIRMWARE_FIXUP
	if [ -f $(BINARIES_DIR)/rpi-firmware/config.txt ]; then \
		grep -q "dtoverlay=seeed-2mic-voicecard" $(BINARIES_DIR)/rpi-firmware/config.txt || \
		{ echo "" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
		  echo "# ReSpeaker 2-Mic HAT v1" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
		  echo "dtparam=i2c_arm=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
		  echo "dtoverlay=i2s-mmap" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
		  echo "dtparam=i2s=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
		  echo "dtoverlay=seeed-2mic-voicecard" >> $(BINARIES_DIR)/rpi-firmware/config.txt; }; \
	fi
endef
# echo "dtoverlay=wm8960-soundcard" >> $(BINARIES_DIR)/rpi-firmware/config.txt; };


RESPEAKER_CONFIG_POST_INSTALL_TARGET_HOOKS += RESPEAKER_CONFIG_RPI_FIRMWARE_FIXUP

$(eval $(generic-package))
