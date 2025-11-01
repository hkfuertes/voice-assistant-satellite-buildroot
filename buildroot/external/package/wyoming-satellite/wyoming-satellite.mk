WYOMING_SATELLITE_VERSION = 13bb0249310391bb7b7f6e109ddcc0d7d76223c1
WYOMING_SATELLITE_SITE = https://github.com/rhasspy/wyoming-satellite.git
WYOMING_SATELLITE_SITE_METHOD = git
WYOMING_SATELLITE_LICENSE = MIT
WYOMING_SATELLITE_SETUP_TYPE = setuptools

WYOMING_SATELLITE_DEPENDENCIES = \
    host-python3-setuptools \
    python3 \
    python-spidev \
    python-numpy \
    python-zeroconf \
    alsa-lib \
    alsa-utils \
    python-wyoming \
    python-pyring-buffer

# Hook post-instalación: generar scripts y configs
define WYOMING_SATELLITE_INSTALL_INIT_SCRIPTS
    mkdir -p $(TARGET_DIR)/etc/init.d
    
    # Generar init script desde template
    sed -e 's|@SATELLITE_NAME@|$(call qstrip,$(BR2_PACKAGE_WYOMING_SATELLITE_NAME))|g' \
        -e 's|@WAKE_URI@|$(call qstrip,$(BR2_PACKAGE_WYOMING_SATELLITE_WAKE_URI))|g' \
        -e 's|@WAKE_WORD@|$(call qstrip,$(BR2_PACKAGE_WYOMING_SATELLITE_WAKE_WORD))|g' \
        $(WYOMING_SATELLITE_PKGDIR)/files/S95wyoming-satellite.in \
        > $(TARGET_DIR)/etc/init.d/S95wyoming-satellite
    chmod 0755 $(TARGET_DIR)/etc/init.d/S95wyoming-satellite
    
    # Instalar CPU governor script
    $(INSTALL) -D -m 0755 $(WYOMING_SATELLITE_PKGDIR)/files/S10cpufreq \
        $(TARGET_DIR)/etc/init.d/S10cpufreq
endef

WYOMING_SATELLITE_POST_INSTALL_TARGET_HOOKS += WYOMING_SATELLITE_INSTALL_INIT_SCRIPTS

# LEDs support
ifeq ($(BR2_PACKAGE_WYOMING_SATELLITE_LEDS),y)
define WYOMING_SATELLITE_INSTALL_LEDS
    $(HOST_DIR)/bin/pip3 install \
        --prefix=$(TARGET_DIR)/usr \
        --root=/ \
        --no-deps \
        --quiet \
        rpi-lgpio gpiozero colorzero || true
    
    if [ -f $(@D)/examples/2mic_service.py ]; then \
        $(INSTALL) -D -m 0755 $(@D)/examples/2mic_service.py \
            $(TARGET_DIR)/usr/bin/wyoming-2mic-leds; \
    fi
    
    $(INSTALL) -D -m 0755 $(WYOMING_SATELLITE_PKGDIR)/files/S80wyoming-leds \
        $(TARGET_DIR)/etc/init.d/S80wyoming-leds
endef

WYOMING_SATELLITE_POST_INSTALL_TARGET_HOOKS += WYOMING_SATELLITE_INSTALL_LEDS
endif

# Modificar config.txt si LEDs habilitados
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
