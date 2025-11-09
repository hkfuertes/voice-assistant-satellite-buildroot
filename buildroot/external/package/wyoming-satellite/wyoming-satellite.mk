################################################################################
#
# wyoming-satellite
#
################################################################################

WYOMING_SATELLITE_VERSION = 13bb0249310391bb7b7f6e109ddcc0d7d76223c1
WYOMING_SATELLITE_SITE = https://github.com/rhasspy/wyoming-satellite.git
WYOMING_SATELLITE_SITE_METHOD = git
WYOMING_SATELLITE_LICENSE = MIT
WYOMING_SATELLITE_SETUP_TYPE = setuptools

WYOMING_SATELLITE_DEPENDENCIES = \
	host-python3 \
	host-python-pip \
	python-spidev \
	python-numpy-wheel \
	python-zeroconf \
	python-wyoming \
	python-pyring-buffer

define WYOMING_SATELLITE_INSTALL_INIT_SCRIPTS
	mkdir -p $(TARGET_DIR)/etc/init.d
	
	# Generate init script from template
	sed -e 's|@SATELLITE_NAME@|$(call qstrip,$(BR2_PACKAGE_WYOMING_SATELLITE_NAME))|g' \
		-e 's|@WAKE_URI@|$(call qstrip,$(BR2_PACKAGE_WYOMING_SATELLITE_WAKE_URI))|g' \
		-e 's|@WAKE_WORD@|$(call qstrip,$(BR2_PACKAGE_WYOMING_SATELLITE_WAKE_WORD))|g' \
		-e 's|@ENABLE_LEDS@|$(if $(BR2_PACKAGE_WYOMING_SATELLITE_LEDS),y,n)|g' \
		$(WYOMING_SATELLITE_PKGDIR)/files/S95wyoming-satellite.in \
		> $(TARGET_DIR)/etc/init.d/S95wyoming-satellite
	chmod 0755 $(TARGET_DIR)/etc/init.d/S95wyoming-satellite
	
	# Install CPU frequency scaling script
	$(INSTALL) -D -m 0755 $(WYOMING_SATELLITE_PKGDIR)/files/S10cpufreq \
		$(TARGET_DIR)/etc/init.d/S10cpufreq
endef

WYOMING_SATELLITE_POST_INSTALL_TARGET_HOOKS += WYOMING_SATELLITE_INSTALL_INIT_SCRIPTS

ifeq ($(BR2_PACKAGE_WYOMING_SATELLITE_LEDS),y)
define WYOMING_SATELLITE_INSTALL_LEDS
	# Install LED support packages
	$(HOST_DIR)/bin/pip3 install \
		--prefix=$(TARGET_DIR)/usr \
		--no-deps \
		rpi-lgpio gpiozero colorzero
	
	# Install LED service script
	if [ -f $(@D)/examples/2mic_service.py ]; then \
		$(INSTALL) -D -m 0755 $(@D)/examples/2mic_service.py \
			$(TARGET_DIR)/usr/bin/wyoming-2mic-leds; \
	fi
	
	$(INSTALL) -D -m 0755 $(WYOMING_SATELLITE_PKGDIR)/files/S80wyoming-leds \
		$(TARGET_DIR)/etc/init.d/S80wyoming-leds
endef

WYOMING_SATELLITE_POST_INSTALL_TARGET_HOOKS += WYOMING_SATELLITE_INSTALL_LEDS
endif

ifeq ($(BR2_PACKAGE_WYOMING_SATELLITE_LEDS),y)
define WYOMING_SATELLITE_RPI_FIRMWARE_FIXUP
	if [ -f $(BINARIES_DIR)/rpi-firmware/config.txt ]; then \
		grep -q "dtparam=spi=on" $(BINARIES_DIR)/rpi-firmware/config.txt || \
		echo "dtparam=spi=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt; \
	fi
endef

WYOMING_SATELLITE_POST_INSTALL_TARGET_HOOKS += WYOMING_SATELLITE_RPI_FIRMWARE_FIXUP
endif

$(eval $(python-package))
