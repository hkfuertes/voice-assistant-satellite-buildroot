SEEED_VOICECARD_VERSION = v6.12
SEEED_VOICECARD_SITE = $(call github,HinTak,seeed-voicecard,$(SEEED_VOICECARD_VERSION))
SEEED_VOICECARD_LICENSE = GNU General Public License v3.0
SEEED_VOICECARD_DEPENDENCIES = rpi-firmware dtc host-dtc rpi-utils

$(eval $(kernel-module))

define SEEED_VOICECARD_INSTALL_TARGET_CMDS

	mkdir -p $(TARGET_DIR)/etc/voicecard
	$(INSTALL) -D -m 0644 $(@D)/*.state $(TARGET_DIR)/etc/voicecard
	$(INSTALL) -D -m 0644 $(@D)/*.conf $(TARGET_DIR)/etc/voicecard

	mkdir -p $(BINARIES_DIR)/rpi-firmware/overlays
		$(HOST_DIR)/bin/dtc -@ -I dts -O dtb \
			-o $(BINARIES_DIR)/rpi-firmware/overlays/seeed-2mic-voicecard.dtbo \
			$(@D)/seeed-2mic-voicecard-overlay.dts
		$(HOST_DIR)/bin/dtc -@ -I dts -O dtb \
			-o $(BINARIES_DIR)/rpi-firmware/overlays/seeed-4mic-voicecard.dtbo \
			$(@D)/seeed-4mic-voicecard-overlay.dts
		$(HOST_DIR)/bin/dtc -@ -I dts -O dtb \
			-o $(BINARIES_DIR)/rpi-firmware/overlays/seeed-8mic-voicecard.dtbo \
			$(@D)/seeed-8mic-voicecard-overlay.dts
	
	mkdir -p $(TARGET_DIR)/usr/bin
		$(INSTALL) -D -m 0755 $(@D)/seeed-voicecard $(TARGET_DIR)/usr/bin/

	touch $(TARGET_DIR)/etc/modules
	grep -q "snd-soc-seeed-voicecard" $(TARGET_DIR)/etc/modules || \
		echo "snd-soc-seeed-voicecard" >> $(TARGET_DIR)/etc/modules
	grep -q "snd-soc-ac108" $(TARGET_DIR)/etc/modules || \
		echo "snd-soc-ac108" >> $(TARGET_DIR)/etc/modules
	grep -q "snd-soc-wm8960" $(TARGET_DIR)/etc/modules || \
		echo "snd-soc-wm8960" >> $(TARGET_DIR)/etc/modules

	mkdir -p $(TARGET_DIR)/etc/init.d
 		$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/seeed-voicecard/files/S50seeed-voicecard \
 			$(TARGET_DIR)/etc/init.d/S50seeed-voicecard
		$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/seeed-voicecard/files/S30modules \
			$(TARGET_DIR)/etc/init.d/S30modules
endef

define SEEED_VOICECARD_RPI_FIRMWARE_FIXUP
	if [ -f $(BINARIES_DIR)/rpi-firmware/config.txt ]; then \
		echo "" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
		echo "dtparam=i2c_arm=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
		echo "dtoverlay=i2s-mmap" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
		echo "dtparam=i2s=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
	fi
endef

SEEED_VOICECARD_POST_INSTALL_TARGET_HOOKS += SEEED_VOICECARD_RPI_FIRMWARE_FIXUP

$(eval $(generic-package))
