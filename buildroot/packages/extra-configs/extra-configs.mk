################################################################################
#
# extra-configs
#
################################################################################

EXTRA_CONFIGS_VERSION = 1.0
EXTRA_CONFIGS_LICENSE = MIT
EXTRA_CONFIGS_SOURCE =

define EXTRA_CONFIGS_INSTALL_TARGET_CMDS
	sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' \
		$(TARGET_DIR)/etc/ssh/sshd_config
	sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' \
		$(TARGET_DIR)/etc/ssh/sshd_config
endef

$(eval $(generic-package))
