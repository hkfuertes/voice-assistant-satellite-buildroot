################################################################################
#
# wyoming-openwakeword
#
################################################################################

WYOMING_OPENWAKEWORD_VERSION = v2.1.0
WYOMING_OPENWAKEWORD_SITE = https://github.com/rhasspy/wyoming-openwakeword.git
WYOMING_OPENWAKEWORD_SITE_METHOD = git
WYOMING_OPENWAKEWORD_LICENSE = Apache-2.0
WYOMING_OPENWAKEWORD_SETUP_TYPE = setuptools

WYOMING_OPENWAKEWORD_DEPENDENCIES = \
    python3 \
    python-numpy \
    python-pyopenwakeword \
    python-wyoming # The pyproject expects 1.8.0 but tested working with 1.5.4

define WYOMING_OPENWAKEWORD_FIX_SHEBANG
    # Fix shebang si existe el script
    if [ -f $(TARGET_DIR)/usr/bin/wyoming-openwakeword ]; then \
        sed -i '1s|^#!/.*python|#!/usr/bin/env python3|' \
            $(TARGET_DIR)/usr/bin/wyoming-openwakeword; \
    fi
endef

WYOMING_OPENWAKEWORD_POST_INSTALL_TARGET_HOOKS += WYOMING_OPENWAKEWORD_FIX_SHEBANG

define WYOMING_OPENWAKEWORD_INSTALL_INIT_SYSV
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/wyoming-openwakeword/files/S85wyoming-openwakeword \
        $(TARGET_DIR)/etc/init.d/S85wyoming-openwakeword
endef

$(eval $(python-package))
