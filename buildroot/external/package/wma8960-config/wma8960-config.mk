################################################################################
#
# wma8960-config
#
################################################################################

WMA8960_CONFIG_VERSION = 1.0
WMA8960_CONFIG_LICENSE = MIT
WMA8960_CONFIG_DEPENDENCIES = linux
WMA8960_CONFIG_SOURCE = 

# Download URLs
WMA8960_CONFIG_ASOUND_CONF_URL = https://raw.githubusercontent.com/waveshareteam/WM8960-Audio-HAT/master/asound.conf
WMA8960_CONFIG_ASOUND_STATE_URL = https://raw.githubusercontent.com/waveshareteam/WM8960-Audio-HAT/master/wm8960_asound.state

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
	# Download and install ALSA configuration files
	mkdir -p $(@D)/downloads
	wget -O $(@D)/downloads/asound.conf $(WMA8960_CONFIG_ASOUND_CONF_URL) || true
	wget -O $(@D)/downloads/asound.state $(WMA8960_CONFIG_ASOUND_STATE_URL) || true
	
	if [ -f $(@D)/downloads/asound.conf ]; then \
		$(INSTALL) -D -m 0644 $(@D)/downloads/asound.conf $(TARGET_DIR)/etc/asound.conf; \
	fi
	if [ -f $(@D)/downloads/asound.state ]; then \
		$(INSTALL) -D -m 0644 $(@D)/downloads/asound.state $(TARGET_DIR)/var/lib/alsa/asound.state; \
	fi
	
	# Install ALSA restore init script
	mkdir -p $(TARGET_DIR)/etc/init.d
	echo '#!/bin/sh' > $(TARGET_DIR)/etc/init.d/S50alsa-restore
	echo 'STATEFILE="/var/lib/alsa/asound.state"' >> $(TARGET_DIR)/etc/init.d/S50alsa-restore
	echo '[ -f "$$STATEFILE" ] && alsactl restore -f "$$STATEFILE"' >> $(TARGET_DIR)/etc/init.d/S50alsa-restore
	chmod 0755 $(TARGET_DIR)/etc/init.d/S50alsa-restore
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
