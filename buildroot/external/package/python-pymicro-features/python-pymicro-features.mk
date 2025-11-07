################################################################################
#
# python-pymicro-features
#
################################################################################

PYTHON_PYMICRO_FEATURES_VERSION = v2.0.2
PYTHON_PYMICRO_FEATURES_SITE = https://github.com/rhasspy/pymicro-features.git
PYTHON_PYMICRO_FEATURES_SITE_METHOD = git
PYTHON_PYMICRO_FEATURES_LICENSE = MIT
PYTHON_PYMICRO_FEATURES_LICENSE_FILES = LICENSE
PYTHON_PYMICRO_FEATURES_SETUP_TYPE = setuptools
PYTHON_PYMICRO_FEATURES_DEPENDENCIES = python3


$(eval $(python-package))
