################################################################################
#
# tensorflow-lite-c-prebuilt
#
################################################################################

TENSORFLOW_LITE_C_PREBUILT_VERSION = 2.17.1
TENSORFLOW_LITE_C_PREBUILT_SITE = $(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/package/tensorflow-lite-c-prebuilt/files
TENSORFLOW_LITE_C_PREBUILT_SITE_METHOD = local
TENSORFLOW_LITE_C_PREBUILT_INSTALL_STAGING = YES
TENSORFLOW_LITE_C_PREBUILT_INSTALL_TARGET = YES

# Detect architecture and set the correct library file
ifeq ($(BR2_x86_64),y)
TENSORFLOW_LITE_C_PREBUILT_LIB = linux_amd64_libtensorflowlite_c.so.$(TENSORFLOW_LITE_C_PREBUILT_VERSION)
else ifeq ($(BR2_aarch64),y)
TENSORFLOW_LITE_C_PREBUILT_LIB = linux_arm64_libtensorflowlite_c.so.$(TENSORFLOW_LITE_C_PREBUILT_VERSION)
else
$(error Unsupported architecture for tensorflow-lite-c-prebuilt)
endif

# No build step needed for prebuilt libraries
define TENSORFLOW_LITE_C_PREBUILT_BUILD_CMDS
    # Nothing to build - precompiled library
endef

# Install to staging directory
define TENSORFLOW_LITE_C_PREBUILT_INSTALL_STAGING_CMDS
    $(INSTALL) -D -m 0755 $(@D)/$(TENSORFLOW_LITE_C_PREBUILT_LIB) \
        $(STAGING_DIR)/usr/lib/libtensorflowlite_c.so
    ln -sf libtensorflowlite_c.so $(STAGING_DIR)/usr/lib/libtensorflow-lite.so
endef

# Install to target directory
define TENSORFLOW_LITE_C_PREBUILT_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/$(TENSORFLOW_LITE_C_PREBUILT_LIB) \
        $(TARGET_DIR)/usr/lib/libtensorflowlite_c.so
    ln -sf libtensorflowlite_c.so $(TARGET_DIR)/usr/lib/libtensorflow-lite.so
endef

$(eval $(generic-package))
