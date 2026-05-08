"""
BhashaFlow Speech-to-Text Engine
Uses faster-whisper for high-accuracy transcription.
Model is loaded once and reused across requests.
"""
from faster_whisper import WhisperModel
import time
import os
import logging

logger = logging.getLogger(__name__)

# ── Global model (loaded once, reused for all requests) ──
_model = None
_model_size = None

# Default model size. Use "large-v3" for best accuracy (requires GPU + ~3GB VRAM).
# Use "base" or "small" for faster setup on weaker hardware.
DEFAULT_MODEL_SIZE = os.environ.get("WHISPER_MODEL_SIZE", "base")


def _get_model(model_size=None):
    """Lazy-load the Whisper model (singleton pattern)."""
    global _model, _model_size

    if model_size is None:
        model_size = DEFAULT_MODEL_SIZE

    if _model is not None and _model_size == model_size:
        return _model

    print(f"🚀 Loading faster-whisper model ({model_size})...")
    start_load = time.time()

    # Auto-detect GPU availability
    try:
        import torch
        device = "cuda" if torch.cuda.is_available() else "cpu"
    except ImportError:
        device = "cpu"

    compute_type = "float16" if device == "cuda" else "int8"

    _model = WhisperModel(
        model_size,
        device=device,
        compute_type=compute_type
    )
    _model_size = model_size
    print(f"✅ Model loaded on {device.upper()} in {time.time() - start_load:.2f}s")

    return _model


def generate_transcript(audio_path, model_size=None):
    """
    Converts audio to text using faster-whisper.
    Returns tuple: (transcript_text, detected_language_code)
    """
    if not os.path.exists(audio_path):
        raise FileNotFoundError(f"Audio file not found: {audio_path}")

    model = _get_model(model_size)

    print(f"🎙️ Transcribing: {os.path.basename(audio_path)}...")
    start = time.time()

    segments, info = model.transcribe(audio_path, beam_size=5)

    detected_lang = info.language
    print(f"🔍 Detected language: {detected_lang} (confidence: {info.language_probability:.2f})")

    transcript_text = ""
    for segment in segments:
        print(f"  [{segment.start:.1f}s → {segment.end:.1f}s] {segment.text}")
        transcript_text += segment.text + " "

    transcript_text = transcript_text.strip()
    elapsed = time.time() - start
    print(f"✅ Transcription done in {elapsed:.2f}s ({len(transcript_text)} chars)")

    # Save transcript to file
    os.makedirs("transcripts", exist_ok=True)
    base_name = os.path.splitext(os.path.basename(audio_path))[0]
    output_file = f"transcripts/{base_name}_transcript.txt"

    with open(output_file, "w", encoding="utf-8") as f:
        f.write(transcript_text)
    print(f"💾 Saved to: {os.path.abspath(output_file)}")

    return transcript_text, detected_lang


if __name__ == "__main__":
    print("=== BhashaFlow STT Engine ===")
    audio_file = input("Enter path to audio file: ")
    if os.path.exists(audio_file):
        text, lang = generate_transcript(audio_file)
        print(f"\n--- Detected: {lang} ---")
        print(text)
    else:
        print("❌ Error: File not found!")
