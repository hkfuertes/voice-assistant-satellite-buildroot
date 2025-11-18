#!/usr/bin/env python3
import subprocess
import re
import sys

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


event_handlers = {
    'wake_word': lambda wake_word: (
        print(f"[WAKE] Wake word detected: {wake_word}"),
        led_action(lambda leds: leds.set_color(BLUE))
    ),
    
    'VOICE_ASSISTANT_RUN_START': lambda data: (
        state.update({'conversation_active': True}),
        print("[START] Voice conversation started"),
        led_action(lambda leds: leds.set_color(YELLOW))
    ),
    
    'VOICE_ASSISTANT_STT_START': lambda data: (
        print("[STT] Listening..."),
        led_action(lambda leds: leds.set_color(YELLOW))
    ),
    
    'VOICE_ASSISTANT_STT_VAD_START': lambda data: (
        print("[VAD] Voice activity detected")
    ),
    
    'VOICE_ASSISTANT_STT_VAD_END': lambda data: (
        print("[VAD] Silence detected")
    ),
    
    'VOICE_ASSISTANT_STT_END': lambda data: (
        state.update({'current_text': data.get('text', '')}),
        print(f"[TEXT] Recognized: '{data.get('text', '')}'"),
        led_action(lambda leds: leds.set_color(GREEN))
    ),
    
    'VOICE_ASSISTANT_INTENT_START': lambda data: (
        print("[INTENT] Processing intent...")
    ),
    
    'VOICE_ASSISTANT_INTENT_END': lambda data: (
        print(f"[INTENT] Processed (ID: {data.get('conversation_id', '')})")
    ),
    
    'VOICE_ASSISTANT_TTS_START': lambda data: (
        print(f"[TTS] Response: '{data.get('text', '')}'"),
        led_action(lambda leds: leds.set_color(BLUE))
    ),
    
    'VOICE_ASSISTANT_TTS_END': lambda data: (
        print("[TTS] Playing response")
    ),
    
    'VOICE_ASSISTANT_RUN_END': lambda data: (
        state.update({'conversation_active': False}),
        print("[END] Conversation finished\n"),
        led_action(lambda leds: leds.set_color(BLACK))
    ),
    
    'VOICE_ASSISTANT_ERROR': lambda data: (
        print(f"[ERROR] [{data.get('code', '')}]: {data.get('message', '')}"),
        led_action(lambda leds: leds.set_color(RED))
    ),
    
    'ducking': lambda: print("[AUDIO] Ducking music"),
    
    'unducking': lambda: print("[AUDIO] Unducking music"),
    
    'playing': lambda path: None
}


def parse_and_handle_event(line):
    match = re.search(r'Detected wake word: (.+)', line)
    if match:
        event_handlers['wake_word'](match.group(1))
        return
    
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
    
    if 'Ducking music' in line:
        event_handlers['ducking']()
        return
    
    if 'Unducking music' in line:
        event_handlers['unducking']()
        return
    
    match = re.search(r'Playing (.+)', line)
    if match:
        event_handlers['playing'](match.group(1))
        return


def run_with_wrapper(command):
    print("[+] Starting Voice Assistant with event wrapper...")
    
    init_leds()
    
    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        bufsize=1,
        universal_newlines=True
    )
    
    try:
        for line in process.stdout:
            parse_and_handle_event(line.rstrip())
    except KeyboardInterrupt:
        print("\n[!] Stopping Voice Assistant...")
        process.terminate()
        process.wait()
    finally:
        if state.get('leds'):
            state['leds'].cleanup()
    
    return process.returncode


def main():
    """Main entry point - passes all arguments to linux_voice_assistant with --debug"""
    
    # Build command: python3 -m linux_voice_assistant --debug [user args]
    command = [
        '/usr/bin/python3', '-m', 'linux_voice_assistant',
        '--debug'
    ]
    
    # Add all arguments passed to the wrapper
    command.extend(sys.argv[1:])
    
    print(f"[+] Command: {' '.join(command)}")
    
    sys.exit(run_with_wrapper(command))
