################################################################################
#
# python-netifaces2-wheel - precompiled netifaces2 wheel installer
#
################################################################################

PYTHON_NETIFACES2_WHEEL_VERSION = 0.0.22

ifeq ($(BR2_aarch64),y)
    PYTHON_NETIFACES2_WHEEL_SITE = https://files.pythonhosted.org/packages/ba/cb/78613bbabe140763fa5ffb9e9098c35c74440b091a21025ad4acc8e6c2a4
    PYTHON_NETIFACES2_WHEEL_SOURCE = netifaces2-0.0.22-cp37-abi3-manylinux_2_17_aarch64.manylinux2014_aarch64.whl
else ifeq ($(BR2_arm),y)
    PYTHON_NETIFACES2_WHEEL_SITE = https://files.pythonhosted.org/packages/36/1d/4dfb25228d9047ae9bc2f72f14260ffdc6a72b436dc1af6c954e50d45cce
    PYTHON_NETIFACES2_WHEEL_SOURCE = netifaces2-0.0.22-cp37-abi3-manylinux_2_17_armv7l.manylinux2014_armv7l.whl
else ifeq ($(BR2_x86_64),y)
    PYTHON_NETIFACES2_WHEEL_SITE = https://files.pythonhosted.org/packages/d4/e9/fcbf4c0e84037e072364696927e6e12d78ce69c93eaaf9b382b8655bbdc8
    PYTHON_NETIFACES2_WHEEL_SOURCE = netifaces2-0.0.22-cp37-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl
else
    $(error Unsupported architecture for python-netifaces2-wheel. Supported: aarch64, arm, x86_64)
endif

PYTHON_NETIFACES2_PYTHON_VERSION = $(shell $(HOST_DIR)/bin/python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "3.13")

define PYTHON_NETIFACES2_WHEEL_DOWNLOAD_CMDS
    $(call DOWNLOAD_CACHED, \
        $(PYTHON_NETIFACES2_WHEEL_SITE)/$(PYTHON_NETIFACES2_WHEEL_SOURCE), \
        $(PYTHON_NETIFACES2_WHEEL_SOURCE))
endef

define PYTHON_NETIFACES2_WHEEL_EXTRACT_CMDS
    mkdir -p $(@D)
    touch $(@D)/.stamp_extracted
endef

define PYTHON_NETIFACES2_WHEEL_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/lib/python$(PYTHON_NETIFACES2_PYTHON_VERSION)/site-packages
    unzip -q -o $(PYTHON_NETIFACES2_WHEEL_DL_DIR)/$(PYTHON_NETIFACES2_WHEEL_SOURCE) \
        -d $(TARGET_DIR)/usr/lib/python$(PYTHON_NETIFACES2_PYTHON_VERSION)/site-packages
endef

define PYTHON_NETIFACES2_WHEEL_INSTALL_STAGING_CMDS
    mkdir -p $(STAGING_DIR)/usr/lib/python$(PYTHON_NETIFACES2_PYTHON_VERSION)/site-packages
    unzip -q -o $(PYTHON_NETIFACES2_WHEEL_DL_DIR)/$(PYTHON_NETIFACES2_WHEEL_SOURCE) \
        -d $(STAGING_DIR)/usr/lib/python$(PYTHON_NETIFACES2_PYTHON_VERSION)/site-packages
endef

$(eval $(generic-package))
