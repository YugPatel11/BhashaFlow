import os
import sys
import logging
import traceback
import threading

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework import status

from .models import Lecture, Transcript
from .serializers import LectureSerializer

logger = logging.getLogger(__name__)

# Add parent directory to sys.path to import AI modules
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../'))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

# Import AI modules with graceful fallback
try:
    from speech_to_text.stt import generate_transcript
    _stt_available = True
    print("✅ STT module loaded successfully.")
except ImportError as e:
    _stt_available = False
    print(f"⚠️ STT module not available: {e}")
    print("   Install with: pip install faster-whisper")

try:
    from translation.translate import translate_text
    _translation_available = True
    print("✅ Translation module loaded successfully.")
except ImportError as e:
    _translation_available = False
    print(f"⚠️ Translation module not available: {e}")
    print("   Install with: pip install deep-translator")

try:
    from text_to_speech.tts import generate_audio
    _tts_available = True
    print("✅ TTS module loaded successfully.")
except ImportError as e:
    _tts_available = False
    print(f"⚠️ TTS module not available: {e}")
    print("   Install with: pip install gTTS")


class LectureUploadView(APIView):
    """Upload a lecture audio file and trigger background processing."""
    parser_classes = (MultiPartParser, FormParser)

    def post(self, request, *args, **kwargs):
        serializer = LectureSerializer(data=request.data)
        if serializer.is_valid():
            lecture = serializer.save(status='pending')

            # Start background processing
            thread = threading.Thread(
                target=_run_pipeline,
                args=(lecture.pk,),
                daemon=True
            )
            thread.start()

            return Response(
                LectureSerializer(lecture).data,
                status=status.HTTP_201_CREATED
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LectureListView(APIView):
    """List all lectures with their status and transcripts."""
    def get(self, request, *args, **kwargs):
        lectures = Lecture.objects.all().order_by('-created_at')
        serializer = LectureSerializer(lectures, many=True)
        return Response(serializer.data)


class ProcessLectureView(APIView):
    """Manually re-trigger processing for a lecture."""
    def post(self, request, pk, *args, **kwargs):
        try:
            lecture = Lecture.objects.get(pk=pk)
        except Lecture.DoesNotExist:
            return Response({"error": "Lecture not found."}, status=status.HTTP_404_NOT_FOUND)

        if lecture.status == 'processing':
            return Response({"message": "Already processing."}, status=status.HTTP_409_CONFLICT)

        lecture.status = 'pending'
        lecture.error_message = ''
        lecture.save()

        thread = threading.Thread(target=_run_pipeline, args=(pk,), daemon=True)
        thread.start()
        return Response({"message": "Processing started."}, status=status.HTTP_202_ACCEPTED)


class LectureStatusView(APIView):
    """Check the processing status of a lecture."""
    def get(self, request, pk, *args, **kwargs):
        try:
            lecture = Lecture.objects.get(pk=pk)
        except Lecture.DoesNotExist:
            return Response({"error": "Lecture not found."}, status=status.HTTP_404_NOT_FOUND)

        transcripts = Transcript.objects.filter(lecture=lecture)
        return Response({
            "id": lecture.pk,
            "title": lecture.title,
            "status": lecture.status,
            "error_message": lecture.error_message,
            "available_languages": list(transcripts.values_list('language', flat=True)),
        })


class TranscriptDetailView(APIView):
    """Get transcript text (and optional audio URL) for a specific lecture + language."""
    def get(self, request, lecture_id, language, *args, **kwargs):
        try:
            transcript = Transcript.objects.get(lecture_id=lecture_id, language=language)
            return Response({
                "lecture_id": lecture_id,
                "language": language,
                "text": transcript.text,
                "audio_url": transcript.audio_file.url if transcript.audio_file else None,
            })
        except Transcript.DoesNotExist:
            return Response(
                {"error": "Transcript not found for this language."},
                status=status.HTTP_404_NOT_FOUND
            )


# ── Background Pipeline ──────────────────────────────────────────────

def _run_pipeline(lecture_pk):
    """
    Background pipeline: STT → Translation → Save to DB.
    Updates lecture status throughout the process.
    """
    from django.db import connection

    try:
        lecture = Lecture.objects.get(pk=lecture_pk)
        audio_path = lecture.audio_file.path

        # ── Update status to processing ──
        lecture.status = 'processing'
        lecture.error_message = ''
        lecture.save()

        print(f"\n{'='*60}")
        print(f"🔄 Processing lecture {lecture_pk}: {lecture.title}")
        print(f"   Audio: {audio_path}")
        print(f"{'='*60}")

        # ── Step 1: Speech-to-Text ──
        if not _stt_available:
            raise RuntimeError(
                "STT module not available. Install faster-whisper: pip install faster-whisper"
            )

        print("\n📝 Step 1/2: Speech-to-Text...")
        transcript_text, detected_lang = generate_transcript(audio_path)

        if not transcript_text or not transcript_text.strip():
            raise RuntimeError("STT produced empty transcript. Check audio file quality.")

        # Normalize detected language code
        lang_map = {'gu': 'gu', 'hi': 'hi', 'en': 'en', 'ta': 'ta', 'mr': 'mr', 'te': 'te'}
        db_lang = lang_map.get(detected_lang, 'en')

        print(f"   Detected language: {detected_lang} → stored as: {db_lang}")
        print(f"   Transcript length: {len(transcript_text)} characters")

        # Save original transcript
        Transcript.objects.update_or_create(
            lecture=lecture, language=db_lang,
            defaults={'text': transcript_text}
        )

        # ── Step 2: Translation ──
        if not _translation_available:
            raise RuntimeError(
                "Translation module not available. Install deep-translator: pip install deep-translator"
            )

        print("\n🌍 Step 2/3: Translation...")

        # Translate to all other supported languages
        target_languages = [lang for lang in ['en', 'hi', 'gu', 'mr', 'ta', 'te'] if lang != db_lang]

        translations = translate_text(
            transcript_text,
            source_lang=db_lang,
            target_languages=target_languages
        )

        for lang_code, translated_text in translations.items():
            if not translated_text.startswith('[Translation failed'):
                transcript, _ = Transcript.objects.update_or_create(
                    lecture=lecture, language=lang_code,
                    defaults={'text': translated_text}
                )
                print(f"   ✅ Saved {lang_code} transcript")
                
                # ── Step 3: Text-to-Speech (Indented within loop) ──
                if _tts_available:
                    print(f"   🔊 Generating audio for {lang_code}...")
                    from django.core.files import File
                    temp_audio_name = f"tts_{lecture.id}_{lang_code}.mp3"
                    temp_audio_path = os.path.join(PROJECT_ROOT, 'backend', 'media', 'temp', temp_audio_name)
                    os.makedirs(os.path.dirname(temp_audio_path), exist_ok=True)
                    
                    if generate_audio(translated_text, lang_code, temp_audio_path):
                        with open(temp_audio_path, 'rb') as f:
                            transcript.audio_file.save(temp_audio_name, File(f), save=True)
                        print(f"   ✅ Audio saved for {lang_code}")
                        # Clean up temp file
                        if os.path.exists(temp_audio_path):
                            os.remove(temp_audio_path)
            else:
                print(f"   ⚠️ Skipped {lang_code}: {translated_text}")

        # Also generate audio for the original transcript if needed
        original_transcript = Transcript.objects.filter(lecture=lecture, language=db_lang).first()
        if original_transcript and not original_transcript.audio_file and _tts_available:
             print(f"   🔊 Generating audio for original ({db_lang})...")
             from django.core.files import File
             temp_audio_name = f"tts_{lecture.id}_{db_lang}.mp3"
             temp_audio_path = os.path.join(PROJECT_ROOT, 'backend', 'media', 'temp', temp_audio_name)
             os.makedirs(os.path.dirname(temp_audio_path), exist_ok=True)
             if generate_audio(original_transcript.text, db_lang, temp_audio_path):
                 with open(temp_audio_path, 'rb') as f:
                     original_transcript.audio_file.save(temp_audio_name, File(f), save=True)
                 if os.path.exists(temp_audio_path):
                     os.remove(temp_audio_path)

        # ── Done ──
        lecture.status = 'completed'
        lecture.error_message = ''
        lecture.save()

        print(f"\n🎉 Lecture {lecture_pk} processed successfully!")
        print(f"{'='*60}\n")

    except Exception as e:
        error_msg = f"{type(e).__name__}: {str(e)}"
        print(f"\n❌ Pipeline failed for lecture {lecture_pk}: {error_msg}")
        traceback.print_exc()

        try:
            lecture = Lecture.objects.get(pk=lecture_pk)
            lecture.status = 'failed'
            lecture.error_message = error_msg
            lecture.save()
        except Exception:
            pass

    finally:
        connection.close()
