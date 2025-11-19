#!/usr/bin/env python3
"""APA102 LED Driver and Controller for ReSpeaker 2mic HAT"""
import logging
import time
from math import ceil

try:
    import spidev
    import gpiozero
    HAS_HARDWARE = True
except ImportError:
    HAS_HARDWARE = False

_LOGGER = logging.getLogger(__name__)

RGB_MAP = {
    "rgb": [3, 2, 1],
    "rbg": [3, 1, 2],
    "grb": [2, 3, 1],
    "gbr": [2, 1, 3],
    "brg": [1, 3, 2],
    "bgr": [1, 2, 3],
}

# Predefined colors
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
RED = (255, 0, 0)
YELLOW = (255, 255, 0)
BLUE = (0, 0, 255)
GREEN = (0, 255, 0)


class APA102:
    """Driver for APA102 LEDs (DotStar)"""

    MAX_BRIGHTNESS = 0b11111
    LED_START = 0b11100000

    def __init__(
        self,
        num_led,
        global_brightness,
        order="rgb",
        bus=0,
        device=1,
        max_speed_hz=8000000,
    ):
        self.num_led = num_led
        order = order.lower()
        self.rgb = RGB_MAP.get(order, RGB_MAP["rgb"])
        
        if global_brightness > self.MAX_BRIGHTNESS:
            self.global_brightness = self.MAX_BRIGHTNESS
        else:
            self.global_brightness = global_brightness
        
        _LOGGER.debug("LED brightness: %d", self.global_brightness)

        self.leds = [self.LED_START, 0, 0, 0] * self.num_led
        self.spi = spidev.SpiDev()
        self.spi.open(bus, device)
        
        if max_speed_hz:
            self.spi.max_speed_hz = max_speed_hz

    def clock_start_frame(self):
        """Sends start frame to the LED strip"""
        self.spi.xfer2([0] * 4)

    def clock_end_frame(self):
        """Sends end frame to the LED strip"""
        self.spi.xfer2([0xFF] * 4)

    def set_pixel(self, led_num, red, green, blue, bright_percent=100):
        """Sets the color of a single pixel"""
        if led_num < 0 or led_num >= self.num_led:
            return

        brightness = int(ceil(bright_percent * self.global_brightness / 100.0))
        ledstart = (brightness & 0b00011111) | self.LED_START

        start_index = 4 * led_num
        self.leds[start_index] = ledstart
        self.leds[start_index + self.rgb[0]] = red
        self.leds[start_index + self.rgb[1]] = green
        self.leds[start_index + self.rgb[2]] = blue

    def set_all(self, red, green, blue, bright_percent=100):
        """Sets all LEDs to the same color"""
        for i in range(self.num_led):
            self.set_pixel(i, red, green, blue, bright_percent)

    def show(self):
        """Sends the buffer to the LED strip"""
        self.clock_start_frame()
        data = list(self.leds)
        while data:
            self.spi.xfer2(data[:32])
            data = data[32:]
        self.clock_end_frame()

    def cleanup(self):
        """Releases the SPI device"""
        self.spi.close()


class LEDController:
    """High-level controller for ReSpeaker LEDs"""
    
    def __init__(self, num_leds=3, gpio=12, brightness=8):
        self.enabled = False
        
        if not HAS_HARDWARE:
            _LOGGER.info("LED hardware not available, LEDs disabled")
            return
        
        try:
            # Turn on power to LEDs
            self.led_power = gpiozero.LED(gpio, active_high=False)
            self.led_power.on()
            
            # Initialize APA102 driver
            self.leds = APA102(num_led=num_leds, global_brightness=brightness)
            self.enabled = True
            _LOGGER.info("LEDs initialized")
        except Exception as e:
            self.enabled = False
            _LOGGER.error(f"Failed to initialize LEDs: {e}")
    
    def set_color(self, color):
        """Sets color on all LEDs"""
        if not self.enabled:
            return
        try:
            self.leds.set_all(color[0], color[1], color[2])
            self.leds.show()
        except Exception as e:
            _LOGGER.error(f"Error setting color: {e}")
    
    def flash(self, color, times=3, delay=0.3):
        """Flashes the LEDs"""
        if not self.enabled:
            return
        for _ in range(times):
            self.set_color(color)
            time.sleep(delay)
            self.set_color(BLACK)
            time.sleep(delay)
    
    def cleanup(self):
        """Cleans up LED resources"""
        if not self.enabled:
            return
        try:
            self.set_color(BLACK)
            self.leds.cleanup()
            self.led_power.off()
        except Exception as e:
            _LOGGER.error(f"Error during cleanup: {e}")
