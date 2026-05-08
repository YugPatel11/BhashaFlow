# BhashaFlow – Setup Guide

## Prerequisites

- Python 3.10+ 
- Flutter SDK 3.0+
- Internet connection (for Google Translate API and Whisper model download)

---

## 1. Backend Setup

```bash
cd backend

# Install Python dependencies
pip install -r requirements.txt

# Create database tables (IMPORTANT - must do this first!)
python manage.py migrate

# Start the server (use your machine's IP so the Flutter app can reach it)
python manage.py runserver 0.0.0.0:8000
```

### Environment Variables (Optional)

| Variable | Default | Description |
|---|---|---|
| `WHISPER_MODEL_SIZE` | `base` | Whisper model size. Options: `tiny`, `base`, `small`, `medium`, `large-v3`. Larger = more accurate but slower and needs more RAM/VRAM. |

Example:
```bash
set WHISPER_MODEL_SIZE=large-v3
python manage.py runserver 0.0.0.0:8000
```

---

## 2. Flutter Frontend Setup

```bash
cd frontend

# Install Flutter dependencies
flutter pub get

# IMPORTANT: Update the server URL in lib/main.dart
# Change BASE_URL to your backend server's IP address:
const String BASE_URL = 'http://10.92.177.63:8000';

# Run the app
flutter run
```

---

## 3. How It Works

1. **Teacher** uploads a lecture audio file (.m4a, .wav, .mp3, etc.)
2. **Backend** automatically processes it in the background:
   - Speech-to-Text (faster-whisper) → detects language and transcribes
   - Translation (Google Translate) → translates to English, Hindi, Gujarati
3. **Student** opens the app, selects a language, and reads the transcript

---

## 4. API Endpoints

| Method | URL | Description |
|---|---|---|
| POST | `/api/lectures/upload/` | Upload audio + start processing |
| GET | `/api/lectures/` | List all lectures with status |
| GET | `/api/lectures/<id>/status/` | Check processing status |
| POST | `/api/lectures/<id>/process/` | Re-trigger processing |
| GET | `/api/lectures/<id>/transcript/<lang>/` | Get transcript (lang: en, hi, gu) |

---

## 5. Troubleshooting

| Problem | Solution |
|---|---|
| `no such table: api_lecture` | Run `python manage.py migrate` |
| Translation not happening | Check server console for errors. Make sure `deep-translator` is installed. |
| STT fails | Make sure `faster-whisper` is installed. First run downloads the Whisper model (~150MB for base). |
| Flutter can't connect | Update `BASE_URL` in `lib/main.dart` to your server IP. Make sure both devices are on the same network. |
| Lecture stuck on "processing" | Check the Django server terminal for error logs. Re-trigger with POST to `/api/lectures/<id>/process/`. |
