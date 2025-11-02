WMA8960_CONFIG_VERSION = 1.0
WMA8960_CONFIG_LICENSE = MIT
WMA8960_CONFIG_DEPENDENCIES = linux

WMA8960_CONFIG_SOURCE = 

define WMA8960_CONFIG_CHECK_KERNEL_CONFIG
	if [ ! -f $(LINUX_DIR)/.config ]; then \
		echo "ERROR: Linux kernel not configured"; \
		exit 1; \
	fi; \
	if ! grep -q "CONFIG_SND_SOC_WM8960=m" $(LINUX_DIR)/.config && \
	   ! grep -q "CONFIG_SND_SOC_WM8960=y" $(LINUX_DIR)/.config; then \
		echo ""; \
		echo "ERROR: wma8960-config requires CONFIG_SND_SOC_WM8960 in kernel"; \
		echo "Please enable it via: make linux-menuconfig"; \
		echo ""; \
		exit 1; \
	fi
endef

WMA8960_CONFIG_PRE_BUILD_HOOKS += WMA8960_CONFIG_CHECK_KERNEL_CONFIG

define WMA8960_CONFIG_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/wma8960-config/files/asound.conf \
		$(TARGET_DIR)/etc/asound.conf
	
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/wma8960-config/files/respeaker.sh \
		$(TARGET_DIR)/usr/local/bin/respeaker
		
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/wma8960-config/files/S50respeaker \
		$(TARGET_DIR)/etc/init.d/S50respeaker
endef

define WMA8960_CONFIG_RPI_FIRMWARE_FIXUP
	if [ -f $(BINARIES_DIR)/rpi-firmware/config.txt ]; then \
		grep -q "dtoverlay=wm8960-soundcard" $(BINARIES_DIR)/rpi-firmware/config.txt || \
		{ echo "" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
		  echo "# ReSpeaker 2-Mic HAT v1" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
		  echo "dtparam=i2c_arm=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
		  echo "dtoverlay=i2s-mmap" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
		  echo "dtparam=i2s=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
		  echo "dtoverlay=wm8960-soundcard" >> $(BINARIES_DIR)/rpi-firmware/config.txt; }; \
	fi
endef

WMA8960_CONFIG_POST_INSTALL_TARGET_HOOKS += WMA8960_CONFIG_RPI_FIRMWARE_FIXUP

$(eval $(generic-package))