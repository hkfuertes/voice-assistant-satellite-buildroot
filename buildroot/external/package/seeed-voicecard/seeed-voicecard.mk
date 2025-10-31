################################################################################
#
# seeed-voicecard
#
################################################################################

SEEED_VOICECARD_VERSION = v6.12
SEEED_VOICECARD_SITE = https://github.com/HinTak/seeed-voicecard/archive/refs/heads/$(SEEED_VOICECARD_VERSION).tar.gz
SEEED_VOICECARD_LICENSE = MIT
SEEED_VOICECARD_LICENSE_FILES = LICENSE

SEEED_VOICECARD_DEPENDENCIES = rpi-firmware dtc

$(eval $(kernel-module))

define SEEED_VOICECARD_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/etc/voicecard
	$(INSTALL) -m 644 $(@D)/*.conf $(TARGET_DIR)/etc/voicecard/
	$(INSTALL) -m 644 $(@D)/*.state $(TARGET_DIR)/etc/voicecard/
	
	$(INSTALL) -D -m 755 $(@D)/seeed-voicecard $(TARGET_DIR)/usr/bin/seeed-voicecard

	mkdir -p $(TARGET_DIR)/etc/modules-load.d
	echo "snd-soc-ac108" > $(TARGET_DIR)/etc/modules-load.d/seeed-voicecard.conf
	echo "snd-soc-wm8960" >> $(TARGET_DIR)/etc/modules-load.d/seeed-voicecard.conf
	echo "snd-soc-seeed-voicecard" >> $(TARGET_DIR)/etc/modules-load.d/seeed-voicecard.conf
endef

define SEEED_VOICECARD_INSTALL_IMAGES_CMDS
	mkdir -p $(BINARIES_DIR)/rpi-firmware/overlays/
	$(INSTALL) -m 644 $(@D)/seeed-*-voicecard.dtbo $(BINARIES_DIR)/rpi-firmware/overlays/
endef

define SEEED_VOICECARD_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 755 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/seeed-voicecard/files/S90seeed-voicecard \
		$(TARGET_DIR)/etc/init.d/S90seeed-voicecard
endef

define RESPEAKER_RPI_FIRMWARE_FIXUP
    if [ -f $(BINARIES_DIR)/rpi-firmware/config.txt ]; then \
        grep -q "dtoverlay=seeed-2mic-voicecard" $(BINARIES_DIR)/rpi-firmware/config.txt || \
        { echo "" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
          echo "# ReSpeaker 2-Mic HAT" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
          echo "dtparam=i2c_arm=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
          echo "dtoverlay=i2s-mmap" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
          echo "dtparam=i2s=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
          echo "dtoverlay=seeed-2mic-voicecard" >> $(BINARIES_DIR)/rpi-firmware/config.txt; }; \
    fi
endef

RESPEAKER_POST_INSTALL_TARGET_HOOKS += RESPEAKER_RPI_FIRMWARE_FIXUP

$(eval $(generic-package))
