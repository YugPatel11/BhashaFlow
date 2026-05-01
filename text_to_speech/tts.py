import os
import time
from TTS.api import TTS

def generate_audio(text_file, language_code):
    """
    Reads translated text and generates natural audio using Coqui XTTS v2.
    """
    print(f"🚀 Loading Coqui XTTS v2 model for language: {language_code}...")
    start_load = time.time()
    
    # Init TTS with XTTS v2
    tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2", gpu=True)
    print(f"✅ Model loaded in {time.time() - start_load:.2f} seconds.")

    with open(text_file, "r", encoding="utf-8") as f:
        text = f.read()

    os.makedirs("output_audio", exist_ok=True)
    base_name = os.path.splitext(os.path.basename(text_file))[0]
    output_path = f"output_audio/{base_name}_{language_code}.wav"

    print("🎙️ Generating audio...")
    start_gen = time.time()
    
    # Assuming 'speaker.wav' is a 3-5 second sample of the teacher's voice to clone.
    # We will use a dummy/default speaker if speaker.wav is not present.
    speaker_wav = "speaker.wav" if os.path.exists("speaker.wav") else None
    
    if speaker_wav:
        tts.tts_to_file(text=text, file_path=output_path, speaker_wav=speaker_wav, language=language_code)
    else:
        # Fallback to standard speaker mapping if no reference audio is provided
        print("⚠️ No speaker.wav found. Using default voice.")
        # XTTS requires speaker_wav or a preset speaker. If XTTS requires speaker_wav, we fallback to a simple model
        try:
            tts.tts_to_file(text=text, file_path=output_path, speaker_wav="../audio_recording/recordings/sample.wav", language=language_code)
        except:
            print("❌ Error: XTTS requires a sample voice to clone. Please place a 'speaker.wav' file in this folder.")
            return

    print(f"✅ Audio generated in {time.time() - start_gen:.2f} seconds.")
    print(f"💾 Saved to {os.path.abspath(output_path)}")

if __name__ == "__main__":
    print("=== BhashaFlow TTS Engine (Phase 4) ===")
    txt_path = input("Enter path to translated text file: ")
    lang = input("Enter language code (e.g., hi, mr, ta, en): ")
    if os.path.exists(txt_path):
        generate_audio(txt_path, lang)
    else:
        print("❌ File not found!")
