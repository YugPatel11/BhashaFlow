# BhashaFlow Setup & Installation Guide

This guide contains all the prerequisites and instructions needed to run BhashaFlow on a new computer.

## 1. System Requirements
- **OS:** Windows / Linux
- **GPU:** NVIDIA GPU with CUDA support is highly recommended for Speech-to-Text and Translation.
- **Python:** Python 3.10 or 3.11 recommended.

## 2. Essential Prerequisites (Must Install First!)
Before running `pip install`, you **must** install the Microsoft C++ Build Tools on Windows. Some audio libraries require it to compile successfully.

1. Download **Microsoft C++ Build Tools**: [https://visualstudio.microsoft.com/visual-cpp-build-tools/](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
2. Run the installer and check the box for **"Desktop development with C++"**.
3. Complete the installation and restart your computer.

## 3. Installation Steps per Phase

### Phase 1: Audio Recording
```bash
cd audio_recording
pip install -r requirements.txt
python record.py
```

### Phase 2: Speech-to-Text (faster-whisper)
```bash
cd speech_to_text
pip install -r requirements.txt
python stt.py
```

### Phase 3: Translation (IndicTrans2)
```bash
cd translation
pip install -r requirements.txt
python translate.py
```

### Phase 4: Text-to-Speech (Coqui XTTS v2)
```bash
cd text_to_speech
pip install -r requirements.txt
python tts.py
```

### Phase 6: Backend API Server
```bash
cd backend
pip install -r requirements.txt
python manage.py runserver
```

### Phase 7: Flutter App
1. Install Flutter: [flutter.dev](https://docs.flutter.dev/get-started/install)
2. Run the following commands:
```bash
cd frontend
flutter create .
flutter pub get
flutter run
```
