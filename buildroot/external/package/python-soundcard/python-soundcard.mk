################################################################################
#
# python-soundcard
#
################################################################################

PYTHON_SOUNDCARD_VERSION = 0.4.5
PYTHON_SOUNDCARD_SITE = https://github.com/bastibe/SoundCard.git
PYTHON_SOUNDCARD_SITE_METHOD = git
PYTHON_SOUNDCARD_SETUP_TYPE = setuptools
PYTHON_SOUNDCARD_LICENSE = BSD-3-Clause
PYTHON_SOUNDCARD_LICENSE_FILES = LICENSE

PYTHON_SOUNDCARD_DEPENDENCIES = python-cffi python-numpy pulseaudio

define FIX_PULSEAUDIO_GROUP
	sed -i 's/^\(pulse-access:x:[0-9]*:\)pulse$$/\1pulse,root/' $(TARGET_DIR)/etc/group
endef

PYTHON_SOUNDCARD_TARGET_FINALIZE_HOOKS += FIX_PULSEAUDIO_GROUP

$(eval $(python-package))
