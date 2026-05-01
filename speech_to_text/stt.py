from faster_whisper import WhisperModel
import time
import os

def generate_transcript(audio_path):
    """
    Converts audio to text using faster-whisper (large-v3) on GPU.
    Returns the Gujarati transcript text and saves it to a file.
    """
    print("🚀 Loading faster-whisper model (large-v3) on GPU...")
    start_load = time.time()
    
    # Load model once with CUDA and float16 precision (as per project.md)
    model = WhisperModel(
        "large-v3", 
        device="cuda", 
        compute_type="float16"
    )
    print(f"✅ Model loaded in {time.time() - start_load:.2f} seconds.")

    print(f"🎙️ Transcribing audio: {audio_path}...")
    start_transcribe = time.time()
    
    # Transcribe the audio
    segments, info = model.transcribe(audio_path, beam_size=5, language="gu")

    print(f"🔍 Detected language: {info.language} with probability {info.language_probability:.2f}")

    transcript_text = ""
    for segment in segments:
        print(f"[{segment.start:.2f}s -> {segment.end:.2f}s] {segment.text}")
        transcript_text += segment.text + " "

    print(f"✅ Transcription finished in {time.time() - start_transcribe:.2f} seconds.")
    
    # Save transcript to a file
    base_name = os.path.splitext(os.path.basename(audio_path))[0]
    output_file = f"transcripts/{base_name}_transcript.txt"
    os.makedirs("transcripts", exist_ok=True)
    
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(transcript_text.strip())
        
    print(f"💾 Transcript saved successfully to: {os.path.abspath(output_file)}")
    return transcript_text.strip()

if __name__ == "__main__":
    print("=== BhashaFlow STT Engine (Phase 2) ===")
    audio_file = input("Enter path to audio file (e.g., ../audio_recording/recordings/sample.wav): ")
    if os.path.exists(audio_file):
        generate_transcript(audio_file)
    else:
        print("❌ Error: File not found! Please check the path and try again.")
