import sys
import sounddevice as sd
import numpy as np

# ✅ Adjusted buffer size for lower latency
SAMPLE_RATE = 16000
CHANNELS = 1
BLOCK_SIZE = 2048  # 🛠️ Balanced for real-time playback

def play_audio():
    """ Continuously read PCM16 raw audio from stdin and play it in real-time. """
    try:
        with sd.OutputStream(samplerate=SAMPLE_RATE, channels=CHANNELS, dtype='int16') as stream:
            while True:
                raw_data = sys.stdin.buffer.read(BLOCK_SIZE)
                if not raw_data:
                    break
                audio_array = np.frombuffer(raw_data, dtype=np.int16)
                stream.write(audio_array)  # ✅ Smooth streaming playback
    except KeyboardInterrupt:
        print("🔇 Stopping live audio playback.")
    except Exception as e:
        print(f"⚠️ Error playing audio: {e}")

if __name__ == "__main__":
    play_audio()
