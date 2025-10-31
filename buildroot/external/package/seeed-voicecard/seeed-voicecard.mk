################################################################################
#
# respeaker
#
################################################################################

RESPEAKER_VERSION = v6.12
RESPEAKER_SITE = $(call github,HinTak,seeed-voicecard,$(RESPEAKER_VERSION))
RESPEAKER_LICENSE = GNU General Public License v3.0
RESPEAKER_DEPENDENCIES = rpi-firmware dtc host-dtc

$(eval $(kernel-module))

define RESPEAKER_INSTALL_TARGET_CMDS

	mkdir -p $(TARGET_DIR)/etc
	mkdir -p $(TARGET_DIR)/var/lib/alsa
	$(INSTALL) -D -m 0644 $(@D)/wm8960_asound.state $(TARGET_DIR)/var/lib/alsa/asound.state
	$(INSTALL) -D -m 0644 $(@D)/asound_2mic.conf $(TARGET_DIR)/etc/asound

	mkdir -p $(BINARIES_DIR)/rpi-firmware/overlays
		$(HOST_DIR)/bin/dtc -@ -I dts -O dtb \
			-o $(BINARIES_DIR)/rpi-firmware/overlays/seeed-2mic-voicecard.dtbo \
			$(@D)/seeed-2mic-voicecard-overlay.dts
	
	mkdir -p $(TARGET_DIR)/etc/init.d
		$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/respeaker/S80respeaker \
			$(TARGET_DIR)/etc/init.d/S80respeaker
endef

define RESPEAKER_RPI_FIRMWARE_FIXUP
	if [ -f $(BINARIES_DIR)/rpi-firmware/config.txt ]; then \
		grep -q "dtoverlay=wm8960-soundcard" $(BINARIES_DIR)/rpi-firmware/config.txt || \
		{ echo "" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
		  echo "# ReSpeaker 2-Mic HAT v1" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
		  echo "dtparam=i2c_arm=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
		  echo "dtoverlay=i2s-mmap" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
		  echo "dtparam=i2s=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
		  echo "dtoverlay=seeed-2mic-voicecard" >> $(BINARIES_DIR)/rpi-firmware/config.txt; }; \
	fi
endef

RESPEAKER_POST_INSTALL_TARGET_HOOKS += RESPEAKER_RPI_FIRMWARE_FIXUP

$(eval $(generic-package))
