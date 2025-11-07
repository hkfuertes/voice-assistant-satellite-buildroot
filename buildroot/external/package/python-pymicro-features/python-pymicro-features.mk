################################################################################
#
# python-pymicro-features
#
################################################################################

PYTHON_PYMICRO_FEATURES_VERSION = 2.0.2
PYTHON_PYMICRO_FEATURES_LICENSE = MIT
PYTHON_PYMICRO_FEATURES_SOURCE =

define PYTHON_PYMICRO_FEATURES_INSTALL_TARGET_CMDS
	unzip -o -d $(TARGET_DIR)/usr/lib/python3.13/site-packages/ \
		$(PYTHON_PYMICRO_FEATURES_PKGDIR)/pymicro_features-$(PYTHON_PYMICRO_FEATURES_VERSION)-cp39-abi3-manylinux_2_27_aarch64.manylinux_2_28_aarch64.whl
endef

$(eval $(generic-package))
