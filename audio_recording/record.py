import sounddevice as sd
import soundfile as sf
import datetime
import os

def record_audio(duration, filename=None):
    """
    Records audio from the default microphone and saves it as a WAV file.
    """
    samplerate = 44100  # Standard audio sample rate
    channels = 1        # Mono recording

    if not filename:
        os.makedirs("recordings", exist_ok=True)
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"recordings/lecture_{timestamp}.wav"

    print(f"🎤 Recording started for {duration} seconds...")
    
    # Start recording
    myrecording = sd.rec(int(duration * samplerate), samplerate=samplerate, channels=channels)
    
    # Wait until recording is finished
    sd.wait()
    print("✅ Recording finished.")

    # Save as WAV file
    sf.write(filename, myrecording, samplerate)
    print(f"💾 Audio saved successfully to: {os.path.abspath(filename)}")
    return filename

if __name__ == "__main__":
    print("=== BhashaFlow Audio Recorder ===")
    try:
        dur_str = input("Enter duration to record (in seconds, e.g., 5): ")
        dur = int(dur_str)
        if dur <= 0:
            print("❌ Duration must be greater than 0.")
        else:
            record_audio(dur)
    except ValueError:
        print("❌ Invalid input. Please enter a valid number of seconds.")
    except Exception as e:
        print(f"❌ An error occurred during recording: {e}")
