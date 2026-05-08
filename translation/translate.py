import torch
from transformers import AutoModelForSeq2SeqLM, AutoTokenizer
import os
import time

def translate_text(input_text, source_lang="guj_Gujr", target_languages=["hin_Deva", "mar_Deva", "tam_Taml", "eng_Latn"]):
    """
    Translates input text from a source language (Gujarati) to multiple target languages using IndicTrans2.
    """
    print("🚀 Loading IndicTrans2 models on GPU...")
    start_load = time.time()
    
    # Using the indic-indic model for regional languages and indic-en for English
    # Note: For a production app, these models should be loaded once globally
    
    device = "cuda" if torch.cuda.is_available() else "cpu"
    
    # We load indic-indic for Guj -> Hindi/Marathi/Tamil
    model_name_indic = "ai4bharat/indictrans2-indic-indic-1B"
    tokenizer_indic = AutoTokenizer.from_pretrained(model_name_indic, trust_remote_code=True)
    model_indic = AutoModelForSeq2SeqLM.from_pretrained(model_name_indic, trust_remote_code=True).to(device)
    if device == "cuda": model_indic = model_indic.half()
    
    # We load indic-en for Guj -> English
    model_name_en = "ai4bharat/indictrans2-indic-en-1B"
    tokenizer_en = AutoTokenizer.from_pretrained(model_name_en, trust_remote_code=True)
    model_en = AutoModelForSeq2SeqLM.from_pretrained(model_name_en, trust_remote_code=True).to(device)
    if device == "cuda": model_en = model_en.half()

    print(f"✅ Models loaded in {time.time() - start_load:.2f} seconds.")

    os.makedirs("translations", exist_ok=True)
    results = {}

    print("🎙️ Starting Translation Pipeline...")
    for tgt_lang in target_languages:
        print(f"Translating to {tgt_lang}...")
        
        # Select appropriate model based on target language
        if tgt_lang == "eng_Latn":
            tokenizer = tokenizer_en
            model = model_en
        else:
            tokenizer = tokenizer_indic
            model = model_indic

        # Tokenize and format the input
        batch = tokenizer([input_text], src_lang=source_lang, tgt_lang=tgt_lang, return_tensors="pt").to(device)
        
        # Generate translation
        with torch.inference_mode():
            outputs = model.generate(**batch, num_beams=5, max_new_tokens=256)
            
        translated_text = tokenizer.batch_decode(outputs, skip_special_tokens=True)[0]
        results[tgt_lang] = translated_text
        
        # Save to file
        output_file = f"translations/translated_{tgt_lang}.txt"
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(translated_text)
        print(f"  -> Saved {tgt_lang} translation to {output_file}")

    return results

if __name__ == "__main__":
    print("=== BhashaFlow Translation Engine (Phase 3) ===")
    text_file = input("Enter path to the Gujarati transcript text file (e.g., ../speech_to_text/transcripts/lecture_transcript.txt): ")
    
    if os.path.exists(text_file):
        with open(text_file, "r", encoding="utf-8") as f:
            transcript = f.read()
            
        # Standard languages requested: Hindi, Marathi, Tamil, English
        translate_text(transcript)
        print("✅ All translations completed successfully!")
    else:
        print("❌ Error: File not found! Please check the path and try again.")
