################################################################################
#
# python-pymicro-wakeword
#
################################################################################

PYTHON_PYMICRO_WAKEWORD_VERSION = 2.1.0
PYTHON_PYMICRO_WAKEWORD_SITE = $(call github,OHF-Voice,pymicro-wakeword,v$(PYTHON_PYMICRO_WAKEWORD_VERSION))
PYTHON_PYMICRO_WAKEWORD_SETUP_TYPE = setuptools
PYTHON_PYMICRO_WAKEWORD_LICENSE = Apache-2.0
PYTHON_PYMICRO_WAKEWORD_LICENSE_FILES = LICENSE

# Dependencias en orden: pymicro-features debe compilarse antes que pymicro-wakeword
PYTHON_PYMICRO_WAKEWORD_DEPENDENCIES = \
	python-pymicro-features \
	python-numpy

$(eval $(python-package))
