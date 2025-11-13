################################################################################
#
# python-pymicro-wakeword
#
################################################################################

PYTHON_PYMICRO_WAKEWORD_VERSION = v2.1.0
PYTHON_PYMICRO_WAKEWORD_SITE = https://github.com/OHF-Voice/pymicro-wakeword.git
PYTHON_PYMICRO_WAKEWORD_SITE_METHOD = git
PYTHON_PYMICRO_WAKEWORD_SETUP_TYPE = setuptools
PYTHON_PYMICRO_WAKEWORD_LICENSE = Apache-2.0
PYTHON_PYMICRO_WAKEWORD_LICENSE_FILES = LICENSE

PYTHON_PYMICRO_WAKEWORD_DEPENDENCIES = python-numpy-wheel tensorflow-lite-c-prebuilt

define PYTHON_PYMICRO_WAKEWORD_PRE_BUILD_TARGET_COPY_DEBUG
	if [ -d "$(PYTHON_PYMICRO_WAKEWORD_DIR)/debug" ]; then \
		cp -rv $(PYTHON_PYMICRO_WAKEWORD_DIR)/debug/* $(@D)/ ; \
	fi
endef

define PYTHON_PYMICRO_WAKEWORD_POST_INSTALL_MAKE_LNS
    mkdir -p $(TARGET_DIR)/usr/lib/python3.13/site-packages/pymicro_wakeword/lib
    ln -sf /usr/lib/libtensorflow-lite.so \
        $(TARGET_DIR)/usr/lib/python3.13/site-packages/pymicro_wakeword/lib/libtensorflowlite_c.so
endef


PYTHON_PYMICRO_WAKEWORD_PRE_BUILD_TARGET_HOOKS += PYTHON_PYMICRO_WAKEWORD_PRE_BUILD_TARGET_COPY_DEBUG
PYTHON_PYMICRO_WAKEWORD_POST_INSTALL_TARGET_HOOKS += PYTHON_PYMICRO_WAKEWORD_POST_INSTALL_MAKE_LNS

$(eval $(python-package))
