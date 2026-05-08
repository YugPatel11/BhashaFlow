"""
BhashaFlow Translation Engine
Uses deep-translator (Google Translate) for reliable, zero-setup translation.
No model downloads required — works immediately.
"""
import os
import time
from deep_translator import GoogleTranslator

# Supported target languages with their codes
SUPPORTED_LANGUAGES = {
    'en': 'english',
    'hi': 'hindi',
    'gu': 'gujarati',
    'ta': 'tamil',
    'mr': 'marathi',
    'te': 'telugu',
}


def translate_text(input_text, source_lang='gu', target_languages=None):
    """
    Translates input text from a source language to multiple target languages
    using Google Translate via deep-translator.

    Args:
        input_text: The text to translate.
        source_lang: Source language code (e.g., 'gu', 'hi', 'en').
        target_languages: List of target language codes (e.g., ['en', 'hi']).
                         If None, translates to all supported languages except source.

    Returns:
        dict: {language_code: translated_text} for each target language.
    """
    if target_languages is None:
        target_languages = [lang for lang in SUPPORTED_LANGUAGES if lang != source_lang]

    print(f"🌍 Starting Translation Pipeline (source: {source_lang})...")
    start_time = time.time()

    results = {}

    for tgt_lang in target_languages:
        if tgt_lang == source_lang:
            continue  # Skip translating to same language

        print(f"  Translating to {tgt_lang} ({SUPPORTED_LANGUAGES.get(tgt_lang, tgt_lang)})...")

        try:
            # Split long text into chunks (Google Translate has a 5000 char limit)
            chunks = _split_text(input_text, max_length=4500)
            translated_chunks = []

            for i, chunk in enumerate(chunks):
                translator = GoogleTranslator(source=source_lang, target=tgt_lang)
                translated = translator.translate(chunk)
                if translated:
                    translated_chunks.append(translated)

            translated_text = ' '.join(translated_chunks)
            results[tgt_lang] = translated_text
            print(f"    ✅ Done ({len(translated_text)} chars)")

        except Exception as e:
            print(f"    ❌ Error translating to {tgt_lang}: {e}")
            results[tgt_lang] = f"[Translation failed: {e}]"

    elapsed = time.time() - start_time
    print(f"🏁 Translation completed in {elapsed:.2f} seconds.")

    # Optionally save to files
    os.makedirs("translations", exist_ok=True)
    for lang, text in results.items():
        output_file = f"translations/translated_{lang}.txt"
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(text)

    return results


def _split_text(text, max_length=4500):
    """Split text into chunks that respect sentence boundaries."""
    if len(text) <= max_length:
        return [text]

    chunks = []
    current_chunk = ""

    # Split by sentences (period + space)
    sentences = text.replace('. ', '.\n').split('\n')

    for sentence in sentences:
        if len(current_chunk) + len(sentence) + 1 <= max_length:
            current_chunk += (' ' if current_chunk else '') + sentence
        else:
            if current_chunk:
                chunks.append(current_chunk)
            current_chunk = sentence

    if current_chunk:
        chunks.append(current_chunk)

    return chunks if chunks else [text]


if __name__ == "__main__":
    print("=== BhashaFlow Translation Engine ===")
    text_file = input("Enter path to transcript text file: ")

    if os.path.exists(text_file):
        with open(text_file, "r", encoding="utf-8") as f:
            transcript = f.read()

        src = input("Source language code (en/hi/gu/ta/mr): ").strip() or 'gu'
        results = translate_text(transcript, source_lang=src)

        print("\n✅ All translations completed!")
        for lang, text in results.items():
            print(f"\n--- {lang.upper()} ---")
            print(text[:200] + "..." if len(text) > 200 else text)
    else:
        print("❌ Error: File not found!")
