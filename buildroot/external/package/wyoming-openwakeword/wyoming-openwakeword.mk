################################################################################
#
# wyoming-openwakeword (with venv for wyoming 1.8)
#
################################################################################

WYOMING_OPENWAKEWORD_VERSION = v2.1.0
WYOMING_OPENWAKEWORD_SITE = https://github.com/rhasspy/wyoming-openwakeword.git
WYOMING_OPENWAKEWORD_SITE_METHOD = git
WYOMING_OPENWAKEWORD_LICENSE = Apache-2.0
WYOMING_OPENWAKEWORD_SETUP_TYPE = setuptools


WYOMING_OPENWAKEWORD_VENV_DIR = /opt/wyoming-openwakeword
WYOMING_OPENWAKEWORD_DEPENDENCIES = \
    host-python3 \
    host-python-pip \
    python3 \
    python-numpy \
    python-pyopenwakeword \
	tensorflow-lite


define WYOMING_OPENWAKEWORD_INSTALL_TARGET_CMDS
    # Create venv WITHOUT pip in the target directory
    mkdir -p $(TARGET_DIR)$(WYOMING_OPENWAKEWORD_VENV_DIR)
    $(HOST_DIR)/bin/python3 -m venv \
        --system-site-packages \
        --without-pip \
        $(TARGET_DIR)$(WYOMING_OPENWAKEWORD_VENV_DIR)

    # Use HOST pip with --no-scripts to avoid bin pollution
    $(HOST_DIR)/bin/python3 -m pip install \
        --target=$(TARGET_DIR)$(WYOMING_OPENWAKEWORD_VENV_DIR)/lib/python3.*/site-packages \
        --upgrade pip setuptools wheel

    # Install wyoming
    cd $(@D) && $(HOST_DIR)/bin/python3 -m pip install \
        --target=$(TARGET_DIR)$(WYOMING_OPENWAKEWORD_VENV_DIR)/lib/python3.*/site-packages \
        "wyoming>=1.8,<2"

    # Install wyoming-openwakeword
    cd $(@D) && $(HOST_DIR)/bin/python3 -m pip install \
        --target=$(TARGET_DIR)$(WYOMING_OPENWAKEWORD_VENV_DIR)/lib/python3.*/site-packages \
        --no-deps \
		--upgrade \
        .

    # Fix python3 symlink
    rm -f $(TARGET_DIR)$(WYOMING_OPENWAKEWORD_VENV_DIR)/bin/python3
    ln -sf /usr/bin/python3 $(TARGET_DIR)$(WYOMING_OPENWAKEWORD_VENV_DIR)/bin/python3

    # Create wrapper script inline with echo
    mkdir -p $(TARGET_DIR)/usr/bin
    echo '#!/bin/sh' > $(TARGET_DIR)/usr/bin/wyoming-openwakeword
    echo 'PYTHONPATH=/opt/wyoming-openwakeword/lib/python3.*/site-packages:$$PYTHONPATH' >> $(TARGET_DIR)/usr/bin/wyoming-openwakeword
    echo 'exec /usr/bin/python3 -m wyoming_openwakeword "$$@"' >> $(TARGET_DIR)/usr/bin/wyoming-openwakeword
    chmod 0755 $(TARGET_DIR)/usr/bin/wyoming-openwakeword
endef


define WYOMING_OPENWAKEWORD_INSTALL_INIT_SYSV
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/wyoming-openwakeword/files/S85wyoming-openwakeword \
        $(TARGET_DIR)/etc/init.d/S85wyoming-openwakeword
endef


$(eval $(generic-package))
