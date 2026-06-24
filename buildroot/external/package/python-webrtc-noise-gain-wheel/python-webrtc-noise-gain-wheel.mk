################################################################################
#
# python-webrtc-noise-gain-wheel
#
################################################################################

PYTHON_WEBRTC_NOISE_GAIN_WHEEL_VERSION = 1.3.0

ifeq ($(BR2_aarch64),y)
    PYTHON_WEBRTC_NOISE_GAIN_WHEEL_SITE = https://files.pythonhosted.org/packages/bc/e2/711f829859a869aeda2dd58bc9eed32261418c5d1942b2d7929056fe74a0
    PYTHON_WEBRTC_NOISE_GAIN_WHEEL_SOURCE = webrtc_noise_gain-1.3.0-cp39-abi3-manylinux_2_27_aarch64.manylinux_2_28_aarch64.whl
else ifeq ($(BR2_x86_64),y)
    PYTHON_WEBRTC_NOISE_GAIN_WHEEL_SITE = https://files.pythonhosted.org/packages/3c/0f/b475e7c58de013d634df63da60e3d9a81601d8416c212739ab0eeb21e478
    PYTHON_WEBRTC_NOISE_GAIN_WHEEL_SOURCE = webrtc_noise_gain-1.3.0-cp39-abi3-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl
else
    $(error Unsupported architecture for python-webrtc-noise-gain-wheel. \
        Supported via prebuilt wheel: aarch64, x86_64. \
        No armv7l wheel exists upstream; cross-compilation from source not yet implemented.)
endif

PYTHON_WEBRTC_NOISE_GAIN_PYTHON_VERSION = $(shell $(HOST_DIR)/bin/python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "3.13")

define PYTHON_WEBRTC_NOISE_GAIN_WHEEL_DOWNLOAD_CMDS
    $(call DOWNLOAD_CACHED, \
        $(PYTHON_WEBRTC_NOISE_GAIN_WHEEL_SITE)/$(PYTHON_WEBRTC_NOISE_GAIN_WHEEL_SOURCE), \
        $(PYTHON_WEBRTC_NOISE_GAIN_WHEEL_SOURCE))
endef

define PYTHON_WEBRTC_NOISE_GAIN_WHEEL_EXTRACT_CMDS
    mkdir -p $(@D)
    touch $(@D)/.stamp_extracted
endef

define PYTHON_WEBRTC_NOISE_GAIN_WHEEL_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/lib/python$(PYTHON_WEBRTC_NOISE_GAIN_PYTHON_VERSION)/site-packages
    unzip -q -o $(PYTHON_WEBRTC_NOISE_GAIN_WHEEL_DL_DIR)/$(PYTHON_WEBRTC_NOISE_GAIN_WHEEL_SOURCE) \
        -d $(TARGET_DIR)/usr/lib/python$(PYTHON_WEBRTC_NOISE_GAIN_PYTHON_VERSION)/site-packages
endef

define PYTHON_WEBRTC_NOISE_GAIN_WHEEL_INSTALL_STAGING_CMDS
    mkdir -p $(STAGING_DIR)/usr/lib/python$(PYTHON_WEBRTC_NOISE_GAIN_PYTHON_VERSION)/site-packages
    unzip -q -o $(PYTHON_WEBRTC_NOISE_GAIN_WHEEL_DL_DIR)/$(PYTHON_WEBRTC_NOISE_GAIN_WHEEL_SOURCE) \
        -d $(STAGING_DIR)/usr/lib/python$(PYTHON_WEBRTC_NOISE_GAIN_PYTHON_VERSION)/site-packages
endef

$(eval $(generic-package))
