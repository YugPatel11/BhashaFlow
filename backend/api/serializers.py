from rest_framework import serializers
from .models import Lecture, Transcript

class TranscriptSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transcript
        fields = ['id', 'language', 'text', 'audio_file']

class LectureSerializer(serializers.ModelSerializer):
    transcripts = TranscriptSerializer(many=True, read_only=True)

    class Meta:
        model = Lecture
        fields = ['id', 'title', 'audio_file', 'status', 'error_message', 'created_at', 'transcripts']
        read_only_fields = ['status', 'error_message']
