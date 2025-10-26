################################################################################
#
# usb-gadget
#
################################################################################

USB_GADGET_VERSION = 1.0
USB_GADGET_LICENSE = MIT
USB_GADGET_SOURCE =

define USB_GADGET_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/usb-gadget/usb-gadget.sh \
		$(TARGET_DIR)/usr/sbin/usb-gadget
	mkdir -p $(TARGET_DIR)/etc
	grep -qxF "dwc2" $(TARGET_DIR)/etc/modules || echo "dwc2" >> $(TARGET_DIR)/etc/modules
	grep -qxF "libcomposite" $(TARGET_DIR)/etc/modules || echo "libcomposite" >> $(TARGET_DIR)/etc/modules
endef

define USB_GADGET_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/usb-gadget/S35usb-gadget \
		$(TARGET_DIR)/etc/init.d/S35usb-gadget
endef

define USB_GADGET_RPI_FIRMWARE_FIXUP
	if [ -f $(BINARIES_DIR)/rpi-firmware/config.txt ]; then \
		echo "Adding dwc2 overlay to config.txt"; \
		grep -q "dtoverlay=dwc2" $(BINARIES_DIR)/rpi-firmware/config.txt || \
		echo "dtoverlay=dwc2" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
	fi
endef

USB_GADGET_POST_INSTALL_TARGET_HOOKS += USB_GADGET_RPI_FIRMWARE_FIXUP

$(eval $(generic-package))
