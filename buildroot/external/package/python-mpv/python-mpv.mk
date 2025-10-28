################################################################################
#
# python-mpv
#
################################################################################

PYTHON_MPV_VERSION = 1.0.8
PYTHON_MPV_SITE = $(call github,jaseg,python-mpv,v$(PYTHON_MPV_VERSION))
PYTHON_MPV_LICENSE = GPL-2.0-or-later OR LGPL-2.0-or-later
PYTHON_MPV_LICENSE_FILES = LICENSE
PYTHON_MPV_SETUP_TYPE = setuptools
PYTHON_MPV_DEPENDENCIES = python3 mpv

# Fix library path for embedded Linux without ldconfig
define PYTHON_MPV_FIX_LIBRARY_PATH
	sed -i '/sofile = ctypes.util.find_library/,/backend = CDLL(sofile)/c\    backend = CDLL("libmpv.so.2")' \
		$(TARGET_DIR)/usr/lib/python3.13/site-packages/mpv.py
endef

PYTHON_MPV_POST_INSTALL_TARGET_HOOKS += PYTHON_MPV_FIX_LIBRARY_PATH

$(eval $(python-package))
