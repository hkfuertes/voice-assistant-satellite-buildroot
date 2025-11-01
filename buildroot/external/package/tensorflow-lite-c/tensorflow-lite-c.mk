################################################################################
#
# tensorflow-lite-c
#
################################################################################

TENSORFLOW_LITE_C_VERSION = 2.11.0
TENSORFLOW_LITE_C_SITE = $(call github,tensorflow,tensorflow,v$(TENSORFLOW_LITE_C_VERSION))
TENSORFLOW_LITE_C_INSTALL_STAGING = YES
TENSORFLOW_LITE_C_LICENSE = Apache-2.0
TENSORFLOW_LITE_C_LICENSE_FILES = LICENSE
TENSORFLOW_LITE_C_SUBDIR = tensorflow/lite
TENSORFLOW_LITE_C_SUPPORTS_IN_SOURCE_BUILD = NO
TENSORFLOW_LITE_C_DEPENDENCIES += \
    host-pkgconf \
    host-flatbuffers \
    cpuinfo \
    eigen \
    farmhash \
    fft2d \
    flatbuffers \
    gemmlowp \
    libabseil-cpp \
    neon-2-sse

TENSORFLOW_LITE_C_CONF_OPTS = \
    -Dabsl_DIR=$(STAGING_DIR)/usr/lib/cmake/absl \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_CXX_FLAGS="$(TARGET_CXXFLAGS) -I$(STAGING_DIR)/usr/include/gemmlowp" \
    -DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DEigen3_DIR=$(STAGING_DIR)/usr/share/eigen3/cmake \
    -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
    -DFETCHCONTENT_QUIET=OFF \
    -DFFT2D_SOURCE_DIR=$(STAGING_DIR)/usr/include/fft2d \
    -DFlatBuffers_DIR=$(STAGING_DIR)/usr/lib/cmake/flatbuffers \
    -DNEON_2_SSE_DIR=$(STAGING_DIR)/usr/lib/cmake/NEON_2_SSE \
    -DSYSTEM_FARMHASH=ON \
    -DTFLITE_ENABLE_EXTERNAL_DELEGATE=ON \
    -DTFLITE_ENABLE_GPU=OFF \
    -DTFLITE_ENABLE_INSTALL=ON \
    -DTFLITE_ENABLE_MMAP=ON \
    -DTFLITE_ENABLE_NNAPI=OFF

ifeq ($(BR2_PACKAGE_RUY),y)
TENSORFLOW_LITE_C_DEPENDENCIES += ruy
TENSORFLOW_LITE_C_CONF_OPTS += -DTFLITE_ENABLE_RUY=ON
else
TENSORFLOW_LITE_C_CONF_OPTS += -DTFLITE_ENABLE_RUY=OFF
endif

ifeq ($(BR2_PACKAGE_XNNPACK),y)
TENSORFLOW_LITE_C_DEPENDENCIES += xnnpack
TENSORFLOW_LITE_C_CONF_OPTS += -DTFLITE_ENABLE_XNNPACK=ON -Dxnnpack_POPULATED=ON
else
TENSORFLOW_LITE_C_CONF_OPTS += -DTFLITE_ENABLE_XNNPACK=OFF
endif

# Build C API manually by compiling source files and linking with main lib
define TENSORFLOW_LITE_C_BUILD_C_API_MANUAL
	mkdir -p $(@D)/build_c_api
	cd $(@D)/build_c_api && \
	$(TARGET_CXX) -shared -fPIC \
		-I$(@D) \
		-I$(STAGING_DIR)/usr/include \
		-o libtensorflowlite_c.so \
		$(@D)/tensorflow/lite/c/c_api.cc \
		$(@D)/tensorflow/lite/c/c_api_experimental.cc \
		$(@D)/tensorflow/lite/c/c_api_opaque.cc \
		$(@D)/tensorflow/lite/c/c_api_opaque_internal.cc \
		$(@D)/tensorflow/lite/c/common.cc \
		-L$(@D)/tensorflow/lite/buildroot-build \
		-ltensorflow-lite \
		-Wl,-rpath-link,$(@D)/tensorflow/lite/buildroot-build
endef

TENSORFLOW_LITE_C_POST_BUILD_HOOKS += TENSORFLOW_LITE_C_BUILD_C_API_MANUAL

# Install C API library
define TENSORFLOW_LITE_C_INSTALL_C_LIB
	if [ -f $(@D)/build_c_api/libtensorflowlite_c.so ]; then \
		$(INSTALL) -D -m 0755 $(@D)/build_c_api/libtensorflowlite_c.so \
			$(TARGET_DIR)/usr/lib/libtensorflowlite_c.so; \
		$(INSTALL) -D -m 0755 $(@D)/build_c_api/libtensorflowlite_c.so \
			$(STAGING_DIR)/usr/lib/libtensorflowlite_c.so; \
	fi
	mkdir -p $(TARGET_DIR)/usr/include/tensorflow/lite/c
	mkdir -p $(STAGING_DIR)/usr/include/tensorflow/lite/c
	for header in c_api.h c_api_experimental.h c_api_types.h common.h builtin_op_data.h; do \
		if [ -f $(@D)/tensorflow/lite/c/$$header ]; then \
			cp -f $(@D)/tensorflow/lite/c/$$header $(TARGET_DIR)/usr/include/tensorflow/lite/c/; \
			cp -f $(@D)/tensorflow/lite/c/$$header $(STAGING_DIR)/usr/include/tensorflow/lite/c/; \
		fi; \
	done
endef

TENSORFLOW_LITE_C_POST_INSTALL_TARGET_HOOKS += TENSORFLOW_LITE_C_INSTALL_C_LIB
TENSORFLOW_LITE_C_POST_INSTALL_STAGING_HOOKS += TENSORFLOW_LITE_C_INSTALL_C_LIB

$(eval $(cmake-package))
