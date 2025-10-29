################################################################################
#
# python-pymicro-features
#
################################################################################

PYTHON_PYMICRO_FEATURES_VERSION = 1.0.0
PYTHON_PYMICRO_FEATURES_SITE = https://github.com/rhasspy/pymicro-features.git
PYTHON_PYMICRO_FEATURES_SITE_METHOD = git
PYTHON_PYMICRO_FEATURES_LICENSE = MIT
PYTHON_PYMICRO_FEATURES_LICENSE_FILES = LICENSE
PYTHON_PYMICRO_FEATURES_SETUP_TYPE = setuptools
PYTHON_PYMICRO_FEATURES_DEPENDENCIES = python3 tensorflow-lite host-python-pybind11
PYTHON_PYMICRO_FEATURES_BUILD_OPTS = --skip-dependency-check

define PYTHON_PYMICRO_FEATURES_LINK_TFLITE
    mkdir -p $(TARGET_DIR)/usr/lib/python3.13/site-packages/lib/linux_arm64
    ln -sf /usr/lib/libtensorflow-lite.so \
        $(TARGET_DIR)/usr/lib/python3.13/site-packages/lib/linux_arm64/libtensorflowlite_c.so
endef

PYTHON_PYMICRO_FEATURES_POST_INSTALL_TARGET_HOOKS += PYTHON_PYMICRO_FEATURES_LINK_TFLITE

$(eval $(python-package))
