import wave
import numpy as np

# Define audio properties
AUDIO_FILE = "received_audio.wav"  # The raw PCM file
OUTPUT_WAV = "output.wav"  # The fixed WAV file
SAMPLE_RATE = 16000  # Match the sample rate used in Flutter
NUM_CHANNELS = 1  # Mono audio
BITS_PER_SAMPLE = 16  # PCM 16-bit audio

def convert_raw_to_wav():
    try:
        print("🔄 Converting raw PCM to WAV...")
        with open(AUDIO_FILE, "rb") as raw_file:
            pcm_data = raw_file.read()

        # Convert PCM bytes to NumPy array
        audio_data = np.frombuffer(pcm_data, dtype=np.int16)

        # Save as WAV
        with wave.open(OUTPUT_WAV, "w") as wav_file:
            wav_file.setnchannels(NUM_CHANNELS)
            wav_file.setsampwidth(BITS_PER_SAMPLE // 8)  # 16-bit = 2 bytes
            wav_file.setframerate(SAMPLE_RATE)
            wav_file.writeframes(audio_data.tobytes())

        print(f"✅ Converted to WAV: {OUTPUT_WAV}")

    except Exception as e:
        print(f"❌ Error converting audio: {e}")

if __name__ == "__main__":
    convert_raw_to_wav()
