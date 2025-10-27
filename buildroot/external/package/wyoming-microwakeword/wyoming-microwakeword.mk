################################################################################
#
# wyoming-microwakeword
#
################################################################################

WYOMING_MICROWAKEWORD_VERSION = 9bedb6865e879fc4f1df7f9730ff2ef763dc3ac5
WYOMING_MICROWAKEWORD_SITE = https://github.com/rhasspy/wyoming-microwakeword.git
WYOMING_MICROWAKEWORD_SITE_METHOD = git
WYOMING_MICROWAKEWORD_LICENSE = MIT
WYOMING_MICROWAKEWORD_SETUP_TYPE = setuptools

WYOMING_MICROWAKEWORD_DEPENDENCIES = \
	host-python3 \
	host-python-pip \
	python3 \
	python-numpy

define WYOMING_MICROWAKEWORD_INSTALL_TARGET_CMDS
	# Instalar wyoming (versión específica)
	$(HOST_DIR)/bin/pip3 install \
		--prefix=$(TARGET_DIR)/usr \
		--root=/ \
		--no-deps \
		'wyoming==1.5.4' || true
	
	cd $(TARGET_DIR)/usr/lib/python3.13/site-packages && \
	tar xzf $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/wyoming-microwakeword/files/pymicro-complete.tar.gz
	
	# Instalar wyoming-microwakeword
	cd $(@D) && \
		$(HOST_DIR)/bin/pip3 install \
		--prefix=$(TARGET_DIR)/usr \
		--root=/ \
		--no-deps \
		--no-build-isolation \
		.
	
	# Fix shebang
	if [ -f $(TARGET_DIR)/usr/bin/wyoming-microwakeword ]; then \
		sed -i '1s|^#!/.*python|#!/usr/bin/env python3|' \
			$(TARGET_DIR)/usr/bin/wyoming-microwakeword; \
	fi
	
	# Instalar init script
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/wyoming-microwakeword/files/S86wyoming-microwakeword \
		$(TARGET_DIR)/etc/init.d/S86wyoming-microwakeword
endef

$(eval $(python-package))
