################################################################################
#
# rpi-utils
#
################################################################################

RPI_UTILS_VERSION = master
RPI_UTILS_SITE = $(call github,raspberrypi,utils,$(RPI_UTILS_VERSION))
RPI_UTILS_LICENSE = BSD-3-Clause
RPI_UTILS_LICENSE_FILES = LICENCE
RPI_UTILS_DEPENDENCIES = dtc host-pkgconf

# rpi-utils usa CMake
RPI_UTILS_CONF_OPTS = -DBUILD_SHARED_LIBS=OFF

# Instalar solo los binarios que necesitas
define RPI_UTILS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/dtmerge/dtoverlay $(TARGET_DIR)/usr/bin/dtoverlay
	$(INSTALL) -D -m 0755 $(@D)/dtmerge/dtparam $(TARGET_DIR)/usr/bin/dtparam
	$(INSTALL) -D -m 0755 $(@D)/vclog/vclog $(TARGET_DIR)/usr/bin/vclog
	$(INSTALL) -D -m 0755 $(@D)/pinctrl/pinctrl $(TARGET_DIR)/usr/bin/pinctrl
endef

$(eval $(cmake-package))
