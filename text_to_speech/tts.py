import os
from gtts import gTTS
import time

def generate_audio(text, language_code, output_path):
    """
    Generates natural audio from text using Google TTS (gTTS).
    Supported codes: 'en', 'hi', 'gu'.
    """
    try:
        print(f"Generating TTS audio for language: {language_code}...")
        start_time = time.time()
        
        # Create TTS object
        # Note: gTTS language codes match our codes for en, hi, gu.
        tts = gTTS(text=text, lang=language_code)
        
        # Save to file
        tts.save(output_path)
        
        print(f"Audio generated in {time.time() - start_time:.2f} seconds.")
        return True
    except Exception as e:
        print(f"TTS Error: {e}")
        return False

if __name__ == "__main__":
    test_text = "નમસ્તે, આ એક કસોટી છે." # Gujarati: "Hello, this is a test."
    test_lang = "gu"
    test_output = "test_output.mp3"
    generate_audio(test_text, test_lang, test_output)
