################################################################################
#
# python-numpy-wheel - precompiled numpy wheel installer for ARM
#
################################################################################

PYTHON_NUMPY_WHEEL_VERSION = 2.3.4

# URLs de los wheels
ifeq ($(BR2_aarch64),y)
    PYTHON_NUMPY_WHEEL_ARCH = aarch64
    PYTHON_NUMPY_WHEEL_SITE = https://files.pythonhosted.org/packages/34/f1/4de9586d05b1962acdcdb1dc4af6646361a643f8c864cef7c852bf509740
    PYTHON_NUMPY_WHEEL_SOURCE = numpy-2.3.4-cp313-cp313-manylinux_2_27_aarch64.manylinux_2_28_aarch64.whl
else ifeq ($(BR2_arm),y)
    PYTHON_NUMPY_WHEEL_ARCH = armv7l
    PYTHON_NUMPY_WHEEL_SITE = https://www.piwheels.org/simple/numpy
    PYTHON_NUMPY_WHEEL_SOURCE = numpy-2.3.4-cp313-cp313-linux_armv7l.whl
else
    $(error Unsupported architecture for python-numpy-wheel)
endif

PYTHON_NUMPY_PYTHON_VERSION = $(shell $(HOST_DIR)/bin/python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "3.13")

# Descargar wheel
define PYTHON_NUMPY_WHEEL_DOWNLOAD_CMDS
	$(call DOWNLOAD_CACHED, \
		$(PYTHON_NUMPY_WHEEL_SITE)/$(PYTHON_NUMPY_WHEEL_SOURCE), \
		$(PYTHON_NUMPY_WHEEL_SOURCE))
endef

# Extraer wheel
define PYTHON_NUMPY_WHEEL_EXTRACT_CMDS
	mkdir -p $(@D)
	unzip -q $(PYTHON_NUMPY_WHEEL_DL_DIR)/$(PYTHON_NUMPY_WHEEL_SOURCE) -d $(@D)
endef

# Instalar target
define PYTHON_NUMPY_WHEEL_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/lib/python$(PYTHON_NUMPY_PYTHON_VERSION)/site-packages
	cp -r $(@D)/numpy $(TARGET_DIR)/usr/lib/python$(PYTHON_NUMPY_PYTHON_VERSION)/site-packages
	cp -r $(@D)/numpy-$(PYTHON_NUMPY_WHEEL_VERSION).dist-info $(TARGET_DIR)/usr/lib/python$(PYTHON_NUMPY_PYTHON_VERSION)/site-packages
	if [ -d $(@D)/numpy.libs ]; then \
		cp -r $(@D)/numpy.libs $(TARGET_DIR)/usr/lib/python$(PYTHON_NUMPY_PYTHON_VERSION)/site-packages; \
	fi
endef

# Instalar staging (para dependencias)
define PYTHON_NUMPY_WHEEL_INSTALL_STAGING_CMDS
	mkdir -p $(STAGING_DIR)/usr/lib/python$(PYTHON_NUMPY_PYTHON_VERSION)/site-packages
	cp -r $(@D)/numpy* $(STAGING_DIR)/usr/lib/python$(PYTHON_NUMPY_PYTHON_VERSION)/site-packages
endef

$(eval $(generic-package))
