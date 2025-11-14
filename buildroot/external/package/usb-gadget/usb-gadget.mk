################################################################################
#
# usb-gadget
#
################################################################################

USB_GADGET_VERSION = 1.0
USB_GADGET_LICENSE = MIT
USB_GADGET_SOURCE = $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/usb-gadget

define USB_GADGET_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 0755  $(@D)/S35usb-gadget $(TARGET_DIR)/etc/init.d/S35usb-gadget
endef

define USB_GADGET_RPI_FIRMWARE_FIXUP
	if [ -f $(BINARIES_DIR)/rpi-firmware/config.txt ]; then \
		grep -q "dtoverlay=dwc2" $(BINARIES_DIR)/rpi-firmware/config.txt || \
		echo "dtoverlay=dwc2" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
	fi
endef

USB_GADGET_POST_INSTALL_TARGET_HOOKS += USB_GADGET_RPI_FIRMWARE_FIXUP

$(eval $(generic-package))
