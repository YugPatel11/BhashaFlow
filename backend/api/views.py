import os
import sys
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework import status
from .models import Lecture, Transcript
from .serializers import LectureSerializer

# Add parent directory to sys.path to import AI modules
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../'))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

try:
    from speech_to_text.stt import generate_transcript
    from translation.translate import translate_text
except ImportError as e:
    print(f"Warning: Could not import AI modules: {e}")
    generate_transcript = None
    translate_text = None

import threading

class LectureUploadView(APIView):
    parser_classes = (MultiPartParser, FormParser)

    def post(self, request, *args, **kwargs):
        serializer = LectureSerializer(data=request.data)
        if serializer.is_valid():
            lecture = serializer.save()
            # Trigger processing in a background thread
            thread = threading.Thread(target=self.run_pipeline, args=(lecture.pk,))
            thread.start()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def run_pipeline(self, lecture_pk):
        try:
            from django.db import connection
            # Re-fetch lecture in the new thread to ensure it's loaded correctly
            from .models import Lecture, Transcript
            lecture = Lecture.objects.get(pk=lecture_pk)
            audio_path = lecture.audio_file.path

            if not generate_transcript or not translate_text:
                print("Error: AI modules not properly configured.")
                return
            # 1. Real Transcription
            print(f"Starting STT for {audio_path}...")
            text, detected_lang = generate_transcript(audio_path)
            
            # Map Whisper code to DB code (ensure consistency)
            db_lang = detected_lang if detected_lang in ['gu', 'hi', 'en'] else 'en'
            
            Transcript.objects.update_or_create(
                lecture=lecture, language=db_lang, 
                defaults={'text': text}
            )

            # 2. Real Translation
            print(f"Starting Translation from {detected_lang}...")
            
            # Mapping for IndicTrans2 source language
            stt_to_it2 = {
                'gu': 'guj_Gujr',
                'hi': 'hin_Deva',
                'en': 'eng_Latn'
            }
            source_it2 = stt_to_it2.get(detected_lang, 'eng_Latn')
            
            # Target mapping
            it2_to_db = {
                "hin_Deva": "hi",
                "eng_Latn": "en",
                "guj_Gujr": "gu"
            }
            
            # Filter out the source language from targets
            targets = [k for k in it2_to_db.keys() if it2_to_db[k] != db_lang]
            
            translations = translate_text(text, source_lang=source_it2, target_languages=targets)
            
            for full_code, t_text in translations.items():
                short_code = it2_to_db.get(full_code, full_code)
                Transcript.objects.update_or_create(
                    lecture=lecture, language=short_code,
                    defaults={'text': t_text}
                )
            print(f"Successfully processed lecture {lecture_pk}")
        except Exception as e:
            print(f"Error in background pipeline: {e}")
        finally:
            connection.close()

class LectureListView(APIView):
    def get(self, request, *args, **kwargs):
        lectures = Lecture.objects.all().order_by('-created_at')
        serializer = LectureSerializer(lectures, many=True)
        return Response(serializer.data)

class ProcessLectureView(APIView):
    def post(self, request, pk, *args, **kwargs):
        thread = threading.Thread(target=LectureUploadView().run_pipeline, args=(pk,))
        thread.start()
        return Response({"message": "Processing started in background."}, status=status.HTTP_202_ACCEPTED)

class TranscriptDetailView(APIView):
    def get(self, request, lecture_id, language, *args, **kwargs):
        try:
            transcript = Transcript.objects.get(lecture_id=lecture_id, language=language)
            return Response({
                "lecture_id": lecture_id,
                "language": language,
                "text": transcript.text,
                "audio_url": transcript.audio_file.url if transcript.audio_file else None
            })
        except Transcript.DoesNotExist:
            return Response({"error": "Transcript not found."}, status=status.HTTP_404_NOT_FOUND)
