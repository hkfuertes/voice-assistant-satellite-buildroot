################################################################################
#
# respeaker
#
################################################################################

RESPEAKER_VERSION = v6.12
RESPEAKER_SITE = $(call github,HinTak,seeed-voicecard,$(RESPEAKER_VERSION))
RESPEAKER_LICENSE = GNU General Public License v3.0
RESPEAKER_DEPENDENCIES = rpi-firmware dtc

$(eval $(kernel-module))

define RESPEAKER_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/etc/voicecard
	$(INSTALL) -D -m 0644 $(@D)/*.conf $(TARGET_DIR)/etc/voicecard/
	$(INSTALL) -D -m 0644 $(@D)/*.state $(TARGET_DIR)/etc/voicecard/

	mkdir -p $(BINARIES_DIR)/rpi-firmware/overlays
	$(INSTALL) -D -m 0644 $(@D)/seeed-2mic-voicecard.dtbo $(BINARIES_DIR)/rpi-firmware/overlays/
	$(INSTALL) -D -m 0644 $(@D)/seeed-4mic-voicecard.dtbo $(BINARIES_DIR)/rpi-firmware/overlays/
	$(INSTALL) -D -m 0644 $(@D)/seeed-8mic-voicecard.dtbo $(BINARIES_DIR)/rpi-firmware/overlays/
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
