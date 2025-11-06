################################################################################
#
# python-pyopenwakeword
#
################################################################################

PYTHON_PYOPENWAKEWORD_VERSION = v1.1.0
PYTHON_PYOPENWAKEWORD_SITE = https://github.com/rhasspy/pyopen-wakeword.git
PYTHON_PYOPENWAKEWORD_SITE_METHOD = git
PYTHON_PYOPENWAKEWORD_LICENSE = Apache-2.0
PYTHON_PYOPENWAKEWORD_SETUP_TYPE = setuptools

# Usa TensorFlow Lite precompilado, sin dependencias Python adicionales
PYTHON_PYOPENWAKEWORD_DEPENDENCIES = python-numpy

$(eval $(python-package))
