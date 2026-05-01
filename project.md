# 📘 Project: BhashaFlow – Post-Class AI Transcript System (Multi-Language, High Accuracy, GPU Optimized)

## 🎯 Objective

Build a system where a teacher records a lecture, and after the class ends, the system generates:

* Full transcript (high accuracy)
* Translations in multiple languages (per student preference)
* Natural audio (per language)

This system is **not real-time**. It focuses on **maximum quality and reliability** with full multi-language support from the start.

---

## 🧱 Tech Stack

### Frontend

* Flutter (Single app: Teacher + Student)

### Backend

* Django (API-based, no WebSockets)

### AI Models

* Speech-to-Text: faster-whisper (large-v3, GPU)
* Translation: IndicTrans2 (multi-language)
* Text-to-Speech: Coqui TTS (XTTS v2, multi-language)

### Database

* PostgreSQL / SQLite

### Hardware

* GPU enabled system (CUDA supported)

---

## 🌍 Multi-Language Design (CORE FEATURE)

* Each lecture is processed once for transcription
* Then translated into multiple target languages
* Each student selects preferred language
* System serves content based on selected language

### Example Languages

* English
* Hindi
* Gujarati
* Tamil
* Marathi

---

## 🧠 Core Architecture

* Load AI models **once at server startup**
* Do NOT reload models per request
* Use GPU (CUDA) for STT
* Process lectures **after upload (offline pipeline)**
* Generate and store **separate outputs per language**

---

## ⚙️ System Flow

1. Teacher records lecture (audio file)
2. Audio uploaded to backend
3. Backend pipeline:

   * Speech-to-Text → Gujarati transcript
   * Translation → Multiple languages
   * Generate audio per language
   * Save all outputs
4. Students open app:

   * Select language
   * View transcript
   * Play audio in selected language

---

## 🚀 Processing Pipeline (Multi-Language)

Audio File
→ Speech-to-Text (large-v3, GPU)
→ Gujarati Text
→ Translation (IndicTrans2 → multiple languages)
→ Translated Texts (EN, HI, GU, etc.)
→ Text-to-Speech (XTTS v2 per language)
→ Audio Files (per language)
→ Save to Database

---

## 🗄️ Database Design (IMPORTANT)

### Lecture Table

* id
* title
* audio_file
* created_at

### Transcript Table

* id
* lecture (FK)
* language (e.g., 'en', 'hi', 'gu')
* text
* audio_file

👉 Each lecture will have **multiple transcript rows (one per language)**

---

## 🧩 Backend Design (IMPORTANT)

* Load Whisper model globally:

```python
from faster_whisper import WhisperModel

model = WhisperModel(
    "large-v3",
    device="cuda",
    compute_type="float16"
)
```

* Reuse model for all requests
* Do NOT initialize model inside functions

---

## 📦 Django APIs

* Upload lecture
* Process lecture (trigger pipeline)
* Get lectures list
* Get transcript by language
* Get audio by language

---

## 📱 Flutter App Features

### Teacher

* Record lecture
* Upload audio

### Student

* Select preferred language
* View lecture list
* Read transcript in selected language
* Play audio in selected language

---

## ⚡ Performance Expectations

* Model load time: ~15–30 seconds (once)
* Processing time: ~5–10 minutes per 1-hour lecture
* Additional time for multi-language generation

---

## ❗ Important Rules

* Do NOT use real-time streaming
* Do NOT reload AI models per request
* Always process after class ends
* Always use GPU for STT
* Generate all required languages in one pipeline run

---

## ✅ Final Output

* Accurate transcript of lecture
* Multiple language translations
* Natural audio for each language
* Students receive content in their chosen language

---

## 🚀 Future Improvements

* Add more languages dynamically
* Auto language detection
* Subtitle export (SRT)
* Download transcript as PDF
* Search inside transcript
* Speaker diarization (optional)

---