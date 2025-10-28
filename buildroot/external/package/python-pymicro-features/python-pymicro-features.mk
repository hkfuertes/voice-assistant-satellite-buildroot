################################################################################
#
# python-pymicro-features
#
################################################################################

PYTHON_PYMICRO_FEATURES_VERSION = 2.0.2
PYTHON_PYMICRO_FEATURES_SITE = $(call github,rhasspy,pymicro-features,v$(PYTHON_PYMICRO_FEATURES_VERSION))
PYTHON_PYMICRO_FEATURES_LICENSE = MIT
PYTHON_PYMICRO_FEATURES_LICENSE_FILES = LICENSE
PYTHON_PYMICRO_FEATURES_SETUP_TYPE = setuptools
PYTHON_PYMICRO_FEATURES_DEPENDENCIES = python3 tensorflow-lite

$(eval $(python-package))