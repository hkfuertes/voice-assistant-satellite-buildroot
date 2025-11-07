################################################################################
#
# python-pyring-buffer
#
################################################################################

PYTHON_PYRING_BUFFER_VERSION = v1.0.1
PYTHON_PYRING_BUFFER_SITE = https://github.com/rhasspy/pyring-buffer.git
PYTHON_PYRING_BUFFER_SITE_METHOD = git
PYTHON_PYRING_BUFFER_LICENSE = Apache-2.0
PYTHON_PYRING_BUFFER_SETUP_TYPE = setuptools

# Pure Python, sin dependencias
PYTHON_PYRING_BUFFER_DEPENDENCIES =

$(eval $(python-package))
