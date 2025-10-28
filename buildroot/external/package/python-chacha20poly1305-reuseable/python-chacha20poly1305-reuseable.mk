################################################################################
#
# python-chacha20poly1305-reuseable
#
################################################################################

PYTHON_CHACHA20POLY1305_REUSEABLE_VERSION = 0.13.2
PYTHON_CHACHA20POLY1305_REUSEABLE_SITE = $(call github,bdraco,chacha20poly1305-reuseable,v$(PYTHON_CHACHA20POLY1305_REUSEABLE_VERSION))
PYTHON_CHACHA20POLY1305_REUSEABLE_LICENSE = Apache-2.0 OR BSD-3-Clause
PYTHON_CHACHA20POLY1305_REUSEABLE_LICENSE_FILES = LICENSE
PYTHON_CHACHA20POLY1305_REUSEABLE_SETUP_TYPE = setuptools
PYTHON_CHACHA20POLY1305_REUSEABLE_DEPENDENCIES = python3 python-cryptography

$(eval $(python-package))
