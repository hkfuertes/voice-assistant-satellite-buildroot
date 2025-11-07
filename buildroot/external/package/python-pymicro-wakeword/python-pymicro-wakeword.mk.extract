################################################################################
#
# python-pymicro-wakeword
#
################################################################################

PYTHON_PYMICRO_WAKEWORD_VERSION = 2.1.0
PYTHON_PYMICRO_WAKEWORD_LICENSE = Apache-2.0
PYTHON_PYMICRO_WAKEWORD_SOURCE = 

define PYTHON_PYMICRO_WAKEWORD_INSTALL_TARGET_CMDS
	unzip -o -d $(TARGET_DIR)/usr/lib/python3.13/site-packages/ \
		$(PYTHON_PYMICRO_WAKEWORD_PKGDIR)/pymicro_wakeword-$(PYTHON_PYMICRO_WAKEWORD_VERSION)-py3-none-manylinux_2_35_aarch64.whl
endef

$(eval $(generic-package))
