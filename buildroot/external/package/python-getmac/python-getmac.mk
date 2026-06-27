################################################################################
#
# python-getmac
#
################################################################################

PYTHON_GETMAC_VERSION = 0.9.5
PYTHON_GETMAC_SOURCE = getmac-$(PYTHON_GETMAC_VERSION).tar.gz
PYTHON_GETMAC_SITE = https://files.pythonhosted.org/packages/89/a8/4af8e06912cd83b1cc6493e9b5d0589276c858f7bdccaf1855df748983de
PYTHON_GETMAC_LICENSE = MIT
PYTHON_GETMAC_SETUP_TYPE = setuptools
PYTHON_GETMAC_DEPENDENCIES = python3

$(eval $(python-package))
