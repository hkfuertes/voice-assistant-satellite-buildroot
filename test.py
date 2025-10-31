#!/usr/bin/env python3
import sounddevice as sd
import numpy as np
import sys


def list_devices():
    """Listar dispositivos disponibles"""
    print("=== Available Audio Devices ===")
    devices = sd.query_devices()
    for i, device in enumerate(devices):
        print(f"{i}: {device['name']} (in: {device['max_input_channels']}, out: {device['max_output_channels']})")
    print()


def audio_monitor(device_name="wm8960"):
    """Monitorear entrada de audio con barras visuales"""
    
    # Configuración
    SAMPLE_RATE = 16000
    BLOCK_SIZE = 1024
    CHANNELS = 1
    
    # Listar dispositivos
    list_devices()
    
    print("=== Audio Input Monitor ===")
    print(f"Sample Rate: {SAMPLE_RATE} Hz")
    print(f"Block Size: {BLOCK_SIZE}")
    print(f"Channels: {CHANNELS}")
    print(f"Looking for device: {device_name}")
    print("\nHabla ahora (Ctrl+C para salir)...\n")
    
    def audio_callback(indata, frames, time_info, status):
        if status:
            print(f"Audio status: {status}", file=sys.stderr)
        
        # Obtener datos de audio (float32, rango -1.0 a 1.0)
        audio = indata[:, 0].astype(np.float32)
        
        # Calcular estadísticas
        rms = np.sqrt(np.mean(audio**2))
        peak = np.max(np.abs(audio))
        mean = np.mean(audio)
        
        # Normalizar para visualización (0-100)
        # float32 está en rango [-1.0, 1.0]
        rms_norm = int(rms * 100)
        peak_norm = int(peak * 100)
        
        # Barra visual
        bar_rms = "█" * max(1, rms_norm // 5)
        bar_peak = "█" * max(1, peak_norm // 5)
        
        print(f"\rRMS:  [{bar_rms:<20}] {rms:8.4f} ({rms_norm:3d}%)  |  "
              f"Peak: [{bar_peak:<20}] {peak:8.4f} ({peak_norm:3d}%)  |  "
              f"Mean: {mean:8.4f}", end="", flush=True)
    
    # Iniciar stream de audio
    try:
        with sd.InputStream(
            channels=CHANNELS,
            samplerate=SAMPLE_RATE,
            blocksize=BLOCK_SIZE,
            callback=audio_callback,
            device=device_name,  # Especificar dispositivo por nombre
            dtype='float32'  # Explícito
        ):
            print("Stream iniciado. Hablando...Press Ctrl+C para salir\n")
            sd.sleep(int(120 * 1000))  # 120 segundos máximo
    except KeyboardInterrupt:
        print("\n\nMonitor detenido.")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        print("\nIntentando con dispositivo por defecto...\n")
        # Fallback
        try:
            with sd.InputStream(
                channels=CHANNELS,
                samplerate=SAMPLE_RATE,
                blocksize=BLOCK_SIZE,
                callback=audio_callback,
                dtype='float32'
            ):
                print("Stream iniciado (default device). Press Ctrl+C para salir\n")
                sd.sleep(int(120 * 1000))
        except KeyboardInterrupt:
            print("\n\nMonitor detenido.")


if __name__ == "__main__":
    # Usa "wm8960" o el número de dispositivo si sabes cuál es
    audio_monitor(device_name="wm8960")
