IGNORE THIS FILE

import pyaudio
import numpy as np
import wave
import time

# Audio file saved by Dart WebSocket server
AUDIO_FILE = "received_audio.wav"

# Audio settings (must match recording settings)
FORMAT = pyaudio.paInt16  # 16-bit PCM
CHANNELS = 1              # Mono audio
RATE = 16000              # Sample rate (16kHz)
CHUNK = 1024              # Buffer size

def play_audio():
    try:
        # Open the saved PCM file
        with wave.open(AUDIO_FILE, 'rb') as wf:
            p = pyaudio.PyAudio()

            stream = p.open(format=p.get_format_from_width(wf.getsampwidth()),
                            channels=wf.getnchannels(),
                            rate=wf.getframerate(),
                            output=True)

            data = wf.readframes(CHUNK)

            while data:
                stream.write(data)
                data = wf.readframes(CHUNK)

            stream.stop_stream()
            stream.close()
            p.terminate()

            print("🎧 Playback finished.")

    except FileNotFoundError:
        print("❌ No audio file found! Please make sure audio is recorded.")

if __name__ == "__main__":
    print("🔁 Waiting for audio file...")
    while True:
        play_audio()
        time.sleep(1)  # Check for new files every second
