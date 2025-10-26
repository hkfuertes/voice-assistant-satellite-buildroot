################################################################################
#
# iwd-autoconfig
#
################################################################################

IWD_AUTOCONFIG_VERSION = 1.0
IWD_AUTOCONFIG_LICENSE = MIT

define IWD_AUTOCONFIG_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 0755 $(@D)/S39iwd-autoconfig \
		$(TARGET_DIR)/etc/init.d/S39iwd-autoconfig
endef

$(eval $(generic-package))
