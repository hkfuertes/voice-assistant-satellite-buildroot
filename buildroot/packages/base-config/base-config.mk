################################################################################
#
# pi-wifi-fix
#
################################################################################

BASE_CONFIG_VERSION = 1.0
BASE_CONFIG_LICENSE = MIT
BASE_CONFIG_SOURCE =

define BASE_CONFIG_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/etc/modprobe.d
	echo "options brcmfmac roamoff=1 feature_disable=0x82000 eap_restrict=1" > \
		$(TARGET_DIR)/etc/modprobe.d/brcmfmac.conf

	mkdir -p $(TARGET_DIR)/etc/iwd
	$(INSTALL) -D -m 0644 $(PKGDIR)/files/main.conf \
		$(TARGET_DIR)/etc/iwd/main.conf
endef

$(eval $(generic-package))
