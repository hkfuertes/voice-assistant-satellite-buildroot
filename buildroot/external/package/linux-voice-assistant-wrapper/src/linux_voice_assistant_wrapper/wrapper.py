#!/usr/bin/env python3
import sys
import logging
import asyncio
import re

try:
    from .led_controller import LEDController, BLACK, RED, YELLOW, BLUE, GREEN
    HAS_LEDS = True
except ImportError:
    HAS_LEDS = False
    BLACK = RED = YELLOW = BLUE = GREEN = None


state = {
    'conversation_active': False,
    'current_text': None,
    'leds': None
}


def init_leds():
    """Initializes the LED controller"""
    if not HAS_LEDS:
        print("[LED] Module not available")
        return
    
    state['leds'] = LEDController()
    if state['leds'].enabled:
        state['leds'].flash(GREEN, times=2, delay=0.2)


def led_action(action_fn):
    """Helper to execute LED actions if available"""
    if state.get('leds') and state['leds'].enabled:
        action_fn(state['leds'])


# =============================================================================
# ALL POSSIBLE EVENTS FROM linux_voice_assistant
# =============================================================================
# Wake word detection:
#   - wake_word: Triggered when wake word is detected (e.g., "Okay Nabu")
#
# Voice Assistant lifecycle events:
#   - VOICE_ASSISTANT_RUN_START: Conversation started
#   - VOICE_ASSISTANT_RUN_END: Conversation finished
#
# Speech-to-Text (STT) events:
#   - VOICE_ASSISTANT_STT_START: Started listening for voice
#   - VOICE_ASSISTANT_STT_VAD_START: Voice Activity Detection started
#   - VOICE_ASSISTANT_STT_VAD_END: Voice Activity Detection ended (silence)
#   - VOICE_ASSISTANT_STT_END: Speech recognized, contains 'text' field
#
# Intent processing events:
#   - VOICE_ASSISTANT_INTENT_START: Processing user intent
#   - VOICE_ASSISTANT_INTENT_END: Intent processed, contains 'conversation_id'
#
# Text-to-Speech (TTS) events:
#   - VOICE_ASSISTANT_TTS_START: Generating TTS response, contains 'text' field
#   - VOICE_ASSISTANT_TTS_END: TTS ready, contains 'url' field
#
# Error events:
#   - VOICE_ASSISTANT_ERROR: Error occurred, contains 'code' and 'message' fields
#
# Audio control events:
#   - ducking: Music volume lowered
#   - unducking: Music volume restored
#   - playing: Audio file being played
# =============================================================================


event_handlers = {
    'wake_word': lambda wake_word: (
        print(f"[WAKE] {wake_word}"),
        led_action(lambda leds: leds.set_color(BLUE))
    ),
    
    'VOICE_ASSISTANT_RUN_START': lambda data: (
        state.update({'conversation_active': True}),
        led_action(lambda leds: leds.set_color(YELLOW))
    ),
    
    'VOICE_ASSISTANT_STT_END': lambda data: (
        state.update({'current_text': data.get('text', '')}),
        print(f"[TEXT] {data.get('text', '')}"),
        led_action(lambda leds: leds.set_color(GREEN))
    ),
    
    'VOICE_ASSISTANT_TTS_START': lambda data: (
        print(f"[TTS] {data.get('text', '')}"),
        led_action(lambda leds: leds.set_color(BLUE))
    ),
    
    'VOICE_ASSISTANT_RUN_END': lambda data: (
        state.update({'conversation_active': False}),
        led_action(lambda leds: leds.set_color(BLACK))
    ),
    
    'VOICE_ASSISTANT_ERROR': lambda data: (
        print(f"[ERROR] {data.get('code', '')}: {data.get('message', '')}"),
        led_action(lambda leds: leds.set_color(RED))
    ),
}


def parse_and_handle_event(line):
    """Parse log line and trigger event handler"""
    # Wake word detection
    match = re.search(r'Detected wake word: (.+)', line)
    if match:
        if 'wake_word' in event_handlers:
            event_handlers['wake_word'](match.group(1))
        return
    
    # Voice assistant events
    match = re.search(r'Voice event: type=(\w+)(?:, data=(.+))?', line)
    if match:
        event_type = match.group(1)
        data = {}
        if match.group(2):
            try:
                data = eval(match.group(2))
            except:
                pass
        if event_type in event_handlers:
            event_handlers[event_type](data)
        return


class EventCapturingHandler(logging.Handler):
    """Custom logging handler that intercepts log records"""
    
    def emit(self, record):
        try:
            msg = self.format(record)
            parse_and_handle_event(msg)
            print(msg)
        except Exception:
            self.handleError(record)


def setup_event_logging():
    """Setup logging interception for event handling"""
    root_logger = logging.getLogger()
    
    event_handler = EventCapturingHandler()
    event_handler.setLevel(logging.DEBUG)
    
    formatter = logging.Formatter('%(levelname)s:%(name)s:%(message)s')
    event_handler.setFormatter(formatter)
    
    root_logger.addHandler(event_handler)


def main():
    """Main entry point - runs linux_voice_assistant directly"""
    
    print("[+] Starting Voice Assistant with event wrapper...")
    
    init_leds()
    setup_event_logging()
    
    try:
        # Import the async main function
        from linux_voice_assistant.__main__ import main as voice_main
        
        # Modify sys.argv to include --debug and user args
        original_argv = sys.argv.copy()
        sys.argv = ['linux_voice_assistant', '--debug'] + sys.argv[1:]
        
        try:
            # Run the async main function
            # voice_main() is a coroutine, so we need asyncio.run()
            asyncio.run(voice_main())
        except KeyboardInterrupt:
            print("\n[!] Stopping Voice Assistant...")
        finally:
            sys.argv = original_argv
            
    except ImportError as e:
        print(f"[ERROR] Failed to import linux_voice_assistant: {e}")
        return 1
    finally:
        if state.get('leds'):
            state['leds'].cleanup()
    
    return 0
