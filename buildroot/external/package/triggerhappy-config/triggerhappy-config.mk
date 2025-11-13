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
	$(INSTALL) -D -m 0644 $(@D)/media.conf \
		$(TARGET_DIR)/etc/triggerhappy/triggers.d/media.conf
	
	# Install init script
	$(INSTALL) -D -m 0755 $(@D)/S02triggerhappy.init \
		$(TARGET_DIR)/etc/init.d/S02triggerhappy

	# Install volume control script
    $(INSTALL) -D -m 0755 $(@D)/volume_control.sh \
        $(TARGET_DIR)/usr/bin/volume_control
endef

$(eval $(generic-package))
