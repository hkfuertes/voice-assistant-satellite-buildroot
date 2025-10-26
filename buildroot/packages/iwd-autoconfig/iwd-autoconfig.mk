################################################################################
#
# iwd-autoconfig
#
################################################################################

IWD_AUTOCONFIG_VERSION = 1.0
IWD_AUTOCONFIG_LICENSE = MIT

define IWD_AUTOCONFIG_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_IWD_AUTOCONFIG_PATH)/package/iwd-autoconfig/S40iwd-autoconfig \
		$(TARGET_DIR)/etc/init.d/S40iwd-autoconfig
endef

$(eval $(generic-package))
