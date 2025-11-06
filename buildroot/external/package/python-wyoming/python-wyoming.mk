################################################################################
#
# python-wyoming
#
################################################################################

PYTHON_WYOMING_VERSION = 1.5.4
PYTHON_WYOMING_SITE = https://github.com/OHF-Voice/wyoming.git
PYTHON_WYOMING_SITE_METHOD = git
PYTHON_WYOMING_SETUP_TYPE = setuptools
PYTHON_WYOMING_LICENSE = MIT
PYTHON_WYOMING_LICENSE_FILES = LICENSE
PYTHON_WYOMING_DEPENDENCIES = python3

$(eval $(python-package))
