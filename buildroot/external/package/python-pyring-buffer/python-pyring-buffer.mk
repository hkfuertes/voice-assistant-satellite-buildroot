################################################################################
#
# python-pyring-buffer
#
################################################################################

PYTHON_PYRING_BUFFER_VERSION = 1.0.1
PYTHON_PYRING_BUFFER_SOURCE = pyring-buffer-$(PYTHON_PYRING_BUFFER_VERSION).tar.gz
PYTHON_PYRING_BUFFER_SITE = https://files.pythonhosted.org/packages/source/p/pyring-buffer
PYTHON_PYRING_BUFFER_SETUP_TYPE = setuptools
PYTHON_PYRING_BUFFER_LICENSE = Apache-2.0
PYTHON_PYRING_BUFFER_DEPENDENCIES = python3

$(eval $(python-package))
