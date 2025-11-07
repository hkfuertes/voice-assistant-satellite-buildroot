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
PYTHON_PYMICRO_FEATURES_DEPENDENCIES = python3 host-python-pybind11


$(eval $(python-package))
