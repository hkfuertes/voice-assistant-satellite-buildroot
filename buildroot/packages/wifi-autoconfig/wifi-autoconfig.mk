################################################################################
#
# wifi-autoconfig
#
################################################################################

WIFI_AUTOCONFIG_VERSION = 1.0
WIFI_AUTOCONFIG_LICENSE = MIT
WIFI_AUTOCONFIG_SOURCE =

define WIFI_AUTOCONFIG_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/etc/modprobe.d
	echo "options brcmfmac roamoff=1 feature_disable=0x82000" > \
		$(TARGET_DIR)/etc/modprobe.d/brcmfmac.conf
	
	test -f $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/wifi-autoconfig/files/wpa_supplicant.conf && \
		$(INSTALL) -D -m 0600 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/wifi-autoconfig/files/wpa_supplicant.conf \
		$(TARGET_DIR)/etc/wpa_supplicant.conf || true
endef

define WIFI_AUTOCONFIG_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/wifi-autoconfig/files/S39wifi-autoconfig \
		$(TARGET_DIR)/etc/init.d/S39wifi-autoconfig
endef

$(eval $(generic-package))
