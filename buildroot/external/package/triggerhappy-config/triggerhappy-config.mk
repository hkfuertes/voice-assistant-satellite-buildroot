################################################################################
#
# triggerhappy-config
#
################################################################################

TRIGGERHAPPY_CONFIG_VERSION = 1.0
TRIGGERHAPPY_CONFIG_SITE = $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/triggerhappy-config/files
TRIGGERHAPPY_CONFIG_SITE_METHOD = local

define TRIGGERHAPPY_CONFIG_INSTALL_TARGET_CMDS
	# Install triggerhappy configuration
	$(INSTALL) -D -m 0644 $(@D)/emeet.conf \
		$(TARGET_DIR)/etc/triggerhappy/triggers.d/emeet.conf
	
	# Install init script
	$(INSTALL) -D -m 0755 $(@D)/S02triggerhappy.init \
		$(TARGET_DIR)/etc/init.d/S02triggerhappy
endef

$(eval $(generic-package))
