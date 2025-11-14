################################################################################
#
# expand-rootfs
#
################################################################################

EXPAND_ROOTFS_VERSION = 1.0
EXPAND_ROOTFS_LICENSE = MIT
EXPAND_ROOTFS_SITE = $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/expand-rootfs/files
EXPAND_ROOTFS_SITE_METHOD = local

define EXPAND_ROOTFS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/rootfs-resizer $(TARGET_DIR)/usr/bin/rootfs-resizer
endef

define EXPAND_ROOTFS_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 0755 $(@D)/S01expand-rootfs $(TARGET_DIR)/etc/init.d/S01expand-rootfs
endef

$(eval $(generic-package))
