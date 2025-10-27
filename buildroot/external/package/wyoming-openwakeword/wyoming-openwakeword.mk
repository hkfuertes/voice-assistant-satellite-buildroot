################################################################################
#
# wyoming-openwakeword
#
################################################################################

WYOMING_OPENWAKEWORD_VERSION = 66874a4bef7a2b1ce3c8bb7e59d5810b1746ddd1
WYOMING_OPENWAKEWORD_SITE = https://github.com/rhasspy/wyoming-openwakeword.git
WYOMING_OPENWAKEWORD_SITE_METHOD = git
WYOMING_OPENWAKEWORD_LICENSE = Apache-2.0
WYOMING_OPENWAKEWORD_SETUP_TYPE = setuptools

WYOMING_OPENWAKEWORD_DEPENDENCIES = \
	host-python3 \
	host-python-pip \
	python3 \
	python-numpy

define WYOMING_OPENWAKEWORD_INSTALL_TARGET_CMDS
	# Instalar wyoming desde PyPI (pure Python)
	$(HOST_DIR)/bin/pip3 install \
		--prefix=$(TARGET_DIR)/usr \
		--root=/ \
		--no-deps \
		wyoming || true
	
	# Desempaquetar pyopen-wakeword ARM64 manualmente
	cd /tmp && \
		unzip -o $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/wyoming-openwakeword/files/pyopen_wakeword-1.0.1-py3-none-manylinux_2_35_aarch64.whl && \
		cp -r pyopen_wakeword* $(TARGET_DIR)/usr/lib/python3.13/site-packages/ && \
		rm -rf pyopen_wakeword*
	
	# Instalar wyoming-openwakeword
	cd $(@D) && \
		$(HOST_DIR)/bin/pip3 install \
		--prefix=$(TARGET_DIR)/usr \
		--root=/ \
		--no-deps \
		--no-build-isolation \
		--no-index \
		.
	
	# Fix shebang
	if [ -f $(TARGET_DIR)/usr/bin/wyoming-openwakeword ]; then \
		sed -i '1s|^#!/.*python|#!/usr/bin/env python3|' \
			$(TARGET_DIR)/usr/bin/wyoming-openwakeword; \
	fi
	
	# Instalar init script
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/wyoming-openwakeword/files/S85wyoming-openwakeword \
		$(TARGET_DIR)/etc/init.d/S85wyoming-openwakeword
endef

$(eval $(python-package))
