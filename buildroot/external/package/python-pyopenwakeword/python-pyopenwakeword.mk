################################################################################
#
# python-pyopenwakeword
#
################################################################################

PYTHON_PYOPENWAKEWORD_VERSION = v1.1.0
PYTHON_PYOPENWAKEWORD_SITE = https://github.com/rhasspy/pyopen-wakeword.git
PYTHON_PYOPENWAKEWORD_SITE_METHOD = git
PYTHON_PYOPENWAKEWORD_LICENSE = Apache-2.0
PYTHON_PYOPENWAKEWORD_SETUP_TYPE = setuptools

PYTHON_PYOPENWAKEWORD_DEPENDENCIES = python-numpy-wheel tensorflow-lite-c-prebuilt

define PYTHON_PYOPENWAKEWORD_POST_INSTALL_MAKE_LNS
	mkdir -p $(TARGET_DIR)/usr/lib/python3.13/site-packages/pyopen_wakeword/lib
	ln -sf /usr/lib/libtensorflow-lite.so \
		$(TARGET_DIR)/usr/lib/python3.13/site-packages/pyopen_wakeword/lib/libtensorflowlite_c.so
endef

PYTHON_PYOPENWAKEWORD_POST_INSTALL_TARGET_HOOKS += PYTHON_PYOPENWAKEWORD_POST_INSTALL_MAKE_LNS

$(eval $(python-package))
