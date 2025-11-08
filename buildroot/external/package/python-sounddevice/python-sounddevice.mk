################################################################################
#
# python-sounddevice
#
################################################################################

PYTHON_SOUNDDEVICE_VERSION = 0.5.3
PYTHON_SOUNDDEVICE_SOURCE = sounddevice-$(PYTHON_SOUNDDEVICE_VERSION).tar.gz
PYTHON_SOUNDDEVICE_SITE = https://files.pythonhosted.org/packages/source/s/sounddevice
PYTHON_SOUNDDEVICE_LICENSE = MIT
PYTHON_SOUNDDEVICE_LICENSE_FILES = LICENSE
PYTHON_SOUNDDEVICE_SETUP_TYPE = setuptools
PYTHON_SOUNDDEVICE_DEPENDENCIES = python3 python-cffi portaudio host-python-cffi

$(eval $(python-package))
