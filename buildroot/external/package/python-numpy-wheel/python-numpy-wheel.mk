################################################################################
#
# python-numpy-wheel - precompiled numpy wheel installer for ARM
#
################################################################################

PYTHON_NUMPY_WHEEL_VERSION = 2.3.4

# URLs de los wheels
ifeq ($(BR2_aarch64),y)
    PYTHON_NUMPY_WHEEL_ARCH = aarch64
    PYTHON_NUMPY_WHEEL_SITE = https://files.pythonhosted.org/packages/3e/d1/913fe563820f3c6b079f992458f7331278dcd7ba8427e8e745af37ddb44f
    PYTHON_NUMPY_WHEEL_SOURCE = numpy-2.3.4-cp313-cp313-manylinux_2_27_aarch64.manylinux_2_28_aarch64.whl
else ifeq ($(BR2_arm),y)
    PYTHON_NUMPY_WHEEL_ARCH = armv7l
    PYTHON_NUMPY_WHEEL_SITE = https://www.piwheels.org/simple/numpy
    PYTHON_NUMPY_WHEEL_SOURCE = numpy-2.3.4-cp313-cp313-linux_armv7l.whl
else
    $(error Unsupported architecture for python-numpy-wheel)
endif

PYTHON_NUMPY_PYTHON_VERSION = $(shell $(HOST_DIR)/bin/python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "3.13")

define PYTHON_NUMPY_WHEEL_DOWNLOAD_CMDS
	$(call DOWNLOAD_CACHED, \
		$(PYTHON_NUMPY_WHEEL_SITE)/$(PYTHON_NUMPY_WHEEL_SOURCE), \
		$(PYTHON_NUMPY_WHEEL_SOURCE))
endef

define PYTHON_NUMPY_WHEEL_EXTRACT_CMDS
	mkdir -p $(@D)
	touch $(@D)/.stamp_extracted
endef

define PYTHON_NUMPY_WHEEL_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/lib/python$(PYTHON_NUMPY_PYTHON_VERSION)/site-packages
	unzip -q -o $(PYTHON_NUMPY_WHEEL_DL_DIR)/$(PYTHON_NUMPY_WHEEL_SOURCE) \
		-d $(TARGET_DIR)/usr/lib/python$(PYTHON_NUMPY_PYTHON_VERSION)/site-packages
endef

define PYTHON_NUMPY_WHEEL_INSTALL_STAGING_CMDS
	mkdir -p $(STAGING_DIR)/usr/lib/python$(PYTHON_NUMPY_PYTHON_VERSION)/site-packages
	unzip -q -o $(PYTHON_NUMPY_WHEEL_DL_DIR)/$(PYTHON_NUMPY_WHEEL_SOURCE) \
		-d $(STAGING_DIR)/usr/lib/python$(PYTHON_NUMPY_PYTHON_VERSION)/site-packages
endef

$(eval $(generic-package))
