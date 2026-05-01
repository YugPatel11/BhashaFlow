from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework import status
from .models import Lecture, Transcript
from .serializers import LectureSerializer

class LectureUploadView(APIView):
    parser_classes = (MultiPartParser, FormParser)

    def post(self, request, *args, **kwargs):
        serializer = LectureSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LectureListView(APIView):
    def get(self, request, *args, **kwargs):
        lectures = Lecture.objects.all().order_by('-created_at')
        serializer = LectureSerializer(lectures, many=True)
        return Response(serializer.data)

class ProcessLectureView(APIView):
    def post(self, request, pk, *args, **kwargs):
        try:
            lecture = Lecture.objects.get(pk=pk)
            # Offline processing trigger goes here
            # For Phase 6, we simulate triggering the AI pipeline
            return Response({"message": f"Pipeline triggered successfully for lecture {lecture.id}."}, status=status.HTTP_202_ACCEPTED)
        except Lecture.DoesNotExist:
            return Response({"error": "Lecture not found."}, status=status.HTTP_404_NOT_FOUND)

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
