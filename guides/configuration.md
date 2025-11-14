#### WiFi Setup

Zeroconf is enabled by default, so once the device is connected to WiFi it should be autodiscovered by Home Assistant.

To connect to WiFi, create a `wpa_supplicant.conf` file in the `/boot` partition:

```conf
country=ES
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="YourSSID"
    psk="YourPassword"
}
```

#### Home Assistant Integration

The device will auto-discover via Zeroconf. Alternatively, manually add:

1. Go to Settings → Devices & Services
2. Add Integration → ESPHome
3. Enter device IP: `192.168.x.x:6053`
