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

PYTHON_SOUNDCARD_DEPENDENCIES = python-cffi python-numpy-wheel pulseaudio

define PYTHON_SOUNDCARD_INSTALL_INIT_SYSV
	echo '#!/bin/sh' > $(TARGET_DIR)/etc/init.d/S01pulsegroup
	echo 'case "$$1" in' >> $(TARGET_DIR)/etc/init.d/S01pulsegroup
	echo '  start)' >> $(TARGET_DIR)/etc/init.d/S01pulsegroup
	echo '    grep -q "^pulse-access:.*:root" /etc/group || \' >> $(TARGET_DIR)/etc/init.d/S01pulsegroup
	echo '    sed -i "s/^\(pulse-access:x:[0-9]*:\)pulse$$/\1pulse,root/" /etc/group' >> $(TARGET_DIR)/etc/init.d/S01pulsegroup
	echo '    ;;' >> $(TARGET_DIR)/etc/init.d/S01pulsegroup
	echo 'esac' >> $(TARGET_DIR)/etc/init.d/S01pulsegroup
	chmod +x $(TARGET_DIR)/etc/init.d/S01pulsegroup
endef


$(eval $(python-package))
