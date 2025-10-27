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
	python3 \
	python-numpy \
	python-zeroconf \
	alsa-lib \
	alsa-utils

define WYOMING_SATELLITE_INSTALL_TARGET_CMDS
	# Instalar Wyoming Satellite
	cd $(@D) && \
		$(HOST_DIR)/bin/pip3 install \
		--prefix=$(TARGET_DIR)/usr \
		--root=/ \
		--no-deps \
		--no-build-isolation \
		--trusted-host pypi.org \
		--trusted-host files.pythonhosted.org \
		.
	
	# Instalar dependencias
	$(HOST_DIR)/bin/pip3 install \
		--prefix=$(TARGET_DIR)/usr \
		--root=/ \
		--no-deps \
		'wyoming==1.5.4' 'pyring-buffer>=1,<2' || true
	
	# Fix shebang
	if [ -f $(TARGET_DIR)/usr/bin/wyoming-satellite ]; then \
		sed -i '1s|^#!/.*python|#!/usr/bin/env python3|' \
			$(TARGET_DIR)/usr/bin/wyoming-satellite; \
	fi
	
	# Instalar init script
	$(INSTALL) -D -m 0755 $(WYOMING_SATELLITE_PKGDIR)/files/S90wyoming-satellite \
		$(TARGET_DIR)/etc/init.d/S90wyoming-satellite
	
	$(INSTALL) -D -m 0755$(WYOMING_SATELLITE_PKGDIR)/files/S10cpufreq \
    	$(TARGET_DIR)/etc/init.d/S10cpufreq
	
	# LEDs si están habilitados
	if grep -q "BR2_PACKAGE_WYOMING_SATELLITE_LEDS=y" $(CONFIG_DIR)/.config; then \
		$(HOST_DIR)/bin/pip3 install \
			--prefix=$(TARGET_DIR)/usr \
			--root=/ \
			--no-deps \
			rpi-lgpio gpiozero colorzero || true; \
		if [ -f $(@D)/examples/2mic_service.py ]; then \
			$(INSTALL) -D -m 0755 $(@D)/examples/2mic_service.py \
				$(TARGET_DIR)/usr/bin/wyoming-2mic-leds; \
			sed -i '1s|^#!/.*python3|#!/usr/bin/env python3|' \
				$(TARGET_DIR)/usr/bin/wyoming-2mic-leds; \
		fi; \
		$(INSTALL) -D -m 0755 $(WYOMING_SATELLITE_PKGDIR)/files/S80wyoming-leds \
			$(TARGET_DIR)/etc/init.d/S80wyoming-leds; \
	fi
endef

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
