################################################################################
#
# iwd-autoconfig
#
################################################################################

IWD_AUTOCONFIG_VERSION = 1.0
IWD_AUTOCONFIG_LICENSE = MIT

# No source needed - just an init script
IWD_AUTOCONFIG_SOURCE =

define IWD_AUTOCONFIG_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/iwd-autoconfig/S39iwd-autoconfig \
		$(TARGET_DIR)/etc/init.d/S39iwd-autoconfig
endef

$(eval $(generic-package))
